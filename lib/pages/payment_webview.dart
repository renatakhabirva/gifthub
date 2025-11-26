import 'package:flutter/material.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  Future<void> updateOrderStatus() async {
    try {
      print('Updating order status for order: ${widget.orderId}');
      await supabase
          .from('Order')
          .update({'OrderStatus': 3})
          .eq('OrderID', widget.orderId);
      print('Order status updated successfully');

      // Очистка корзины после успешной оплаты
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        print('Clearing cart for user: $currentUserId');
        await supabase.from('Cart').delete().eq('ClientID', currentUserId);
        print('Cart cleared successfully');
      }
    } catch (error) {
      print('Error updating order status: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обновлении статуса заказа: $error')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.paymentUrl))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) async {
            if (url.contains('success')) {
              // Обновляем статус заказа при успешной оплате
              await updateOrderStatus();

              // Возвращаемся на предыдущий экран с результатом true
              Navigator.pop(context, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Оплата успешно завершена!'),

                ),
              );
            } else if (url.contains('fail')) {
              // Возвращаемся на предыдущий экран с результатом false
              Navigator.pop(context, false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Оплата не удалась.'),
                  backgroundColor: wishListIcon
                ),
              );
            }
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, false); // Payment was not successful
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Оплата'),

        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}