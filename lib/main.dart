import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final settingsBox = await Hive.openBox('settings');
  final seenOnboarding = settingsBox.get('seenOnboarding', defaultValue: false);

  runApp(MyApp(seenOnboarding: seenOnboarding));
}

class MyApp extends StatefulWidget {
  final bool seenOnboarding;
  const MyApp({super.key, required this.seenOnboarding});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _showHomeScreen;

  @override
  void initState() {
    super.initState();
    _showHomeScreen = widget.seenOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, app, _) {
          ThemeData buildTheme(Brightness brightness) {
            final colorScheme = ColorScheme.fromSeed(
              seedColor: app.accent,
              brightness: brightness,
            );
            final textTheme = GoogleFonts.manropeTextTheme(ThemeData(brightness: brightness).textTheme);

            // Custom dark theme colors for a more professional look
            const darkScaffoldBackgroundColor = Color(0xFF1C1C1E);
            const darkCardColor = Color(0xFF2C2C2E);

            return ThemeData(
              // Use the generated color scheme but override specific colors for dark mode
              colorScheme: brightness == Brightness.dark
                  ? colorScheme.copyWith(
                      surface: darkCardColor, // This will be used by Cards
                      background: darkScaffoldBackgroundColor,
                    )
                  : colorScheme,
              scaffoldBackgroundColor: brightness == Brightness.dark ? darkScaffoldBackgroundColor : null,
              textTheme: textTheme,
              useMaterial3: true,
              filledButtonTheme: FilledButtonThemeData(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              cardTheme: CardThemeData(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(brightness == Brightness.dark ? 0.3 : 0.5),
                border: const OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              segmentedButtonTheme: SegmentedButtonThemeData(
                style: ButtonStyle(
                  shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            );
          }

          return MaterialApp(
            title: 'Habits & Todos',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: app.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: _showHomeScreen
                ? const HomeScreen()
                : OnboardingScreen(onDone: () async {
                    final settingsBox = Hive.box('settings');
                    await settingsBox.put('seenOnboarding', true);
                    setState(() {
                      _showHomeScreen = true;
                    });
                  }),
          );
        },
      ),
    );
  }
}

