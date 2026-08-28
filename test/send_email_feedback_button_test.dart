import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:send_email_feedback_button/send_email_feedback_button.dart'
    show SendEmailFeedbackButton, sendEmail;
import 'package:send_email_feedback_button/src/feedback_context_diagnostics.dart'
    show collectFeedbackContextDiagnostics;
import 'package:send_email_feedback_button/src/feedback_email.dart'
    show buildEmailUri, buildFeedbackEmailBody, buildFeedbackEmailUri;
import 'package:send_email_feedback_button/src/feedback_runtime_diagnostics.dart'
    show
        FeedbackRuntimeDiagnostics,
        formatAndroidDeviceModel,
        formatSystemLocales;
import 'package:send_email_feedback_button/src/platform_info.dart'
    as platform_info;
import 'package:send_email_feedback_button/src/platform_info_stub.dart'
    as web_platform_info;
import 'package:url_launcher_platform_interface/link.dart' show LinkDelegate;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart'
    show UrlLauncherPlatform;

final class _RecordingUrlLauncher extends UrlLauncherPlatform {
  _RecordingUrlLauncher({required this.launchResult, this.pendingLaunch});

  final bool launchResult;
  final Completer<bool>? pendingLaunch;
  int launchCount = 0;
  String? launchedUrl;
  String? webOnlyWindowName;

  @override
  final LinkDelegate? linkDelegate = null;

  @override
  Future<bool> launch(
    final String url, {
    required final bool useSafariVC,
    required final bool useWebView,
    required final bool enableJavaScript,
    required final bool enableDomStorage,
    required final bool universalLinksOnly,
    required final Map<String, String> headers,
    final String? webOnlyWindowName,
  }) {
    launchCount += 1;
    launchedUrl = url;
    this.webOnlyWindowName = webOnlyWindowName;
    return pendingLaunch?.future ?? Future<bool>.value(launchResult);
  }
}

