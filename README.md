# SendEmailFeedbackButton

A simple Flutter button widget that opens the user's default email client with a pre-filled recipient and subject for sending feedback.

![Demo](https://raw.githubusercontent.com/stephane-archer/flutter_send_email_feedback_button/main/assets/screenshots/demo.png)

## Features

- Opens the default email app on tap.
- Pre-fills recipient email address and subject line.
- Uses `url_launcher` under the hood.
- Lightweight and easy to use.

## Usage

``` Dart
import 'package:flutter/material.dart';
import 'package:send_email_feedback_button/send_email_feedback_button.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SendEmailFeedbackButton(
            emailAddress: "support@example.com",
            emailSubject: "App Feedback",
          ),
        ),
      ),
    );
  }
}
```