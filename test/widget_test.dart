<<<<<<< HEAD
import 'package:flutter_test/flutter_test.dart';

// The import below should point to the main App class
import 'package:thort_jivit/app.dart'; 

void main() {
  testWidgets('Welcome screen loads and displays title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // FIX: Change 'MyApp' to 'App'
    await tester.pumpWidget(const App()); 

    // Verify that the 'THOT JIVIT' title is displayed.
    expect(find.text('THOT JIVIT'), findsWidgets); 
    
    // Verify the main call to action buttons are present
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
=======
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_record/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
>>>>>>> b29264d7940f696e3a6b020c08bc81a4f0aacb73
  });
}
