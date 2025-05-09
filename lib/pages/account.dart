import 'package:flutter/material.dart';
import 'package:gifthub/pages/profilepage.dart';
import 'package:gifthub/pages/orders.dart';
import 'package:gifthub/pages/notifications.dart';

class AccountPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.account_circle),
          onPressed: null,
        ),
        title: const Text('Аккаунт'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            ListTile(
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Профиль'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag_outlined),
              title: Text('Заказы'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OrderPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications_none),
              title: Text('Уведомления'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => NotifPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
