import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keda/l10n/app_localizations.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('Localization loads correctly for Spanish (default)', (tester) async {
    late AppLocalizations localizations;

    await tester.pumpWidget(
      createTestApp(
        home: Builder(
          builder: (context) {
            localizations = AppLocalizations.of(context)!;
            return Container();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(localizations.settings, 'Configuración');
    expect(localizations.language, 'Idioma');
  });

  testWidgets('Localization loads correctly for English', (tester) async {
    late AppLocalizations localizations;

    await tester.pumpWidget(
      createTestApp(
        locale: const Locale('en'),
        home: Builder(
          builder: (context) {
            localizations = AppLocalizations.of(context)!;
            return Container();
          },
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(localizations.settings, 'Settings');
    expect(localizations.language, 'Language');
  });
}
