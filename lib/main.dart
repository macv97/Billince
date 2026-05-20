import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'screens/main_menu_screen.dart';
import 'screens/welcome_screen.dart';
import 'data/settings_provider.dart';
import 'data/local_database.dart';
import 'data/app_data.dart';
import 'data/supabase_repository.dart';

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

  // Merge with Cloud if logged in
  if (SupabaseRepository.isAuthenticated) {
    try {
      final cloudExpenses = await SupabaseRepository.fetchUserExpenses();
      for (var cloudExp in cloudExpenses) {
        if (!AppData.expenses.any((localExp) => localExp.id == cloudExp.id)) {
          AppData.expenses.add(cloudExp);
          await LocalDatabase.insertExpense(cloudExp); // Save to local for offline
        }
      }
      // Sort expenses by date DESC after merge
      AppData.expenses.sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      debugPrint("Failed to sync initial expenses: $e");
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsProvider(),
      child: const BillinceApp(),
    ),
  );
}

class BillinceApp extends StatefulWidget {
  const BillinceApp({super.key});

  @override
  State<BillinceApp> createState() => _BillinceAppState();
}

class _BillinceAppState extends State<BillinceApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Check initial link if app was cold-started
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("Failed to get initial deep link: $e");
    }

    // Listen for link events while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("Deep Link Received: $uri");
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'join') {
      final groupId = uri.pathSegments.last;
      
      // Delay to ensure the context and navigator are fully built
      Future.delayed(const Duration(milliseconds: 500), () async {
        final context = _navigatorKey.currentContext;
        if (context == null) return;
        
        if (!SupabaseRepository.isAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Debes iniciar sesión para unirte a un grupo compartido.'),
            backgroundColor: Colors.orange,
          ));
          return;
        }

        try {
          await SupabaseRepository.joinSharedGroup(groupId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('¡Te has unido al grupo correctamente!'),
              backgroundColor: Color(0xFF10B981),
            ));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Error al unirse al grupo: $e'),
              backgroundColor: Colors.redAccent,
            ));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

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
      navigatorKey: _navigatorKey,
      title: 'Billince',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.interfaceColor,
          primary: settings.interfaceColor,
          secondary: const Color(0xFF2563EB),
          tertiary: const Color(0xFF0D9488),
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
          secondary: const Color(0xFF2563EB),
          tertiary: const Color(0xFF0D9488),
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
