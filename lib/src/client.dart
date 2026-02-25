import 'models.dart';
import 'provider.dart';
import 'version_compare.dart';

class InAppVersionControl {
  final VersionRuleProvider provider;

  const InAppVersionControl({required this.provider});

  Future<UpdateDecision> check({
    required String appId,
    required String platform,
    required String currentVersion,
  }) async {
    final rule = await provider.fetchRule(appId: appId, platform: platform);

    // Maintenance overrides everything
    if (rule.maintenance) {
      return UpdateDecision.maintenance(
        currentVersion: currentVersion,
        minVersion: rule.minVersion,
        latestVersion: rule.latestVersion,
        message: rule.message,
      );
    }

    // If current < min => force update
    if (compareVersions(currentVersion, rule.minVersion) < 0) {
      return UpdateDecision.force(
        currentVersion: currentVersion,
        minVersion: rule.minVersion,
        latestVersion: rule.latestVersion,
        storeUrl: rule.storeUrl,
        message: rule.message,
      );
    }

    // If current < latest => optional update
    if (compareVersions(currentVersion, rule.latestVersion) < 0) {
      return UpdateDecision.optional(
        currentVersion: currentVersion,
        minVersion: rule.minVersion,
        latestVersion: rule.latestVersion,
        storeUrl: rule.storeUrl,
        message: rule.message,
      );
    }

    return UpdateDecision.none(
      currentVersion: currentVersion,
      minVersion: rule.minVersion,
      latestVersion: rule.latestVersion,
    );
  }
}