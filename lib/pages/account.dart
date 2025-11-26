import 'package:flutter/material.dart';
import 'package:gifthub/pages/profilepage.dart';
import 'package:gifthub/pages/orders.dart';
import 'package:gifthub/pages/notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gifthub/themes/colors.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final supabase = Supabase.instance.client;
  bool hasUnreadNotifications = false;

  @override
  void initState() {
    super.initState();
    checkUnreadNotifications();
  }

  Future<void> checkUnreadNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('Notification')
          .select('NotificationID')
          .eq('RecipientID', userId)
          .eq('IsRead', false)
          .limit(1);

      setState(() {
        hasUnreadNotifications = response.length > 0;
      });

    } catch (error) {
      print('Error checking notifications: $error');
    }
  }

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
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.account_circle_outlined),
              title: Text('Профиль'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profile',
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_cart_outlined),
              title: Text('Заказы'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/orders',
                );
              },
            ),

            ListTile(
              leading: Stack(
                children: [
                  Icon(
                    Icons.notifications_none,

                  ),
                  if (hasUnreadNotifications)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: wishListIcon,
                          shape: BoxShape.circle,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 8,
                          minHeight: 8,
                        ),
                      ),
                    ),
                ],
              ),
              title: Text('Уведомления'),
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  '/notifications',
                );
                checkUnreadNotifications();
              },
            ),
            ListTile(
              leading: Icon(Icons.credit_card_outlined),
              title: Text('Промокоды'),
              onTap: () {
                Navigator.pushNamed(
                  context,
                    '/promoCodes',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}