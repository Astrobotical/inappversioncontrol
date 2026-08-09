import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_version_control/in_app_version_control.dart';

class FakeProvider implements VersionRuleProvider {
  final VersionRule rule;

  FakeProvider(this.rule);

  @override
  Future<VersionRule> fetchRule({
    required String appId,
    required AppPlatform platform,
  }) async {
    return rule;
  }
}

void main() {
  test('returns optional update when behind latest but above min', () async {
    final vc = InAppVersionControl(
      provider: FakeProvider(
        const VersionRule(
          minVersion: '1.0.0',
          latestVersion: '1.2.0',
          storeUrl: 'https://example.com',
          message: 'Update available',
        ),
      ),
    );
    final decision = await vc.check(
      appId: 'com.example.app',
      platform: AppPlatform.android,
      currentVersion: '1.1.0',
    );
    expect(decision.type, UpdateType.optional);
  });

  test('returns force update when below min version', () async {
    final vc = InAppVersionControl(
      provider: FakeProvider(
        const VersionRule(
          minVersion: '1.0.0',
          latestVersion: '1.2.0',
          storeUrl: 'https://example.com',
          message: 'Update available',
        ),
      ),
    );
    final decision = await vc.check(
      appId: 'com.example.app',
      platform: AppPlatform.android,
      currentVersion: '0.9.0',
    );
    expect(decision.type, UpdateType.force);
  });

  test('returns none when current version matches latest', () async {
    final vc = InAppVersionControl(
      provider: FakeProvider(
        const VersionRule(minVersion: '1.0.0', latestVersion: '1.2.0'),
      ),
    );

    final decision = await vc.check(
      appId: 'com.example.app',
      platform: AppPlatform.android,
      currentVersion: '1.2.0',
    );

    expect(decision.type, UpdateType.none);
    expect(decision.requiresAction, isFalse);
  });

  test('returns maintenance when maintenance mode is enabled', () async {
    final vc = InAppVersionControl(
      provider: FakeProvider(
        const VersionRule(
          minVersion: '1.0.0',
          latestVersion: '1.2.0',
          maintenance: true,
          message: 'Scheduled maintenance',
        ),
      ),
    );

    final decision = await vc.check(
      appId: 'com.example.app',
      platform: AppPlatform.ios,
      currentVersion: '9.9.9',
    );

    expect(decision.type, UpdateType.maintenance);
    expect(decision.message, 'Scheduled maintenance');
  });

  test('compares versions with different segment lengths', () {
    expect(compareVersions('1.2', '1.2.0'), 0);
    expect(compareVersions('1.2.1', '1.2'), greaterThan(0));
  });

  test('throws for invalid version strings', () {
    expect(() => compareVersions('1.0.0-beta', '1.0.0'), throwsFormatException);
  });

  test(
    'endpoint provider maps the default contract from a custom backend',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });

      server.listen((request) async {
        expect(request.uri.queryParameters['appId'], 'com.example.app');
        expect(request.uri.queryParameters['platform'], 'android');

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'minVersion': '1.0.0',
              'latestVersion': '1.2.0',
              'storeUrl': 'https://example.com/store',
              'message': 'Upgrade now',
              'maintenance': false,
            }),
          );
        await request.response.close();
      });

      final provider = EndpointVersionRuleProvider(
        endpoint: Uri.parse(
          'http://${server.address.host}:${server.port}/rule',
        ),
      );
      addTearDown(provider.close);

      final decision = await InAppVersionControl(provider: provider).check(
        appId: 'com.example.app',
        platform: AppPlatform.android,
        currentVersion: '0.9.0',
      );

      expect(decision.type, UpdateType.force);
      expect(decision.storeUrl, 'https://example.com/store');
    },
  );

  test(
    'endpoint provider supports custom response mapping for existing APIs',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async {
        await server.close(force: true);
      });

      server.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        final payload = jsonDecode(body) as Map<String, dynamic>;

        expect(payload['appId'], 'com.example.app');
        expect(payload['platform'], 'ios');

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'data': {
                'minimum_supported': '1.0.0',
                'latest_available': '1.1.0',
                'upgrade_url': 'https://example.com/ios',
                'notice': 'Minor improvements',
                'maintenance_mode': false,
              },
            }),
          );
        await request.response.close();
      });

      final provider = EndpointVersionRuleProvider(
        endpoint: Uri.parse(
          'http://${server.address.host}:${server.port}/rule',
        ),
        method: EndpointRequestMethod.post,
        ruleBuilder: (json, context) {
          final data = json['data'] as Map<String, dynamic>;
          return VersionRule(
            minVersion: data['minimum_supported'] as String,
            latestVersion: data['latest_available'] as String,
            storeUrl: data['upgrade_url'] as String?,
            message: data['notice'] as String?,
            maintenance: data['maintenance_mode'] as bool? ?? false,
          );
        },
      );
      addTearDown(provider.close);

      final decision = await InAppVersionControl(provider: provider).check(
        appId: 'com.example.app',
        platform: AppPlatform.ios,
        currentVersion: '1.0.5',
      );

      expect(decision.type, UpdateType.optional);
      expect(decision.message, 'Minor improvements');
    },
  );
}
