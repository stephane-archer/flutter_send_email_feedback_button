import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:url_launcher/url_launcher.dart';

import 'feedback_context_diagnostics.dart';
import 'feedback_runtime_diagnostics.dart';

const Duration _defaultRuntimeDiagnosticsTimeout = Duration(seconds: 2);

Map<String, String> _normalizeDiagnosticValues(
  final Map<String, String?> diagnostics,
) {
  final values = <String, String>{};
  for (final entry in diagnostics.entries) {
    final label = entry.key.trim();
    final value = entry.value?.trim();
    if (label.isNotEmpty && value != null && value.isNotEmpty) {
      values[label] = value;
    }
  }
  return values;
}

/// Builds a percent-encoded `mailto:` URI.
///
/// Query components are encoded explicitly instead of using
/// [Uri.queryParameters], which can represent spaces as `+`. Some email clients
/// interpret `+` literally in `mailto:` query values.
@visibleForTesting
Uri buildEmailUri({
  required final String emailAddress,
  required final String emailSubject,
  final String? emailBody,
}) {
  final query = <String>[
    'subject=${Uri.encodeComponent(emailSubject)}',
    if (emailBody != null) 'body=${Uri.encodeComponent(emailBody)}',
  ].join('&');
  return Uri(scheme: 'mailto', path: emailAddress, query: query);
}

/// Builds the text body used by a feedback email.
///
/// [emailBody] is kept as the user-facing first section. Runtime metadata and
/// [additionalDiagnostics] are appended under [diagnosticsHeading]. Additional
/// values override runtime values with the same label. Null and blank values
/// are omitted.
@visibleForTesting
String? buildFeedbackEmailBody({
  final String? emailBody,
  final FeedbackRuntimeDiagnostics? runtimeDiagnostics,
  final Map<String, String?> additionalDiagnostics = const {},
  final String diagnosticsHeading = 'Diagnostics:',
}) {
  final values = <String, String>{...?runtimeDiagnostics?.toDiagnosticValues()};
  values.addAll(_normalizeDiagnosticValues(additionalDiagnostics));

  final sections = <String>[];
  if (emailBody != null && emailBody.isNotEmpty) {
    sections.add(emailBody);
  }
  if (values.isNotEmpty) {
    sections.add(
      [
        diagnosticsHeading,
        for (final entry in values.entries) '${entry.key}: ${entry.value}',
      ].join('\n'),
    );
  }
  return sections.isEmpty ? null : sections.join('\n\n');
}

/// Builds a feedback email URI, collecting runtime metadata when requested.
///
/// If runtime metadata cannot be collected, email creation still succeeds and
/// records that the metadata was unavailable. Collection is bounded by
/// [runtimeDiagnosticsTimeout] so a stalled platform lookup cannot prevent the
/// email launch.
@visibleForTesting
Future<Uri> buildFeedbackEmailUri({
  required final String emailAddress,
  required final String emailSubject,
  final String? emailBody,
  final bool includeRuntimeDiagnostics = false,
  final Map<String, String?> additionalDiagnostics = const {},
  final String diagnosticsHeading = 'Diagnostics:',
  final FeedbackRuntimeDiagnosticsProvider runtimeDiagnosticsProvider =
      collectFeedbackRuntimeDiagnostics,
  final Duration runtimeDiagnosticsTimeout = _defaultRuntimeDiagnosticsTimeout,
}) async {
  FeedbackRuntimeDiagnostics? runtimeDiagnostics;
  final resolvedAdditionalDiagnostics = _normalizeDiagnosticValues(
    additionalDiagnostics,
  );
  if (includeRuntimeDiagnostics) {
    try {
      runtimeDiagnostics = await runtimeDiagnosticsProvider().timeout(
        runtimeDiagnosticsTimeout,
      );
    } catch (_) {
      const runtimeDiagnosticsLabel = 'Runtime diagnostics';
      if (!resolvedAdditionalDiagnostics.containsKey(runtimeDiagnosticsLabel)) {
        resolvedAdditionalDiagnostics[runtimeDiagnosticsLabel] = 'unavailable';
      }
    }
  }

  final body = buildFeedbackEmailBody(
    emailBody: emailBody,
    runtimeDiagnostics: runtimeDiagnostics,
    additionalDiagnostics: resolvedAdditionalDiagnostics,
    diagnosticsHeading: diagnosticsHeading,
  );
  return buildEmailUri(
    emailAddress: emailAddress,
    emailSubject: emailSubject,
    emailBody: body,
  );
}

/// Opens a feedback email in the device's default email client.
///
/// Returns the result reported by `url_launcher` for the launch request. A
/// `true` result does not guarantee that an email client opened; on web,
/// allowed URI schemes are reported as successful because the browser does not
/// expose whether the navigation completed. Runtime metadata collection is
/// limited to two seconds; if it fails or times out, the launch is still
/// attempted with an unavailable diagnostic marker. When
/// [diagnosticsContext] is provided, the resolved app locale and current view
/// metrics are also included.
Future<bool> sendEmail({
  required final String emailAddress,
  required final String emailSubject,
  final String? emailBody,
  final bool includeRuntimeDiagnostics = false,
  final BuildContext? diagnosticsContext,
  final Map<String, String?> additionalDiagnostics = const {},
  final String diagnosticsHeading = 'Diagnostics:',
}) async {
  if (!includeRuntimeDiagnostics) {
    final body = buildFeedbackEmailBody(
      emailBody: emailBody,
      additionalDiagnostics: additionalDiagnostics,
      diagnosticsHeading: diagnosticsHeading,
    );
    final uri = buildEmailUri(
      emailAddress: emailAddress,
      emailSubject: emailSubject,
      emailBody: body,
    );
    // Keep the URI synchronously ready so web launches retain their default
    // browsing-context behavior and remain directly tied to the user action.
    return launchUrl(uri);
  }

  // Context-dependent values must be read before the first asynchronous gap.
  // Caller-provided values retain the existing override behavior.
  final contextDiagnostics = collectFeedbackContextDiagnostics(
    diagnosticsContext,
  );
  final resolvedAdditionalDiagnostics = <String, String?>{
    ...contextDiagnostics,
    ...additionalDiagnostics,
  };
  final uri = await buildFeedbackEmailUri(
    emailAddress: emailAddress,
    emailSubject: emailSubject,
    emailBody: emailBody,
    includeRuntimeDiagnostics: true,
    additionalDiagnostics: resolvedAdditionalDiagnostics,
    diagnosticsHeading: diagnosticsHeading,
  );
  // Using the current browsing context keeps web launches working after an
  // asynchronous diagnostics lookup. Opening a new window after awaiting a
  // Future may otherwise be blocked because it is no longer considered a
  // direct user action. Other platforms ignore this web-only option.
  return launchUrl(uri, webOnlyWindowName: '_self');
}
