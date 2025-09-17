import "package:flutter_test/flutter_test.dart";

import "package:juststockadmin/app.dart";

void main() {
  testWidgets('renders sign-in form with OTP action', (tester) async {
    await tester.pumpWidget(const JustStockAdminApp());

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
