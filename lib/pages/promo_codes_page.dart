import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PromoCodesPage extends StatefulWidget {
  const PromoCodesPage({Key? key}) : super(key: key);

  @override
  State<PromoCodesPage> createState() => _PromoCodesPageState();
}

class _PromoCodesPageState extends State<PromoCodesPage> {

  List<Map<String, dynamic>> _clientPromoCodes = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPromoCodes();
  }

  Future<void> _fetchPromoCodes() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Пользователь не авторизован';
        });
        return;
      }

      final response = await Supabase.instance.client
          .from('ClientPromoCode')
          .select('PromoCode:PromoCodeID(*), IsUsed')
          .eq('ClientID', user.id);

      final List data = response as List;

      setState(() {
        _clientPromoCodes = data
            .where((e) => (e['PromoCode'] as Map<String, dynamic>).isNotEmpty)
            .map((e) => e as Map<String, dynamic>)
            .toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Ошибка при загрузке: $e';
        _loading = false;
      });
    }
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Промокод "$code" скопирован')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои промокоды')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : _clientPromoCodes.isEmpty
          ? const Center(child: Text('У вас нет промокодов'))
          : ListView.builder(
        itemCount: _clientPromoCodes.length,
        itemBuilder: (context, index) {
          final item = _clientPromoCodes[index];
          final promo = item['PromoCode'] as Map<String, dynamic>;
          final isUsed = item['IsUsed'] == true;
          final code = promo['Code'] ?? '';
          final promoColor = isUsed ? Colors.grey : Colors.black;
          final promoBgColor = isUsed ? Colors.grey[100] : Colors.white;
          return Card(
            color: promoBgColor,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                Icons.card_giftcard,
                color: isUsed ? Colors.grey : Colors.green,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      code,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: promoColor,
                        decoration: isUsed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  if (!isUsed && code.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Скопировать промокод',
                      onPressed: () => _copyToClipboard(code),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    promo['Description'] ?? promo['PromoCodeDescription'] ?? '',
                    style: TextStyle(
                      color: isUsed ? Colors.grey : null,
                    ),
                  ),
                  if (isUsed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Использован',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (promo['Discount'] != null)
                    Text(
                      '${promo['Discount']}%',
                      style: TextStyle(
                        color: isUsed ? Colors.grey : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (promo['ValidUntil'] != null)
                    Text(
                      'до ${_formatDate(promo['ValidUntil'])}',
                      style: const TextStyle(fontSize: 12),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return date.toString();
    }
  }
}