import 'dart:io';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gifthub/pages/account.dart';
import 'package:gifthub/pages/auth.dart';
import 'package:gifthub/pages/auth_notif.dart';
import 'package:gifthub/pages/cart.dart';
import 'package:gifthub/pages/checkout.dart';
import 'package:gifthub/pages/notifications.dart';
import 'package:gifthub/pages/orders.dart';
import 'package:gifthub/pages/product_card.dart';
import 'package:gifthub/pages/profilepage.dart';
import 'package:gifthub/pages/promo_codes_page.dart';
import 'package:gifthub/pages/registration.dart';
import 'package:gifthub/pages/wishlist.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:gifthub/themes/primarytheme.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/mainpages.dart';
import "package:url_strategy/url_strategy.dart";

import 'env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setPathUrlStrategy();
  await initializeDateFormatting();
  try {

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
    print('Supabase initialized successfully');
  } catch (e) {
    print('Error during initialization: $e');
  }


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
      initialRoute: '/',
      onGenerateRoute: (settings) {
        if (settings.name?.startsWith('/product/') ?? false) {
          final segments = settings.name!.split('/');
          if (segments.length == 3) {
            final productId = int.tryParse(segments[2]);
            if (productId != null) {
              return MaterialPageRoute(
                settings: settings,
                builder: (context) => FutureBuilder<Map<String, dynamic>>(
                  future: _fetchProductData(productId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: Text('Товар не найден')),
                      );
                    }

                    return ProductDetailScreen(product: snapshot.data!);
                  },
                ),
              );
            }
          }
        }
        return null;
      },
      routes: {
        '/': (context) => kIsWeb ? NavigationExample() : SplashScreen(),
        '/main': (context) => NavigationExample(),
        '/authorization': (context) => Authorization(),
        '/registration': (context) => RegistrationForm(),
        '/profile': (context) => ProfilePage(),
        '/orders': (context) => OrderPage(),
        '/notifications': (context) => NotificationsPage(),
        '/promoCodes': (context) => PromoCodesPage(),
        '/product/:id': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            return ProductDetailScreen(product: arguments);
          }
          return const Scaffold(body: Center(child: Text('Товар не найден')));
        },
        '/checkout': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments;
          if (arguments is Map<String, dynamic>) {
            final totalCost = arguments['totalCost'] as double?;
            final cartItems = arguments['cartItems'] as List<Map<String, dynamic>>?;

            if (totalCost != null && cartItems != null) {
              return CheckoutScreen(totalCost: totalCost, cartItems: cartItems);
            }
          }

          return const Scaffold(body: Center(child: Text('Ошибка данных')));
        },
      },

    );
  }
  Future<Map<String, dynamic>> _fetchProductData(int productId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('Product')
        .select('''
        ProductID,
        ProductName,
        ProductCost,
        ProductPhoto(Photo)
      ''')
        .eq('ProductID', productId)
        .single();

    return response;
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

    await Future.delayed(const Duration(seconds: 3));

    Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
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