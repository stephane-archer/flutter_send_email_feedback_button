import 'package:flutter/material.dart';
import 'package:send_email_feedback_button/send_email_feedback_button.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SendEmailFeedbackButton(
          emailAddress: "support@example.com",
          emailSubject: "App Feedback & Test",
        ),
      ),
    );
  }
}
