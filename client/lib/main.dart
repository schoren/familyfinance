import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router.dart';
import 'providers/data_providers.dart';
import 'providers/settings_provider.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:keda/l10n/app_localizations.dart';

import 'dart:js' as js;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  await initializeDateFormatting(null, null);
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
  
  // Hide splash screen
  js.context.callMethod('hideSplash');
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Keda',
      locale: settings.locale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF22C55E),
          primary: const Color(0xFF22C55E),
          secondary: const Color(0xFFFACC15),
          error: const Color(0xFFEF4444),
          surface: const Color(0xFFF8FAFC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ).copyWith(
          displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
          displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
          headlineLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
          headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
          titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w600),
          titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          titleSmall: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
