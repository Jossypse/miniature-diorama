// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/app_theme.dart';
import 'providers/diorama_provider.dart';
import 'providers/music_provider.dart';
import 'providers/quiz_provider.dart';
import 'ui/screens/connect_screen.dart';
import 'ui/screens/main_layout.dart';
import 'ui/screens/intro_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;

  runApp(DioramaApp(hasSeenIntro: hasSeenIntro));
}

class DioramaApp extends StatelessWidget {
  final bool hasSeenIntro;

  const DioramaApp({super.key, required this.hasSeenIntro});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DioramaProvider()),
        ChangeNotifierProxyProvider<DioramaProvider, MusicProvider>(
          create: (_) => MusicProvider(),
          update: (_, device, music) => music!..bind(device),
        ),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
      ],
      child: MaterialApp(
        title: 'Daet Capitol Diorama',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: hasSeenIntro ? '/' : '/intro',
        routes: {
          '/intro': (context) => const IntroScreen(),
          '/': (context) => const ConnectScreen(),
          '/home': (context) => const MainLayout(),
        },
      ),
    );
  }
}
