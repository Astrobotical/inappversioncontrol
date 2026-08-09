import 'models.dart';

/// A backend adapter (Firebase, Supabase, REST, etc.)
abstract class VersionRuleProvider {
  /// Example: [appId] = `com.company.app`, [platform] = [AppPlatform.android].
  Future<VersionRule> fetchRule({
    required String appId,
    required AppPlatform platform,
  });
}
