import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SendEmailFeedbackButton extends StatelessWidget {
  final String _emailAddress;
  final String _emailSubject;

  const SendEmailFeedbackButton({
    super.key,
    required String emailAddress,
    required String emailSubject,
  })  : _emailSubject = emailSubject,
        _emailAddress = emailAddress;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        Uri url = Uri.parse("mailto:$_emailAddress?subject=$_emailSubject");
        await launchUrl(url);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.email),
          SizedBox(width: 2),
          Text("Send feedback"),
        ],
      ),
    );
  }
}
