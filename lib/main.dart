import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gifthub/themes/primarytheme.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/mainpages.dart';
import 'package:window_size/window_size.dart';

void main() async {

  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();


  runApp(GiftHub());
}

class GiftHub extends StatelessWidget {
  const GiftHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru', 'RU'),
      debugShowCheckedModeBanner: false,
      theme: primTheme(),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {

    final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final String supabaseKey = dotenv.env['SUPABASE_KEY'] ?? '';


    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );

    await Future.delayed(Duration(seconds: 3));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => NavigationExample()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBeige,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              'gifthub',
              style: TextStyle(
                fontSize: 72,
                fontFamily: 'plantype',
                color: buttonGreen,
              ),
            ),
            SizedBox(height: 20),

            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(darkGreen),
            ),
          ],
        ),
      ),
    );
  }
}
