import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/themes/primarytheme.dart';
import 'package:gifthub/themes/colors.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({Key? key}) : super(key: key);

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        height: 70,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Главная',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.favorite),
            icon: Icon(Icons.favorite_border_outlined),
            label: 'Желания',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.shopping_cart),
            icon: Icon(Icons.shopping_cart_outlined),
            label: 'Корзина',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.account_circle),
            icon: Icon(Icons.account_circle_outlined),
            label: 'Аккаунт',
          ),
        ],
      ),
      body: currentPageIndex == 0
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              child: Text(
                "GIFTHUB",
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: buttonGreen,
                  fontSize: 72,
                  fontFamily: "plantype",
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.only(top: 25, right: 24, left: 24),
              child: TextFormField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  prefixIconColor: Colors.white,
                ),
              ),
            ),

          ],
        ),
      )
          : currentPageIndex == 1
          ? Center(
        child: Text("Желания"),
      )
          : currentPageIndex == 2
          ? Center(
        child: Text("Корзина"),
      )
          : Center(
        child: Text("Аккаунт"),
      ),
    );
  }
}
