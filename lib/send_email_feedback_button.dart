import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        final url = Uri(
          scheme: 'mailto',
          path: _emailAddress,
          query: 'subject=${Uri.encodeComponent(_emailSubject)}',
        );
        await launchUrl(url);
      },
      label: Text(_label),
      icon: Icon(Icons.email),
    );
  }
}
