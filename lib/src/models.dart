enum UpdateType { none, optional, force, maintenance }

enum AppPlatform {
  android('android'),
  ios('ios'),
  web('web'),
  macos('macos'),
  windows('windows'),
  linux('linux');

  final String value;

  const AppPlatform(this.value);
}

class VersionRule {
  final String minVersion;
  final String latestVersion;
  final String? storeUrl;
  final String? message;
  final bool maintenance;

  const VersionRule({
    required this.minVersion,
    required this.latestVersion,
    this.storeUrl,
    this.message,
    this.maintenance = false,
  });

  factory VersionRule.fromJson(Map<String, dynamic> json) {
    return VersionRule(
      minVersion: json['minVersion'] as String,
      latestVersion: json['latestVersion'] as String,
      storeUrl: json['storeUrl'] as String?,
      message: json['message'] as String?,
      maintenance: json['maintenance'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minVersion': minVersion,
      'latestVersion': latestVersion,
      'storeUrl': storeUrl,
      'message': message,
      'maintenance': maintenance,
    };
  }
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
  }) => UpdateDecision._(
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
  }) => UpdateDecision._(
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
  }) => UpdateDecision._(
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
  }) => UpdateDecision._(
    type: UpdateType.maintenance,
    currentVersion: currentVersion,
    minVersion: minVersion,
    latestVersion: latestVersion,
    message: message,
  );

  bool get requiresAction => type != UpdateType.none;
}
