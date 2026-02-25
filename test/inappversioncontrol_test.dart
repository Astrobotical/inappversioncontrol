import 'package:flutter_test/flutter_test.dart';

import 'package:inappversioncontrol/in_app_version_control.dart';

class FakeProvider implements VersionRuleProvider {
  @override
  Future<VersionRule> fetchRule({required String appId, required String platform}) async {
    return const VersionRule(
      minVersion: '1.0.0',
      latestVersion: '1.2.0',
      storeUrl: 'https://example.com',
      message: 'Update available',
      maintenance: false,
    );
  }
}

void main() {
  test('optional update when behind latest but above min', () async {
    final vc = InAppVersionControl(provider: FakeProvider());
    final decision = await vc.check(
      appId: 'com.example.app',
      platform: 'android',
      currentVersion: '1.1.0',
    );
    expect(decision.type, UpdateType.optional);
  });

  test('force update when below min', () async {
    final vc = InAppVersionControl(provider: FakeProvider());
    final decision = await vc.check(
      appId: 'com.example.app',
      platform: 'android',
      currentVersion: '0.9.0',
    );
    expect(decision.type, UpdateType.force);
  });
}