void main() {
  const runtimeDiagnostics = FeedbackRuntimeDiagnostics(
    applicationName: 'Zero Loss Compress',
    packageName: 'com.example.zeroLossCompress',
    version: '1.6.4',
    buildNumber: '12',
    operatingSystem: 'macos',
    operatingSystemVersion: 'Version 15.0',
    systemLocales: 'ko-KR, en-US',
    processArchitecture: 'macos_arm64',
    deviceModel: 'MacBookPro18,3',
  );

  test('builds a percent-encoded URI with subject and body', () {
    final uri = buildEmailUri(
      emailAddress: 'support@example.com',
      emailSubject: 'Feedback & support',
      emailBody: 'First line\nSecond line + details',
    );

    expect(uri.scheme, 'mailto');
    expect(uri.path, 'support@example.com');
    expect(uri.queryParameters['subject'], 'Feedback & support');
    expect(uri.queryParameters['body'], 'First line\nSecond line + details');
    expect(uri.toString(), contains('Feedback%20%26%20support'));
    expect(uri.toString(), isNot(contains('Feedback+%26+support')));
  });

  test('combines runtime and application-specific diagnostics', () {
    final body = buildFeedbackEmailBody(
      emailBody: 'Please describe the issue:',
      runtimeDiagnostics: runtimeDiagnostics,
      additionalDiagnostics: const {
        'Most recent error': 'FileSystemException',
        'Publication state': 'attempted',
        'Publication mode': 'exclusive copy',
        'Empty value': '  ',
        'Null value': null,
      },
      diagnosticsHeading: 'Diagnostics:',
    );

    expect(body, startsWith('Please describe the issue:'));
    expect(body, contains('Application: Zero Loss Compress'));
    expect(body, contains('App version: 1.6.4+12'));
    expect(body, contains('Operating system: macos'));
    expect(body, contains('System locales: ko-KR, en-US'));
    expect(body, contains('Process architecture: macos_arm64'));
    expect(body, contains('Device model: MacBookPro18,3'));
    expect(body, contains('Most recent error: FileSystemException'));
    expect(body, contains('Publication mode: exclusive copy'));
    expect(body, isNot(contains('Empty value')));
    expect(body, isNot(contains('Null value')));
  });

  test('application diagnostics can override a runtime label', () {
    final body = buildFeedbackEmailBody(
      runtimeDiagnostics: runtimeDiagnostics,
      additionalDiagnostics: const {'App version': 'redacted'},
    );

    expect(body, contains('App version: redacted'));
    expect(body, isNot(contains('App version: 1.6.4+12')));
  });

  test('collects runtime diagnostics when requested', () async {
    final uri = await buildFeedbackEmailUri(
      emailAddress: 'support@example.com',
      emailSubject: 'Feedback',
      emailBody: 'Describe the issue:',
      includeRuntimeDiagnostics: true,
      additionalDiagnostics: const {'Publication mode': 'atomic hard link'},
      runtimeDiagnosticsProvider: () async => runtimeDiagnostics,
    );
    final body = uri.queryParameters['body']!;

    expect(body, contains('App version: 1.6.4+12'));
    expect(body, contains('Publication mode: atomic hard link'));
  });

  test('still builds an email when runtime collection fails', () async {
    final uri = await buildFeedbackEmailUri(
      emailAddress: 'support@example.com',
      emailSubject: 'Feedback',
      includeRuntimeDiagnostics: true,
      runtimeDiagnosticsProvider: () => Future.error(StateError('failed')),
    );

    expect(
      uri.queryParameters['body'],
      contains('Runtime diagnostics: unavailable'),
    );
  });

  test('replaces a blank runtime failure override with the fallback', () async {
    for (final existingValue in <String?>[null, '  ']) {
      final uri = await buildFeedbackEmailUri(
        emailAddress: 'support@example.com',
        emailSubject: 'Feedback',
        includeRuntimeDiagnostics: true,
        additionalDiagnostics: {'Runtime diagnostics': existingValue},
        runtimeDiagnosticsProvider: () => Future.error(StateError('failed')),
      );

      expect(
        uri.queryParameters['body'],
        contains('Runtime diagnostics: unavailable'),
      );
    }
  });

  test(
    'normalizes a runtime failure override before applying fallback',
    () async {
      final uri = await buildFeedbackEmailUri(
        emailAddress: 'support@example.com',
        emailSubject: 'Feedback',
        includeRuntimeDiagnostics: true,
        additionalDiagnostics: const {
          ' Runtime diagnostics ': ' intentionally hidden ',
        },
        runtimeDiagnosticsProvider: () => Future.error(StateError('failed')),
      );

      final body = uri.queryParameters['body'];
      expect(body, contains('Runtime diagnostics: intentionally hidden'));
      expect(body, isNot(contains('Runtime diagnostics: unavailable')));
    },
  );

  test('web platform metadata omits an invented OS version', () {
    expect(web_platform_info.operatingSystem, 'web');
    expect(web_platform_info.operatingSystemVersion, isEmpty);
    expect(web_platform_info.processArchitecture, isEmpty);
  });

  test('formats system locales as ordered BCP-47 language tags', () {
    expect(
      formatSystemLocales(const [Locale('ko', 'KR'), Locale('en', 'US')]),
      'ko-KR, en-US',
    );
  });

  test('reports the native process architecture without CPU details', () {
    expect(
      platform_info.processArchitecture,
      matches(
        RegExp(
          r'^(android|fuchsia|ios|linux|macos|windows)_'
          r'(arm|arm64|ia32|x64|riscv32|riscv64)$',
        ),
      ),
    );
  });

  test('formats a privacy-safe Android manufacturer and model', () {
    expect(
      formatAndroidDeviceModel(manufacturer: 'Google', model: 'Pixel 9'),
      'Google Pixel 9',
    );
    expect(
      formatAndroidDeviceModel(
        manufacturer: 'Samsung',
        model: 'Samsung Galaxy S25',
      ),
      'Samsung Galaxy S25',
    );
  });

  test('still builds an email when runtime collection stalls', () async {
    final stalledDiagnostics = Completer<FeedbackRuntimeDiagnostics>();
    final uri = await buildFeedbackEmailUri(
      emailAddress: 'support@example.com',
      emailSubject: 'Feedback',
      includeRuntimeDiagnostics: true,
      runtimeDiagnosticsProvider: () => stalledDiagnostics.future,
      runtimeDiagnosticsTimeout: const Duration(milliseconds: 1),
    );

    expect(
      uri.queryParameters['body'],
      contains('Runtime diagnostics: unavailable'),
    );
  });

  test(
    'preserves the default web target without runtime diagnostics',
    () async {
      final originalLauncher = UrlLauncherPlatform.instance;
      final launcher = _RecordingUrlLauncher(launchResult: false);
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);

      final launchResult = sendEmail(
        emailAddress: 'support@example.com',
        emailSubject: 'Feedback',
        emailBody: 'Describe the issue:',
      );

      // The launch must be requested before the first asynchronous boundary so
      // browsers continue to treat it as part of the user action.
      expect(launcher.launchedUrl, isNotNull);
      expect(launcher.webOnlyWindowName, isNull);
      expect(await launchResult, isFalse);
      final launchedUri = Uri.parse(launcher.launchedUrl!);
      expect(launchedUri.scheme, 'mailto');
      expect(launchedUri.queryParameters['body'], 'Describe the issue:');
    },
  );

  test('preserves the version 0.2 default URI behavior', () async {
    final originalLauncher = UrlLauncherPlatform.instance;
    final launcher = _RecordingUrlLauncher(launchResult: true);
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);

    expect(
      await sendEmail(
        emailAddress: 'support@example.com',
        emailSubject: 'Feedback & support',
      ),
      isTrue,
    );

    final launchedUri = Uri.parse(launcher.launchedUrl!);
    expect(launchedUri.scheme, 'mailto');
    expect(launchedUri.path, 'support@example.com');
    expect(launchedUri.queryParameters['subject'], 'Feedback & support');
    expect(launchedUri.queryParameters.containsKey('body'), isFalse);
    expect(launcher.webOnlyWindowName, isNull);
  });

  test('uses the current web target after runtime diagnostics', () async {
    final originalLauncher = UrlLauncherPlatform.instance;
    final launcher = _RecordingUrlLauncher(launchResult: true);
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);

    final launchResult = sendEmail(
      emailAddress: 'support@example.com',
      emailSubject: 'Feedback',
      includeRuntimeDiagnostics: true,
    );

    expect(launcher.launchedUrl, isNull);
    expect(await launchResult, isTrue);
    expect(launcher.webOnlyWindowName, '_self');
    final launchedUri = Uri.parse(launcher.launchedUrl!);
    expect(launchedUri.scheme, 'mailto');
  });

  testWidgets('widget exposes body and diagnostic configuration', (
    final tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SendEmailFeedbackButton(
          emailAddress: 'support@example.com',
          emailSubject: 'Feedback',
          emailBody: 'Describe the issue:',
          includeRuntimeDiagnostics: true,
          additionalDiagnostics: {'Mode': 'safe'},
          label: 'Contact support',
        ),
      ),
    );

    expect(find.text('Contact support'), findsOneWidget);
    expect(find.byIcon(Icons.email), findsOneWidget);
    final widget = tester.widget<SendEmailFeedbackButton>(
      find.byType(SendEmailFeedbackButton),
    );
    expect(widget.emailBody, 'Describe the issue:');
    expect(widget.includeRuntimeDiagnostics, isTrue);
    expect(widget.additionalDiagnostics, {'Mode': 'safe'});
  });

  testWidgets('collects resolved app locale and current view metrics', (
    final tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [
      Locale('ko', 'KR'),
      Locale('en', 'US'),
    ];
    tester.view.devicePixelRatio = 2;
    tester.view.physicalSize = const Size(2400, 1600);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    late BuildContext feedbackContext;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('en')],
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 240), devicePixelRatio: 4),
          child: Builder(
            builder: (final context) {
              feedbackContext = context;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    final diagnostics = collectFeedbackContextDiagnostics(feedbackContext);
    expect(diagnostics['App locale'], 'en');
    expect(diagnostics['Window size (logical pixels)'], '1200x800');
    expect(diagnostics['Device pixel ratio'], '2.00');
    expect(
      formatSystemLocales(tester.platformDispatcher.locales),
      'ko-KR, en-US',
    );

    final originalLauncher = UrlLauncherPlatform.instance;
    final launcher = _RecordingUrlLauncher(launchResult: true);
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);

    await tester.runAsync(
      () => sendEmail(
        emailAddress: 'support@example.com',
        emailSubject: 'Feedback',
        includeRuntimeDiagnostics: true,
        diagnosticsContext: feedbackContext,
        additionalDiagnostics: const {'App locale': 'overridden'},
      ),
    );
    final body = Uri.parse(launcher.launchedUrl!).queryParameters['body'];
    expect(body, contains('App locale: overridden'));
    expect(body, contains('System locales: ko-KR, en-US'));
    expect(body, contains('Window size (logical pixels): 1200x800'));
    expect(body, contains('Device pixel ratio: 2.00'));
    expect(body, isNot(contains('App locale: en')));
  });

  test('omits context-scoped diagnostics when no context is supplied', () {
    expect(collectFeedbackContextDiagnostics(null), isEmpty);
  });

  test('runtime diagnostics exclude identifying and emulator fields', () {
    expect(
      runtimeDiagnostics.toDiagnosticValues().keys,
      isNot(
        containsAll(<String>[
          'Device name',
          'Host name',
          'User name',
          'Machine ID',
          'GUID',
          'CPU name',
          'Emulator',
          'Physical device',
        ]),
      ),
    );
  });

  testWidgets('widget prevents duplicate launches while one is in progress', (
    final tester,
  ) async {
    final originalLauncher = UrlLauncherPlatform.instance;
    final pendingLaunch = Completer<bool>();
    final launcher = _RecordingUrlLauncher(
      launchResult: true,
      pendingLaunch: pendingLaunch,
    );
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = originalLauncher);

    await tester.pumpWidget(
      const MaterialApp(
        home: SendEmailFeedbackButton(
          emailAddress: 'support@example.com',
          emailSubject: 'Feedback',
        ),
      ),
    );
    final feedbackButton = find.byWidgetPredicate(
      (final widget) => widget is ElevatedButton,
    );

    await tester.tap(feedbackButton);
    await tester.pump();

    final disabledButton = tester.widget<ElevatedButton>(feedbackButton);
    expect(disabledButton.onPressed, isNull);
    expect(launcher.launchCount, 1);

    await tester.tap(feedbackButton);
    expect(launcher.launchCount, 1);

    pendingLaunch.complete(true);
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<ElevatedButton>(feedbackButton);
    expect(enabledButton.onPressed, isNotNull);
  });
}
