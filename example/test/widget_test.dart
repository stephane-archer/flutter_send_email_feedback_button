import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('shows the feedback email button', (final tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Send feedback'), findsOneWidget);
    expect(find.byIcon(Icons.email), findsOneWidget);
  });
}
