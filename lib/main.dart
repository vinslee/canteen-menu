import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  runApp(const CanteenMenuApp());
}

class CanteenMenuApp extends StatelessWidget {
  const CanteenMenuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '胡老三菜谱',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CAF50),
          brightness: Brightness.light,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 18),
          bodyMedium: TextStyle(fontSize: 16),
          bodySmall: TextStyle(fontSize: 14),
          labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          labelMedium: TextStyle(fontSize: 14),
          labelSmall: TextStyle(fontSize: 12),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          labelStyle: const TextStyle(fontSize: 20),
          hintStyle: const TextStyle(fontSize: 18),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
