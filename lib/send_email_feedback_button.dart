import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sends an email using the device's default email client.
///
/// [emailAddress] is the recipient's email address.
/// [emailSubject] is the subject line of the email.
Future<void> sendEmail({
  required String emailAddress,
  required String emailSubject,
}) async {
  final url = Uri(
    scheme: 'mailto',
    path: emailAddress,
    query: 'subject=${Uri.encodeComponent(emailSubject)}',
  );
  await launchUrl(url);
}

class SendEmailFeedbackButton extends StatelessWidget {
  final String _emailAddress;
  final String _emailSubject;
  final String _label;

  const SendEmailFeedbackButton({
    super.key,
    required String emailAddress,
    required String emailSubject,
    String label = "Send feedback",
  }) : _label = label,
       _emailSubject = emailSubject,
       _emailAddress = emailAddress;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () async {
        await sendEmail(
          emailAddress: _emailAddress,
          emailSubject: _emailSubject,
        );
      },
      label: Text(_label),
      icon: Icon(Icons.email),
    );
  }
}
