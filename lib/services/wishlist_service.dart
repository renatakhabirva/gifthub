import 'package:flutter/material.dart';
import 'package:gifthub/services/messages.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// находится ли товар в вишлисте
Future<bool> checkInWishlist(int productId) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  // наличие товара в таблице WishList
  final response = await Supabase.instance.client
      .from('WishList')
      .select()
      .eq('Client', user.id)
      .eq('Product', productId)
      .maybeSingle();

  return response != null;
}

// добавление/удаление товара из вишлиста
Future<void> toggleWishlistService({
  required BuildContext context,
  required int productId,
  required ValueNotifier<bool> isInWishlist,
}) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        (SnackBar(content: Text(MessagesRu.noLogin))));
    return;
  }

  try {
    if (isInWishlist.value) {
      // удаление товара из вишлиста
      await Supabase.instance.client
          .from('WishList')
          .delete()
          .eq('Client', user.id)
          .eq('Product', productId);

      isInWishlist.value = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MessagesRu.deleteFromWishList)),
      );
    } else {
      // добавление товара в вишлист
      await Supabase.instance.client.from('WishList').insert({
        'Client': user.id,
        'Product': productId,
      });

      isInWishlist.value = true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(MessagesRu.addToWishList)),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при изменении вишлиста: $error')),
    );
  }
}