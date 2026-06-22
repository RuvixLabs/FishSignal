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
      primary: FishColors.sea,
      onPrimary: Colors.white,
      secondary: FishColors.amber,
      onSecondary: FishColors.ink,
      surface: FishColors.inkSoft,
      onSurface: FishColors.mist,
    );
    final base = ThemeData.from(colorScheme: scheme, useMaterial3: true);
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
