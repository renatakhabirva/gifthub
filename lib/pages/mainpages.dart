import 'package:flutter/material.dart';
import 'package:gifthub/pages/auth_notif.dart';
import 'package:gifthub/pages/product_card.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/productgrid.dart';
import 'package:gifthub/pages/auth.dart';
import 'package:gifthub/pages/registration.dart';
import 'package:gifthub/pages/wishlist.dart';
import 'package:gifthub/pages/cart.dart';
import 'package:gifthub/pages/account.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavigationExample extends StatefulWidget {
  const NavigationExample({super.key});

  @override
  State<NavigationExample> createState() => _NavigationExampleState();
}

class _NavigationExampleState extends State<NavigationExample> {
  int currentPageIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  Map<String, dynamic>? selectedProduct;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void navigateToAuth() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Authorization()),
    );
    setState(() {});
  }

  void navigateToRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegistrationForm()),
    );
  }

  void selectProduct(Map<String, dynamic> product) {
    setState(() {
      selectedProduct = product;
    });
  }

  void goBack() {
    setState(() {
      selectedProduct = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      bottomNavigationBar: NavigationBar(
        height: 70,
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
            selectedProduct = null;
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
      body: Stack(
        children: [
          IndexedStack(
            index: currentPageIndex,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 30),
                      child: Text(
                        "GIFTHUB",
                        style: TextStyle(
                          color: buttonGreen,
                          fontSize: 72,
                          fontFamily: "plantype",
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.only(top: 25, right: 10, left: 10),
                      child: TextFormField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          prefixIconColor: Colors.white,
                          hintText: 'Поиск товаров',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontFamily: 'segoe ui',
                          ),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 25, right: 10, left: 10),
                        child: ResponsiveGrid(
                          searchQuery: _searchController.text,
                          onProductTap: selectProduct,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              user != null ? WishlistGrid() : AuthNotif(onLoginPressed: navigateToAuth, onRegistrationPressed: navigateToRegistration),
              user != null ? CartPage() : AuthNotif(onLoginPressed: navigateToAuth, onRegistrationPressed: navigateToRegistration),
              user != null ? AccountPage() : AuthNotif(onLoginPressed: navigateToAuth, onRegistrationPressed: navigateToRegistration),
            ],
          ),
          selectedProduct != null
              ? ProductDetailScreenState(
            product: selectedProduct!,
            onBack: (bool _) => goBack(),
          )
              : Container(),
        ],
      ),
    );
  }
}
