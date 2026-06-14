import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/deck/presentation/providers/deck_notifier.dart';
import 'features/deck/screens/main_deck_screen.dart';
import 'shared/data/hive_persistence_service.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  // Ensure Flutter engine bindings are initialized prior to loading database
  WidgetsFlutterBinding.ensureInitialized();

  // Enforce vertical device orientation only for premium deck swipe feel
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Set system overlay styling for dark mode integration
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0F0F10),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize Local Hive Persistence Service
  final persistenceService = HivePersistenceService();
  await persistenceService.init();

  runApp(
    ProviderScope(
      overrides: [
        // Override persistence provider with fully initialized service
        persistenceServiceProvider.overrideWithValue(persistenceService),
      ],
      child: const OrangeDeckApp(),
    ),
  );
}

class OrangeDeckApp extends ConsumerWidget {
  const OrangeDeckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeNotifierProvider);

    return MaterialApp(
      title: 'OrangeDeck',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(themeState.accentColor),
      darkTheme: buildDarkTheme(themeState.accentColor),
      themeMode: themeState.themeMode,
      home: const MainDeckScreen(),
    );
  }
}
