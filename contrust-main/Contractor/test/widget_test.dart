import 'package:flutter_test/flutter_test.dart';
import 'package:contractor/main.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(MyApp());

    // Verify "Welcome to the Login Screen!" text is found
    expect(find.text('Welcome to the Login Screen!'), findsOneWidget);
  });
}
