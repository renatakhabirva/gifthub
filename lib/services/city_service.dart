import 'package:supabase_flutter/supabase_flutter.dart';

class CityService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> fetchUserCity() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        // Если пользователь не авторизован, возвращаем город с ID 1
        final response = await supabase
            .from('City')
            .select('*')
            .eq('CityID', 1)
            .single();

        return {
          'userCityId': response['CityID'] as int?,
          'userCityName': response['City'] as String?,
        };
      }

      final response = await supabase
          .from('Client')
          .select('ClientCity, City(City)')
          .eq('ClientID', user.id)
          .single();

      return {
        'userCityId': response['ClientCity'] as int?,
        'userCityName': response['City']?['City'] as String?,
      };
    } on PostgrestException catch (error) {
      print('Postgrest ошибка при загрузке города пользователя: ${error.message}');
      return null;
    } catch (error) {
      print('Неизвестная ошибка при загрузке города пользователя: $error');
      return null;
    }
  }
}