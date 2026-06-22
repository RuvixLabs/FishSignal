// FishSignal — pressure-aware, tide-aware fishing bite-window forecast.
//
// PROTOTYPE: local/mock only. No network, no Firebase, no RevenueCat, no store
// or provider integration. All forecast numbers are computed by the bite-score
// engine from fabricated fixtures and are labelled as such in-app.

import 'package:flutter/material.dart';

import 'app_state.dart';
import 'screens.dart';

void main() {
  runApp(const FishSignalApp());
}

class FishSignalApp extends StatefulWidget {
  const FishSignalApp({super.key});

  @override
  State<FishSignalApp> createState() => _FishSignalAppState();
}

class _FishSignalAppState extends State<FishSignalApp> {
  final AppState _state = AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: MaterialApp(
        title: 'FishSignal',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const _Root(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const scheme = ColorScheme.dark(
      primary: FishColors.seaBright,
      onPrimary: FishColors.ink,
      secondary: FishColors.amber,
      onSecondary: FishColors.ink,
      surface: FishColors.inkSoft,
      onSurface: FishColors.mist,
    );
    final base = ThemeData.from(colorScheme: scheme, useMaterial3: true);
    final stadium = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    );
    return base.copyWith(
      scaffoldBackgroundColor: FishColors.ink,
      textTheme: base.textTheme.apply(
        bodyColor: FishColors.mist,
        displayColor: FishColors.mist,
      ),
      dividerColor: FishColors.inkLine,
      cardTheme: const CardThemeData(
        color: FishColors.inkSoft,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: stadium,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: stadium,
          side: const BorderSide(color: FishColors.inkLine),
          foregroundColor: FishColors.mist,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: FishColors.inkSoft,
        contentTextStyle: TextStyle(color: FishColors.mist),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.onboardingComplete) {
      return const OnboardingScreen();
    }
    return const HomeShell();
  }
}
