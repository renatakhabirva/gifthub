import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:gifthub/pages/product_card.dart';
import 'package:gifthub/pages/checkout.dart';
import 'package:gifthub/services/video_widget.dart';
import 'package:gifthub/pages/quantity_product.dart';

import '../services/city_availability_service.dart';
import '../services/city_service.dart';
import '../services/messages.dart';

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

  // Промокод
  final TextEditingController _promoController = TextEditingController();
  String? _promoError;
  bool _promoApplied = false;
  int _discount = 0;
  String? _appliedPromoCode;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
    subscribeToCartUpdates();
  }

  @override
  void dispose() {
    supabase.channel('cart-updates').unsubscribe();
    _promoController.dispose();
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
        print("Доступные товары: ${availableItems.length}");
        print("Недоступные товары: ${unavailableItems.length}");
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'Cart',
      callback: (payload, [ref]) {
        fetchCartItems();
        print("Доступные товары: ${availableItems.length}");
        print("Недоступные товары: ${unavailableItems.length}");
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'Cart',
      callback: (payload, [ref]) {
        fetchCartItems();
        print("Доступные товары: ${availableItems.length}");
        print("Недоступные товары: ${unavailableItems.length}");
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

      final cityService = CityService();
      final userCity = await cityService.fetchUserCity();
      final userCityId = userCity?['userCityId'];

      if (userCityId == null) {
        setState(() => isLoading = false);
        return;
      }

      final cityAvailabilityService = CityAvailabilityService();

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

      availableItems.clear();
      unavailableItems.clear();

      for (var item in response) {
        final product = item['Product'];
        final parametr = item['Parametr'];
        final quantity = item['Quantity'] as int? ?? 1;

        bool isInStock = false;
        bool isAvailableInCity = false;
        int itemCost = product['ProductCost'] ?? 0;

        if (product != null) {
          final productId = product['ProductID'];

          isAvailableInCity = await cityAvailabilityService.isProductAvailableInCity(
            productId,
            userCityId,
          );

          if (isAvailableInCity) {
            if (parametr != null) {
              final parametrId = parametr['ParametrID'];
              final parametrData = await fetchParametrData(productId, parametrId);
              isInStock = parametrData != null && (parametrData['quantity'] ?? 0) >= quantity;
              if (parametrData != null && parametrData['cost'] != null) {
                itemCost = parametrData['cost'];
              }
            } else {
              final productQuantity = product['ProductQuantity'] as int? ?? 0;
              isInStock = productQuantity >= quantity;
            }
          }
        }

        final updatedItem = Map<String, dynamic>.from(item);
        updatedItem['effectiveCost'] = itemCost;

        if (isInStock && isAvailableInCity) {
          availableItems.add(updatedItem);
        } else {
          updatedItem['notAvailableReason'] = !isAvailableInCity ? 'city' : 'stock';
          unavailableItems.add(updatedItem);
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

  Future<Map<String, dynamic>?> fetchParametrData(int productId, int parametrId) async {
    try {
      final response = await supabase
          .from('ParametrProduct')
          .select('Quantity, Cost')
          .eq('ProductID', productId)
          .eq('ParametrID', parametrId)
          .maybeSingle();

      if (response != null) {
        return {
          'quantity': response['Quantity'] as int?,
          'cost': response['Cost'],
        };
      }
      return null;
    } catch (e) {
      print('Ошибка получения данных параметра: $e');
      return null;
    }
  }

  double calculateTotalCost() {
    double total = 0;
    for (var item in availableItems) {
      final quantity = item['Quantity'] ?? 1;
      final cost = item['effectiveCost'] ?? item['Product']['ProductCost'] ?? 0.0;
      total += cost * quantity;
    }
    if (_promoApplied && _discount > 0) {
      total = total * (1 - _discount / 100);
    }
    return total;
  }

  Widget buildPromoCodeField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _promoController,
                  decoration: InputDecoration(
                    labelText: 'Промокод',
                    errorText: _promoError,
                    border: OutlineInputBorder(),
                  ),
                  enabled: !_promoApplied,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _promoApplied ? null : _applyPromo,
                child: const Text('Применить'),
              ),
            ],
          ),
          if (_promoApplied)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Промокод "$_appliedPromoCode" применён! Скидка $_discount%',
                      style: TextStyle(color: buttonGreen),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _promoApplied = false;
                        _discount = 0;
                        _appliedPromoCode = null;
                        _promoController.clear();
                        _promoError = null;
                      });
                    },
                    child: Text('Удалить', style: TextStyle(color: wishListIcon),),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _applyPromo() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _promoError = 'Введите промокод';
      });
      return;
    }

    try {
      final promo = await supabase
          .from('PromoCode')
          .select('PromoCodeID, Discount, ValidUntil')
          .eq('Code', code)
          .maybeSingle();

      if (promo == null) {
        setState(() {
          _promoError = 'Промокод не найден';
          _promoApplied = false;
          _discount = 0;
          _appliedPromoCode = null;
        });
        return;
      }

      final validUntil = promo['ValidUntil'];
      if (validUntil != null && DateTime.now().isAfter(DateTime.parse(validUntil))) {
        setState(() {
          _promoError = 'Срок действия промокода истёк';
          _promoApplied = false;
          _discount = 0;
          _appliedPromoCode = null;
        });
        return;
      }

      final userId = supabase.auth.currentUser?.id;
      final promoCodeId = promo['PromoCodeID'] as int;
      final clientPromo = await supabase
          .from('ClientPromoCode')
          .select('IsUsed')
          .eq('ClientID', userId!)
          .eq('PromoCodeID', promoCodeId)
          .maybeSingle();

      if (clientPromo != null && clientPromo['IsUsed'] == true) {
        setState(() {
          _promoError = 'Вы уже использовали этот промокод';
          _promoApplied = false;
          _discount = 0;
          _appliedPromoCode = null;
        });
        return;
      }

      setState(() {
        _promoApplied = true;
        _discount = (promo['Discount'] as num?)?.toInt() ?? 0;
        _promoError = null;
        _appliedPromoCode = code;
      });
    } catch (e) {
      setState(() {
        _promoError = 'Ошибка проверки: $e';
        _promoApplied = false;
        _discount = 0;
        _appliedPromoCode = null;
      });
    }
  }

  Widget buildCheckoutButton(BuildContext context) {
    final totalCost = calculateTotalCost();
    final hasUnavailableInCity = unavailableItems.any((item) =>
    item['notAvailableReason'] == 'city');

    return Container(
      padding: const EdgeInsets.only(bottom: 90, right: 20, left: 20),
      decoration: BoxDecoration(color: backgroundBeige),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Итого: ${totalCost.toStringAsFixed(2)} ₽',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkGreen,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await fetchCartItems();

              if (hasUnavailableInCity) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Заказ невозможен. В корзине есть товары, недоступные в вашем городе.'),
                ));
                return;
              }

              if (availableItems.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      totalCost: calculateTotalCost(),
                      cartItems: availableItems,
                      promoCode: _appliedPromoCode,
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
      String productName = '';

      try {
        final cartItem = await supabase
            .from('Cart')
            .select('Product(ProductName)')
            .eq('CartItemID', cartItemId)
            .single();

        if (cartItem != null && cartItem['Product'] != null) {
          productName = cartItem['Product']['ProductName'] ?? '';
        }
      } catch (e) {}

      if (error.toString().contains('количество')) {
        errorMessage = productName.isNotEmpty
            ? 'Товара "$productName" больше нет'
            : MessagesRu.quantityProductIsNull;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  Future<void> removeCartItem(int cartItemId) async {
    try {
      await supabase.from('Cart').delete().eq('CartItemID', cartItemId);

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
          ? RefreshIndicator(
        onRefresh: fetchCartItems,
        child: ListView(
          children: [
            Container(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Center(
                child: Text(
                  'Корзина пуста',
                  style: TextStyle(
                    color: darkGreen,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: fetchCartItems,
        color: darkGreen,
        backgroundColor: backgroundBeige,
        child: Stack(
          children: [
            Column(
              children: [
                buildPromoCodeField(),
                Expanded(
                  child: ListView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    itemCount: availableItems.length + unavailableItems.length,
                    itemBuilder: (context, index) {
                      if (index < availableItems.length) {
                        return buildCartItem(availableItems[index], true);
                      } else {
                        return buildCartItem(
                          unavailableItems[index - availableItems.length],
                          false,
                        );
                      }
                    },
                  ),
                ),
                buildCheckoutButton(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildCartItem(Map<String, dynamic> item, bool isAvailable) {
    final product = item['Product'];
    final parametr = item['Parametr'];
    final imageUrl = product['ProductPhoto']?.isNotEmpty ?? false
        ? product['ProductPhoto'][0]['Photo']
        : 'https://picsum.photos/200/300';

    final effectiveCost = item['effectiveCost'] ?? product['ProductCost'];
    final notAvailableReason = item['notAvailableReason'];

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product/${product['ProductID']}',
          arguments: product,
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
              padding: EdgeInsets.all(5),
              width: 150,
              height: 150,
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
                        notAvailableReason == 'city'
                            ? 'Нет в вашем городе'
                            : 'Нет в наличии',
                        style: TextStyle(
                          color: wishListIcon,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    SizedBox(height: 4),
                    Text(
                      '$effectiveCost ₽',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
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
                          item['CartItemID'],
                          currentQuantity - 1,
                        );
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
                        item['CartItemID'],
                        currentQuantity + 1,
                      );
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
            ),
          ],
        ),
      ),
    );
  }
}