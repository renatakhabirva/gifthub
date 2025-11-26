import 'package:supabase_flutter/supabase_flutter.dart';

class CityAvailabilityService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<bool> isProductAvailableInCity(int productId, int userCityId) async {
    try {

      final productResponse = await supabase
          .from('Product')
          .select('ProductSeller')
          .eq('ProductID', productId)
          .single();

      final sellerId = productResponse['ProductSeller'] as int;


      final addressResponse = await supabase
          .from('SellerAddress')
          .select('AddressID, Address!inner(AddressCity)')
          .eq('SellerID', sellerId)
          .eq('Address.AddressCity', userCityId);

      return addressResponse.isNotEmpty;
    } catch (error) {
      print('Ошибка при проверке доступности товара в городе: $error');
      return false;
    }
  }
}