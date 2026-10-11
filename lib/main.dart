import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/workout_repository.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const StrengthTrackerApp());
}

class StrengthTrackerApp extends StatelessWidget {
  const StrengthTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WorkoutRepository()..load(),
      child: MaterialApp(
        title: 'Strength Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE63946),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF121212),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
