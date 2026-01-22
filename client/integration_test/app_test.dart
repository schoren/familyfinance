import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:keda/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-end test', () {
    testWidgets('verify app startup and initial state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify that we are at least not on a crash screen
      // We look for common elements that should be present on splash or login
      // Adjust the expectations based on your actual initial screen
      expect(find.byType(app.MyApp), findsOneWidget);
      
      // Give it some time to settle
      await Future.delayed(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    });
  });
}
