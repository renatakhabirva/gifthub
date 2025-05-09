import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/product_card.dart';
import 'package:gifthub/pages/checkout.dart';
import 'package:gifthub/pages/video_widget.dart';
import 'package:gifthub/pages/quantity_product.dart';

import 'messages.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Map<String, dynamic>> availableItems = [];
  List<Map<String, dynamic>> unavailableItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    subscribeToCartUpdates();
  }

  @override
  void dispose() {
    supabase.channel('cart-updates').unsubscribe();
    super.dispose();
  }

  void subscribeToCartUpdates() {
    supabase
        .channel('cart-updates')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'Cart',
      callback: (payload, [ref]) {
        fetchCartItems();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'Cart',
      callback: (payload, [ref]) {
        fetchCartItems();
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'Cart',
      callback: (payload, [ref]) {
        fetchCartItems();
      },
    )
        .subscribe();
  }

  Future<void> fetchCartItems() async {
    try {
      setState(() => isLoading = true);
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final response = await supabase
          .from('Cart')
          .select('''
          CartItemID,
          Quantity,
          Product(ProductID, ProductName, ProductCost, ProductQuantity, ProductPhoto(Photo)),
          Parametr(ParametrID, ParametrName)
        ''')
          .eq('ClientID', userId)
          .order('AddedAt', ascending: true);

      // Очистка списков
      availableItems.clear();
      unavailableItems.clear();

      for (var item in response) {
        final product = item['Product'];
        final parametr = item['Parametr'];
        final quantity = item['Quantity'] as int? ?? 1;

        bool isInStock = false;

        if (product != null) {
          final productId = product['ProductID'];

          if (parametr != null) {
            final parametrId = parametr['ParametrID'];
            final available =
            await fetchParametrQuantity(productId, parametrId);
            isInStock = available != null && available >= quantity;
          } else {
            final productQuantity = product['ProductQuantity'] as int? ?? 0;
            isInStock = productQuantity >= quantity;
          }
        }

        if (isInStock) {
          availableItems.add(item);
        } else {
          unavailableItems.add(item);
        }
      }

      setState(() {
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка при загрузке корзины: $error'),
      ));
    }
  }

  double calculateTotalCost() {
    double total = 0;
    for (var item in availableItems) {
      final product = item['Product'];
      final quantity = item['Quantity'] ?? 1;
      final cost = product['ProductCost'] ?? 0.0;
      total += cost * quantity;
    }
    return total;
  }

  Widget buildCheckoutButton(BuildContext context) {
    final totalCost = calculateTotalCost();
    return Container(
      padding: const EdgeInsets.only(bottom: 90, right: 20, left: 20),
      decoration: BoxDecoration(color: backgroundBeige),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Итого: ${totalCost.toStringAsFixed(2)} ₽',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await fetchCartItems();

              if (availableItems.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      totalCost: calculateTotalCost(),
                      cartItems: availableItems,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Некоторые товары больше не доступны.'),

                ));
              }
            },
            child: Text('Оформить заказ'),
          ),
        ],
      ),
    );
  }

  Future<void> updateCartItemQuantity(int cartItemId, int newQuantity) async {
    try {
      await supabase
          .from('Cart')
          .update({'Quantity': newQuantity})
          .eq('CartItemID', cartItemId);
    } catch (error) {
      String errorMessage = MessagesRu.error;

      if (error.toString().contains('количество')) {
        errorMessage = MessagesRu.quantityProductIsNull;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }

  }

  Future<void> removeCartItem(int cartItemId) async {
    try {
      await supabase.from('Cart').delete().eq('CartItemID', cartItemId);
      fetchCartItems();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ошибка удаления товара: $error'),
      ));
    }
  }

  bool isVideoUrl(String url) {
    final extensions = ['.mp4', '.mov', '.avi', '.wmv'];
    return extensions.any((ext) => url.toLowerCase().endsWith(ext));
  }

  Widget buildMediaWidget(String url) {
    if (isVideoUrl(url)) {
      return VideoPlayerScreen(videoUrl: url, isMuted: true);
    }
    return Image.network(
      url,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          Icon(Icons.image_not_supported),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.shopping_cart_outlined),
          onPressed: null,
        ),
        title: Text('Корзина'),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : [...availableItems, ...unavailableItems].isEmpty
          ? Center(child: Text('Корзина пуста'))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount:
              availableItems.length + unavailableItems.length,
              itemBuilder: (context, index) {
                if (index < availableItems.length) {
                  return buildCartItem(
                      availableItems[index], true);
                } else {
                  return buildCartItem(
                      unavailableItems[
                      index - availableItems.length],
                      false);
                }
              },
            ),
          ),
          buildCheckoutButton(context),
        ],
      ),
    );
  }

  Widget buildCartItem(Map<String, dynamic> item, bool isAvailable) {
    final product = item['Product'];
    final parametr = item['Parametr'];
    final imageUrl = product['ProductPhoto']?.isNotEmpty ?? false
        ? product['ProductPhoto'][0]['Photo']
        : 'https://picsum.photos/200/300';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        height: 150,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              width: 150,
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(10)),
                child: buildMediaWidget(imageUrl),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      overflow: TextOverflow.ellipsis,
                      product['ProductName'] ?? 'Без названия',
                      style: TextStyle(
                        fontSize: 16,
                        color: darkGreen,
                        fontFamily: "segoeui",
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (parametr != null)
                      Text(
                        parametr['ParametrName'],
                        style: TextStyle(fontSize: 14, color: lightGrey),
                      ),
                    if (!isAvailable)
                      Text(
                        'Нет в наличии',
                        style: TextStyle(
                            color: wishListIcon, fontWeight: FontWeight.bold),
                      ),
                    SizedBox(height: 4),
                    Text(
                      '${product['ProductCost']} ₽',
                      style:
                      TextStyle(fontWeight: FontWeight.bold, color: darkGreen),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isAvailable
                  ? [
                Flexible(
                  child: IconButton(
                    icon: Icon(Icons.remove, color: wishListIcon),
                    onPressed: () {
                      final currentQuantity = item['Quantity'];
                      if (currentQuantity > 1) {
                        updateCartItemQuantity(
                            item['CartItemID'], currentQuantity - 1);
                      }
                    },
                  ),
                ),
                Flexible(
                  child: Text('${item['Quantity']}'),
                ),
                Flexible(
                  child: IconButton(
                    icon: Icon(Icons.add, color: darkGreen),
                    onPressed: () {
                      final currentQuantity = item['Quantity'];
                      updateCartItemQuantity(
                          item['CartItemID'], currentQuantity + 1);
                    },
                  ),
                ),
                Flexible(
                  child: IconButton(
                    icon: Icon(Icons.delete, color: wishListIcon),
                    onPressed: () => removeCartItem(item['CartItemID']),
                  ),
                ),
              ]
                  : [
                Flexible(
                  child: IconButton(
                    icon: Icon(Icons.delete, color: wishListIcon),
                    onPressed: () => removeCartItem(item['CartItemID']),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}