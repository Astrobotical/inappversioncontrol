`in_app_version_control` is a Flutter/Dart package for backend-driven app
version governance. It fetches a version rule from your backend and decides
whether the app should continue normally, suggest an update, force an update,
or enter maintenance mode.

## Features

- Backend-agnostic decision engine
- Optional update, forced update, and maintenance mode support
- Pluggable provider interface for Firebase, Supabase, REST, or custom servers
- Built-in endpoint provider for teams that already expose their own backend API

## Getting started

Create a `VersionRuleProvider`, pass it to `InAppVersionControl`, and call
`check()` with your app ID, platform, and current version.

Use the built-in enum values instead of raw strings:

- `AppPlatform.android`
- `AppPlatform.ios`
- `AppPlatform.web`
- `AppPlatform.macos`
- `AppPlatform.windows`
- `AppPlatform.linux`

The default version format is numeric dot-separated strings such as:

- `1`
- `1.2`
- `1.2.3`

Non-numeric segments such as `1.2.0-beta` are rejected by design.

## Usage

### 1. Use a custom provider

```dart
import 'package:in_app_version_control/in_app_version_control.dart';

class MyBackendProvider implements VersionRuleProvider {
  @override
  Future<VersionRule> fetchRule({
    required String appId,
    required AppPlatform platform,
  }) async {
    // Call Firebase, Supabase, Appwrite, or your own backend here.
    return const VersionRule(
      minVersion: '1.4.0',
      latestVersion: '1.6.0',
      storeUrl: 'https://example.com/store',
      message: 'A newer version is available.',
    );
  }
}

final versionControl = InAppVersionControl(
  provider: MyBackendProvider(),
);

final decision = await versionControl.check(
  appId: 'com.example.app',
  platform: AppPlatform.android,
  currentVersion: '1.5.0',
);
```

### 2. Use the built-in endpoint provider

This is the easiest path if you already have a backend endpoint and only need
the package to call it.

```dart
import 'package:in_app_version_control/in_app_version_control.dart';

final provider = EndpointVersionRuleProvider(
  endpoint: Uri.parse('https://api.example.com/mobile/version-rule'),
  method: EndpointRequestMethod.post,
  headers: const {
    'x-api-key': 'your-api-key',
  },
);

final versionControl = InAppVersionControl(provider: provider);

final decision = await versionControl.check(
  appId: 'com.example.app',
  platform: AppPlatform.ios,
  currentVersion: '1.1.0',
);
```

The default endpoint payload is:

```json
{
  "appId": "com.example.app",
  "platform": "ios"
}
```

The default endpoint response shape is:

```json
{
  "minVersion": "1.0.0",
  "latestVersion": "1.2.0",
  "storeUrl": "https://example.com/store",
  "message": "Update available",
  "maintenance": false
}
```

### 3. Map an existing backend response

If your endpoint already returns a different JSON shape, provide a custom
`ruleBuilder` and keep your existing backend contract.

```dart
final provider = EndpointVersionRuleProvider(
  endpoint: Uri.parse('https://api.example.com/version-policy'),
  method: EndpointRequestMethod.get,
  ruleBuilder: (json, context) {
    final data = json['data'] as Map<String, dynamic>;
    return VersionRule(
      minVersion: data['min_version'] as String,
      latestVersion: data['latest_version'] as String,
      storeUrl: data['store_url'] as String?,
      message: data['notice'] as String?,
      maintenance: data['is_maintenance'] as bool? ?? false,
    );
  },
);
```

## Decision rules

- `maintenance == true` returns `UpdateType.maintenance`
- `currentVersion < minVersion` returns `UpdateType.force`
- `currentVersion < latestVersion` returns `UpdateType.optional`
- Otherwise, `UpdateType.none`
