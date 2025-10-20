import 'package:flutter_test/flutter_test.dart';

// The import below should point to the main App class
import 'package:thort_jivit/app.dart';

void main() {
  testWidgets('Welcome screen loads and displays title', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    // FIX: Change 'MyApp' to 'App'
    await tester.pumpWidget(const App());

    // Verify that the 'THOTH JIVIT' title is displayed.
    expect(find.text('THOTH JIVIT'), findsOneWidget);

    // Verify the main call to action buttons are present
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
