import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gifthub/themes/primarytheme.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/mainpages.dart';

void main() async {
  // Загрузка .env перед запуском приложения
  await dotenv.load();
  runApp(GiftHub());
}

class GiftHub extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: primTheme(),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Функция для инициализации данных приложения
  Future<void> _initializeApp() async {

    final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final String supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';

    // Инициализация Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    // Задержка перед переходом на основной экран
    await Future.delayed(Duration(seconds: 3)); // Задержка 3 секунды

    // Переход на основной экран
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NavigationExample()), // Переход на NavigationExample
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige, // Цвет фона для SplashScreen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Надпись
            Text(
              'gifthub',
              style: TextStyle(
                fontSize: 72,
                fontFamily: 'plantype',
                color: buttonGreen,
              ),
            ),
            SizedBox(height: 20),
            // Полоса загрузки
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(darkGreen), // Цвет полосы загрузки
            ),
          ],
        ),
      ),
    );
  }
}
