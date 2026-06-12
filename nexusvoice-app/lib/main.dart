import 'package:flutter/material.dart';
import 'ui/mobile/main_mobile.dart';
import 'ui/desktop/main_desktop.dart';
import 'core/nv_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Trigger initialization of bindings and native handle
  NvController.instance;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexusVoice',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E17),
        primaryColor: const Color(0xFF00FF87),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF87),
          secondary: Color(0xFF00C9FF),
          surface: Color(0xFF0F1322),
          background: Color(0xFF0B0E17),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF141A31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const AdaptiveLayoutGate(),
    );
  }
}

class AdaptiveLayoutGate extends StatelessWidget {
  const AdaptiveLayoutGate({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return const MainMobile();
        } else {
          return const MainDesktop();
        }
      },
    );
  }
}
