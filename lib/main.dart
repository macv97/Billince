import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/main_menu_screen.dart';
import 'screens/welcome_screen.dart';
import 'data/settings_provider.dart';
import 'data/local_database.dart';
import 'data/app_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Load personal data from local SQLite into AppData cache
  AppData.expenses
    ..clear()
    ..addAll(await LocalDatabase.getExpenses());
  AppData.shoppingLists
    ..clear()
    ..addAll(await LocalDatabase.getShoppingLists());

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const BillinceApp(),
    ),
  );
}

class BillinceApp extends StatelessWidget {
  const BillinceApp({super.key});

  ColorFilter _getColorFilter(ColorBlindnessMode mode) {
    switch (mode) {
      case ColorBlindnessMode.protanopia:
        return const ColorFilter.matrix([
          0.567, 0.433, 0.000, 0, 0,
          0.558, 0.442, 0.000, 0, 0,
          0.000, 0.242, 0.758, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessMode.deuteranopia:
        return const ColorFilter.matrix([
          0.625, 0.375, 0.000, 0, 0,
          0.700, 0.300, 0.000, 0, 0,
          0.000, 0.300, 0.700, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessMode.tritanopia:
        return const ColorFilter.matrix([
          0.950, 0.050, 0.000, 0, 0,
          0.000, 0.433, 0.567, 0, 0,
          0.000, 0.475, 0.525, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case ColorBlindnessMode.none:
      default:
        return const ColorFilter.matrix([
          1, 0, 0, 0, 0,
          0, 1, 0, 0, 0,
          0, 0, 1, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return MaterialApp(
      title: 'Billince',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.interfaceColor,
          primary: settings.interfaceColor,
          secondary: const Color(0xFF10B981),
          tertiary: const Color(0xFFF59E0B),
          surface: Colors.grey.shade50,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.interfaceColor,
          primary: settings.interfaceColor,
          secondary: const Color(0xFF10B981),
          tertiary: const Color(0xFFF59E0B),
          surface: const Color(0xFF1E293B),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      builder: (context, child) {
        Widget wrappedChild = MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScaleFactor),
          ),
          child: child!,
        );

        if (settings.colorBlindnessMode != ColorBlindnessMode.none) {
          wrappedChild = ColorFiltered(
            colorFilter: _getColorFilter(settings.colorBlindnessMode),
            child: wrappedChild,
          );
        }

        return wrappedChild;
      },
      home: Supabase.instance.client.auth.currentSession != null 
          ? const MainMenuScreen() 
          : const WelcomeScreen(),
    );
  }
}
