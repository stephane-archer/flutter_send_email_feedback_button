# SendEmailFeedbackButton

A reusable Flutter button and utility API that opens the user's default email
client with a pre-filled feedback message.

![Demo](https://raw.githubusercontent.com/stephane-archer/flutter_send_email_feedback_button/main/assets/screenshots/demo.png)

## Features

- Pre-fills the recipient, subject, and optional email body.
- Optionally includes application and operating-system diagnostics.
- Accepts application-specific diagnostic fields.

## Requirements

- Dart 3.6 or later.
- Flutter 3.27 or later.
- This package uses `package_info_plus` 8.3.1 through 8.x.
- Android builds require API 19 or later, compile SDK 34, Java 17, Android
  Gradle Plugin 8.3 or later, and Gradle 8.4 or later.
- Apple builds require iOS 12 or later and macOS 10.14 or later.

## Using the widget

```dart
import 'package:flutter/material.dart';
import 'package:send_email_feedback_button/send_email_feedback_button.dart';

class FeedbackButton extends StatelessWidget {
  const FeedbackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SendEmailFeedbackButton(
      emailAddress: 'support@example.com',
      emailSubject: 'App feedback',
      emailBody: 'Please describe the issue:',
      includeRuntimeDiagnostics: true,
      additionalDiagnostics: {
        'Most recent error': 'FileSystemException',
        'Publication mode': 'exclusive copy',
      },
      diagnosticsHeading: 'Diagnostics:',
    );
  }
}
```

When runtime diagnostics are enabled, the package includes the application
name, package identifier, version/build number, operating-system name, and OS
version. Values passed through `additionalDiagnostics` are controlled entirely
by the calling application.

If runtime metadata cannot be collected, the email launch is still attempted
and the message reports that runtime diagnostics were unavailable.

Collecting runtime metadata can delay the launch by up to two seconds. The
widget is disabled while a launch is in progress so repeated taps do not open
multiple email composers. On web, a diagnostics-enabled launch uses the current
browsing context because browsers may block a new window after an asynchronous
metadata lookup.

## Using the utility function

For a custom button, call `sendEmail` directly:

```dart
final launchRequested = await sendEmail(
  emailAddress: 'support@example.com',
  emailSubject: 'App feedback',
  emailBody: 'Please describe the issue:',
  includeRuntimeDiagnostics: true,
  additionalDiagnostics: {
    'Current screen': 'Export',
  },
);

if (!launchRequested) {
  // Show an alternative contact method.
}
```
