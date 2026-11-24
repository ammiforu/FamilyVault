import 'package:flutter_test/flutter_test.dart';
import 'package:family_vault/main.dart';

void main() {
  testWidgets('FamilyVault basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FamilyVaultApp(isConfigured: false));
    expect(find.text('Create Master PIN'), findsOneWidget);
  });
}
