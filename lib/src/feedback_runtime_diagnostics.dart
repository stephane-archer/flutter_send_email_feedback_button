import 'dart:ui' show Locale;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show WidgetsBinding;
import 'package:package_info_plus/package_info_plus.dart';

import 'platform_info.dart' as platform_info;

/// Supplies runtime metadata for a feedback email.
typedef FeedbackRuntimeDiagnosticsProvider =
    Future<FeedbackRuntimeDiagnostics> Function();

/// Runtime metadata that can accompany a feedback email.
///
/// The default collector includes application identity/version information,
/// operating-system details, system locales, process architecture, and a
/// non-identifying device model when one is reliably available.
@immutable
final class FeedbackRuntimeDiagnostics {
  final String applicationName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String operatingSystem;
  final String operatingSystemVersion;
  final String systemLocales;
  final String processArchitecture;
  final String deviceModel;

  const FeedbackRuntimeDiagnostics({
    required this.applicationName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.operatingSystem,
    required this.operatingSystemVersion,
    this.systemLocales = '',
    this.processArchitecture = '',
    this.deviceModel = '',
  });

  /// Collects privacy-safe runtime metadata for the current app.
  ///
  /// Package and device lookups are independent and best-effort. A failure in
  /// either source leaves its fields empty without discarding other metadata.
  static Future<FeedbackRuntimeDiagnostics> collect() async {
    final packageInfoFuture = _collectPackageInfo();
    final deviceModelFuture = _collectDeviceModel();
    final packageInfo = await packageInfoFuture;
    final deviceModel = await deviceModelFuture;
    return FeedbackRuntimeDiagnostics(
      applicationName: packageInfo?.appName ?? '',
      packageName: packageInfo?.packageName ?? '',
      version: packageInfo?.version ?? '',
      buildNumber: packageInfo?.buildNumber ?? '',
      operatingSystem: platform_info.operatingSystem,
      operatingSystemVersion: platform_info.operatingSystemVersion,
      systemLocales: formatSystemLocales(
        WidgetsBinding.instance.platformDispatcher.locales,
      ),
      processArchitecture: platform_info.processArchitecture,
      deviceModel: deviceModel,
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
    addIfPresent('System locales', systemLocales);
    addIfPresent('Process architecture', processArchitecture);
    addIfPresent('Device model', deviceModel);
    return values;
  }
}

@visibleForTesting
String formatSystemLocales(final Iterable<Locale> locales) {
  return locales.map((final locale) => locale.toLanguageTag()).join(', ');
}

Future<PackageInfo?> _collectPackageInfo() async {
  try {
    return await PackageInfo.fromPlatform();
  } catch (_) {
    return null;
  }
}

Future<String> _collectDeviceModel() async {
  if (kIsWeb) {
    return '';
  }

  try {
    final deviceInfo = DeviceInfoPlugin();
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _formatAndroidDeviceModel(
        await deviceInfo.androidInfo,
      ),
      TargetPlatform.iOS => (await deviceInfo.iosInfo).modelName,
      TargetPlatform.macOS => (await deviceInfo.macOsInfo).model,
      TargetPlatform.fuchsia ||
      TargetPlatform.linux ||
      TargetPlatform.windows => '',
    };
  } catch (_) {
    return '';
  }
}

String _formatAndroidDeviceModel(final AndroidDeviceInfo deviceInfo) {
  return formatAndroidDeviceModel(
    manufacturer: deviceInfo.manufacturer,
    model: deviceInfo.model,
  );
}

@visibleForTesting
String formatAndroidDeviceModel({
  required final String manufacturer,
  required final String model,
}) {
  final normalizedManufacturer = manufacturer.trim();
  final normalizedModel = model.trim();
  if (normalizedManufacturer.isEmpty ||
      normalizedModel.toLowerCase().startsWith(
        normalizedManufacturer.toLowerCase(),
      )) {
    return normalizedModel;
  }
  if (normalizedModel.isEmpty) {
    return normalizedManufacturer;
  }
  return '$normalizedManufacturer $normalizedModel';
}

/// Collects the default runtime diagnostics.
Future<FeedbackRuntimeDiagnostics> collectFeedbackRuntimeDiagnostics() {
  return FeedbackRuntimeDiagnostics.collect();
}
