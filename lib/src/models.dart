enum UpdateType { none, optional, force, maintenance }

class VersionRule {
  final String minVersion;     // Anything below this should trigger the package to recommend an update (force if below min, optional if between min and latest)
  final String latestVersion;  // The latest version available, used for display and to determine if the user is up to date
  final String? storeUrl;       // URL to the app store page for the latest version, used for directing users to update.
  final String? message;       // An optional message to display to users when an update is recommended, can be used to provide additional context or instructions.
  final bool maintenance;      // If true, the app is in maintenance mode and should not be used regardless of version. This overrides all other checks.
  const VersionRule({
    required this.minVersion,
    required this.latestVersion,
    this.storeUrl,
    this.message,
    this.maintenance = false,
  });
}

class UpdateDecision {
  final UpdateType type;
  final String currentVersion;
  final String minVersion;
  final String latestVersion;
  final String? storeUrl;
  final String? message;

  const UpdateDecision._({
    required this.type,
    required this.currentVersion,
    required this.minVersion,
    required this.latestVersion,
    this.storeUrl,
    this.message,
  });

  factory UpdateDecision.none({
    required String currentVersion,
    required String minVersion,
    required String latestVersion,
  }) =>
      UpdateDecision._(
        type: UpdateType.none,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,

      );

  factory UpdateDecision.optional({
    required String currentVersion,
    required String minVersion,
    required String latestVersion,
    String? storeUrl,
    String? message,
  }) =>
      UpdateDecision._(
        type: UpdateType.optional,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,
        storeUrl: storeUrl,
        message: message,
      );

  factory UpdateDecision.force({
    required String currentVersion,
    required String minVersion,
    required String latestVersion,
    String? storeUrl,
    String? message,
  }) =>
      UpdateDecision._(
        type: UpdateType.force,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,
        storeUrl: storeUrl,
        message: message,
      );

  factory UpdateDecision.maintenance({
    required String currentVersion,
    required String minVersion,
    required String latestVersion,
    String? message,
  }) =>
      UpdateDecision._(
        type: UpdateType.maintenance,
        currentVersion: currentVersion,
        minVersion: minVersion,
        latestVersion: latestVersion,
        message: message,
      );
}