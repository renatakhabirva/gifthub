import 'package:flutter/material.dart';
import 'package:gifthub/themes/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

class PaymentWindowsWebView extends StatefulWidget {
  final String paymentUrl;
  final String orderId;

  const PaymentWindowsWebView({
    Key? key,
    required this.paymentUrl,
    required this.orderId,
  }) : super(key: key);

  @override
  State<PaymentWindowsWebView> createState() => _PaymentWindowsWebViewState();
}

class _PaymentWindowsWebViewState extends State<PaymentWindowsWebView> {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isWebviewInitialized = false;

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
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      _controller.url.listen((url) {
        _textController.text = url;
        _handleUrlChange(url);
      });

      await _controller.loadUrl(widget.paymentUrl);

      setState(() {
        _isWebviewInitialized = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка инициализации WebView: $e')),
      );
    }
  }

  void _handleUrlChange(String url) async {
    if (url.contains('success')) {
      // Обновляем статус заказа при успешной оплате
      await updateOrderStatus();

      // Возвращаемся на предыдущий экран с результатом true
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Оплата успешно завершена!'),
          ),
        );
      }
    } else if (url.contains('fail')) {
      // Возвращаемся на предыдущий экран с результатом false
      if (mounted) {
        Navigator.pop(context, false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Оплата не удалась.'),
            backgroundColor: wishListIcon,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
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
        body: _isWebviewInitialized
            ? Stack(
          children: [
            Webview(
              _controller,
              permissionRequested: (url, permissionKind, isUserInitiated) =>
                  _onPermissionRequested(
                      url, permissionKind, isUserInitiated),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        )
            : const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    return WebviewPermissionDecision.allow;
  }
}