import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final double totalCost;
  final List<Map<String, dynamic>> cartItems;

  const CheckoutScreen({
    Key? key,
    required this.totalCost,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  String? selectedRecipientName;
  String? selectedRecipientId;

  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;
  bool isOrderLoading = false;
  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    try {
      setState(() => isLoading = true);
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await supabase
          .from('ClientPublicView')
          .select('ClientID, ClientName, ClientSurName, ClientDisplayname')
          .ilike('ClientDisplayname', '%$query%')
          .neq('ClientID', currentUserId)
          .limit(20);

      setState(() {
        searchResults = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при поиске пользователей: $error')),
      );
    }
  }

  void selectRecipient(Map<String, dynamic> recipient) {
    setState(() {
      selectedRecipientId = recipient['ClientID'];
      selectedRecipientName = recipient['ClientDisplayname'] ??
          '${recipient['ClientName']} ${recipient['ClientSurName']}';
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Оформление заказа')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            SizedBox(height: 10),
            Text('Товары:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.cartItems.length,
                itemBuilder: (context, index) {
                  final item = widget.cartItems[index];
                  final product = item['Product'];
                  final imageUrl = product['ProductPhoto']?.isNotEmpty ?? false
                      ? product['ProductPhoto'][0]['Photo']
                      : 'https://picsum.photos/200/300';

                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item['Quantity']}x',
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),

                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            Divider(height: 30),

            Text('Поиск получателя:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(
              onChanged: (query) => searchUsers(query),
              decoration: InputDecoration(
                hintText: 'Введите никнейм',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 10),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (searchResults.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final recipient = searchResults[index];
                    final displayName = recipient['ClientDisplayname'] ?? 'Без имени';
                    final fullName = '${recipient['ClientName']} ${recipient['ClientSurName']}';

                    return ListTile(
                      title: Text(displayName),
                      subtitle: Text(fullName),
                      onTap: () => selectRecipient(recipient),
                      tileColor: selectedRecipientId == recipient['ClientID']
                          ? Colors.green.withOpacity(0.1)
                          : null,
                    );
                  },
                ),
              ),

            if (selectedRecipientName != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Выбранный получатель: $selectedRecipientName',

                ),
              ),

            Spacer(),


            ElevatedButton(
              onPressed: () {
                if (selectedRecipientId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Выберите получателя')),
                  );
                  return;
                }
              },
              child: Text(
                'Оплатить ${widget.totalCost.toStringAsFixed(2)} ₽',
                style: TextStyle(fontSize: 16),
              ),
            ),

          ],
        ),
      ),
    );
  }}