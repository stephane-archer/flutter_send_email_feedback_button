import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'platform_info.dart' as platform_info;

/// Supplies runtime metadata for a feedback email.
typedef FeedbackRuntimeDiagnosticsProvider = Future<FeedbackRuntimeDiagnostics>
    Function();

/// Runtime metadata that can accompany a feedback email.
///
/// The default collector includes application identity/version information and
/// the operating-system name/version.
@immutable
final class FeedbackRuntimeDiagnostics {
  final String applicationName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String operatingSystem;
  final String operatingSystemVersion;

  const FeedbackRuntimeDiagnostics({
    required this.applicationName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.operatingSystem,
    required this.operatingSystemVersion,
  });

  /// Collects application and operating-system metadata for the current app.
  static Future<FeedbackRuntimeDiagnostics> collect() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return FeedbackRuntimeDiagnostics(
      applicationName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      operatingSystem: platform_info.operatingSystem,
      operatingSystemVersion: platform_info.operatingSystemVersion,
    );
  }

  /// Returns the ordered, non-empty fields shown in a feedback email.
  Map<String, String> toDiagnosticValues() {
    final values = <String, String>{};

    void addIfPresent(final String label, final String value) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        values[label] = normalized;
      }
    }

    addIfPresent('Application', applicationName);
    addIfPresent('Package', packageName);
    final normalizedVersion = version.trim();
    final normalizedBuildNumber = buildNumber.trim();
    if (normalizedVersion.isNotEmpty || normalizedBuildNumber.isNotEmpty) {
      values['App version'] = switch ((
        normalizedVersion,
        normalizedBuildNumber,
      )) {
        (final version, '') => version,
        ('', final buildNumber) => buildNumber,
        (final version, final buildNumber) => '$version+$buildNumber',
      };
    }
    addIfPresent('Operating system', operatingSystem);
    addIfPresent('OS version', operatingSystemVersion);
    return values;
  }
}

/// Collects the default runtime diagnostics.
Future<FeedbackRuntimeDiagnostics> collectFeedbackRuntimeDiagnostics() {
  return FeedbackRuntimeDiagnostics.collect();
}
