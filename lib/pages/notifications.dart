import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import "package:intl/intl.dart";
import 'package:gifthub/themes/colors.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Пользователь не авторизован');
      }


      final response = await supabase
          .from('Notification')
          .select('''
            *
          ''')
          .eq('RecipientID', userId)
          .order('CreatedAt', ascending: false);

      print('Notifications response: $response'); // Для отладки

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });

    } catch (error) {
      print('Error loading notifications: $error'); // Для отладки
      setState(() {
        isLoading = false;
        errorMessage = 'Ошибка при загрузке уведомлений: $error';
      });
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await supabase
          .from('Notification')
          .update({'IsRead': true})
          .eq('NotificationID', notificationId);

      await loadNotifications(); // Перезагружаем список
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при обновлении уведомления: $error')),
      );
    }
  }

  String formatDateTime(String? dateTime) {
    if (dateTime == null) return '';
    try {
      final dt = DateTime.parse(dateTime).toLocal();
      return DateFormat('dd.MM.yyyy HH:mm').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Уведомления'),
        backgroundColor: backgroundBeige,
        foregroundColor: darkGreen,


      ),
      body: RefreshIndicator(
        onRefresh: loadNotifications,
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: darkGreen))
            : errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(errorMessage!),
              ElevatedButton(
                onPressed: loadNotifications,
                child: Text('Повторить'),
              ),
            ],
          ),
        )
            : notifications.isEmpty
            ? Center(
          child: Text(
            'Нет уведомлений',
            style: TextStyle(
              color: darkGreen,
              fontSize: 16,
            ),
          ),
        )
            : ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            final sender = notification['Sender'];
            final senderName = sender?['ClientDisplayname'] ??
                '${sender?['ClientName']} ${sender?['ClientSurName']}' ??
                'Неизвестный отправитель';

            return Card(
              margin: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              elevation: notification['IsRead'] ? 1 : 3,
              child: ListTile(
                title: Text(
                  notification['Message'] ?? '',
                  style: TextStyle(
                    fontWeight: notification['IsRead'] ?
                    FontWeight.normal :
                    FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      formatDateTime(notification['CreatedAt']),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                trailing: !notification['IsRead']
                    ? Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: buttonGreenOpacity,
                    shape: BoxShape.circle,
                  ),
                )
                    : null,
                onTap: () {
                  if (!notification['IsRead']) {
                    markAsRead(notification['NotificationID']);
                  }
                },
                tileColor: notification['IsRead']
                    ? null
                    : Colors.grey.withOpacity(0.1),
              ),
            );
          },
        ),
      ),
    );
  }
}