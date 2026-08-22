import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlarmXvApp());
}

class AlarmXvApp extends StatelessWidget {
  const AlarmXvApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF8B80F9);

    return MaterialApp(
      title: 'AlarmXV',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seedColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF111318),
        cardTheme: const CardThemeData(margin: EdgeInsets.zero, elevation: 0),
      ),
      home: const HomeScreen(),
    );
  }
}
