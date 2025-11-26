import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:gifthub/env_config.dart';

Future<String?> createYooKassaPayment(double totalCost, String orderId) async {
  final String shopId = yookassaShopId;
  final String secretKey = yookassaSecretKey;
  final String paymentUrl = 'https://api.yookassa.ru/v3/payments';

  try {
    final Map<String, dynamic> paymentData = {
      "amount": {
        "value": totalCost.toStringAsFixed(2),
        "currency": "RUB"
      },
      "confirmation": {
        "type": "redirect",
        "return_url": "https://your-return-url.com"
      },
      "capture": true,
      "description": "Оплата заказа #$orderId",
    };

    final response = await http.post(
      Uri.parse(paymentUrl),
      headers: {
        'Content-Type': 'application/json',
        'Idempotence-Key': DateTime.now().millisecondsSinceEpoch.toString(),
        'Authorization': 'Basic ${base64Encode(utf8.encode('$shopId:$secretKey'))}',
      },
      body: jsonEncode(paymentData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String? confirmationUrl = responseData['confirmation']?['confirmation_url'];
      return confirmationUrl;
    } else {
      print('Ошибка при создании платежа: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (error) {
    print('Ошибка при отправке запроса в ЮKassa: $error');
    return null;
  }
}