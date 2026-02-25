/// A backend adapter (Firebase, Supabase, REST, etc.)
import 'models.dart';
abstract class VersionRuleProvider {
  /// Example: appId = "com.company.app", platform = "android"/"ios"/"web"
  Future<VersionRule> fetchRule({
    required String appId,
    required String platform,
  });
}