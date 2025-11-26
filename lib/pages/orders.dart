import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

final client = Supabase.instance.client;

class OrderPage extends StatefulWidget {
  @override
  _OrderPageState createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    setState(() => isLoading = true);
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await client
          .from('Order')
          .select('''
        *,
        OrderStatus ("StatusName"),
        OrderCity (City),
        OrderProduct (
            OrderProductQuantity,
            Product:Product!inner (
                ProductID,
                ProductName,
                ProductPhoto (Photo)
            )
        )
    ''')
          .eq('OrderSender', user.id)
          .order('OrderCreateDate', ascending: false);

      print('Данные заказов: $res');

      setState(() {
        orders = List<Map<String, dynamic>>.from(res as List);
        isLoading = false;
      });
    } catch (e) {
      print('Ошибка при получении заказов: $e');
      setState(() => isLoading = false);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Дата не указана';
    try {
      final date = DateTime.parse('${dateStr}Z').toLocal();
      return DateFormat('d MMMM y, HH:mm', 'ru').format(date.toLocal());
    } catch (e) {
      return 'Некорректная дата';
    }
  }

  String _formatPrice(num price) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: 2,
    );
    return formatter.format(price);
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'оплачен':
        return Colors.blue;
      case 'отменен':
        return Colors.orange;
      case 'в пути':
        return Colors.purple;
      case 'выполнен':
        return Colors.green;
      case 'получен':
        return Colors.red;
      case 'ожидает оплаты':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Widget buildOrderCard(Map<String, dynamic> order) {
    print('Обработка заказа: ${order['OrderID']}');

    final statusData = order['OrderStatus'];
    final statusName = statusData != null ? statusData['StatusName'] : 'Статус неизвестен';

    // Получаем данные о городе
    final cityData = order['OrderCity'];
    final cityName = cityData?['City'] ?? 'Город не указан';

    // Получаем улицу, дом и квартиру из заказа
    final String street = order['OrderStreet'] ?? 'не указан';
    final String house = order['OrderHouse'] ?? 'не указан';
    final String apartment = order['OrderApartment'] ?? 'не указано';

    final String fullAddress =
        '$cityName, ул. $street, д. $house, кв. $apartment';

    final List<dynamic> orderProducts = order['OrderProduct'] ?? [];
    final orderSum = order['OrderSum'] ?? 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '№ ${order['OrderID']}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusName).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getStatusColor(statusName),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusName,
                    style: TextStyle(
                      color: _getStatusColor(statusName),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Адрес доставки: $fullAddress',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Создан: ${_formatDate(order['OrderCreateDate'])}',

                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.event, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Плановая дата: ${_formatDate(order['OrderPlanDeliveryDate'])}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.monetization_on, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Сумма заказа: ${_formatPrice(orderSum)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (orderProducts.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: orderProducts.length,
                  itemBuilder: (context, index) {
                    final orderProduct = orderProducts[index];
                    print('Данные продукта: $orderProduct');
                    final product = orderProduct['Product'];
                    final photos = product?['ProductPhoto'] as List?;
                    final String photoUrl = photos?.isNotEmpty == true
                        ? photos?.first['Photo'] as String
                        : 'https://ivelkowygsgeutmxhdwd.supabase.co/storage/v1/object/public/PhotoProduct//no_product_photo.png ';

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: photoUrl,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 90,
                                height: 90,
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'x${orderProduct['OrderProductQuantity']}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else
              const Text(
                'Нет товаров в заказе',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заказы'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchOrders,
        child: orders.isEmpty
            ? Center(
          child: Text(
            'У вас пока нет заказов',
            style: TextStyle(color: Colors.grey[600]),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: orders.length,
          itemBuilder: (context, index) => buildOrderCard(orders[index]),
        ),
      ),
    );
  }
}