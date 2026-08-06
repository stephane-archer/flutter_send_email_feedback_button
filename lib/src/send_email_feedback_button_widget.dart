import 'package:flutter/material.dart';

import 'feedback_email.dart';

/// A Material button that opens a pre-filled feedback email.
class SendEmailFeedbackButton extends StatelessWidget {
  final String _emailAddress;
  final String _emailSubject;
  final String? emailBody;
  final bool includeRuntimeDiagnostics;
  final Map<String, String?> additionalDiagnostics;
  final String _diagnosticsHeading;
  final String _label;

  const SendEmailFeedbackButton({
    super.key,
    required String emailAddress,
    required String emailSubject,
    this.emailBody,
    this.includeRuntimeDiagnostics = false,
    this.additionalDiagnostics = const {},
    String diagnosticsHeading = 'Diagnostics:',
    String label = 'Send feedback',
  })  : _label = label,
        _diagnosticsHeading = diagnosticsHeading,
        _emailSubject = emailSubject,
        _emailAddress = emailAddress;

  @override
  Widget build(final BuildContext context) {
    return _FeedbackEmailLaunchButton(
      label: _label,
      launchEmail: () => sendEmail(
        emailAddress: _emailAddress,
        emailSubject: _emailSubject,
        emailBody: emailBody,
        includeRuntimeDiagnostics: includeRuntimeDiagnostics,
        additionalDiagnostics: additionalDiagnostics,
        diagnosticsHeading: _diagnosticsHeading,
      ),
    );
  }
}

final class _FeedbackEmailLaunchButton extends StatefulWidget {
  const _FeedbackEmailLaunchButton({
    required this.label,
    required this.launchEmail,
  });

  final String label;
  final Future<bool> Function() launchEmail;

  @override
  State<_FeedbackEmailLaunchButton> createState() =>
      _FeedbackEmailLaunchButtonState();
}

final class _FeedbackEmailLaunchButtonState
    extends State<_FeedbackEmailLaunchButton> {
  bool _launchInProgress = false;

  Future<void> _launchEmail() async {
    if (_launchInProgress) {
      return;
    }
    setState(() => _launchInProgress = true);
    try {
      await widget.launchEmail();
    } finally {
      if (mounted) {
        setState(() => _launchInProgress = false);
      }
    }
  }

  @override
  Widget build(final BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _launchInProgress ? null : _launchEmail,
      label: Text(widget.label),
      icon: const Icon(Icons.email),
    );
  }
}
