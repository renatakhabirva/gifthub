
import 'package:supabase_flutter/supabase_flutter.dart';


  final _client = Supabase.instance.client;

  Future<int?> fetchAvailableQuantity(int productId, [String? parametrName]) async {
    final supabase = Supabase.instance.client;
    try {
      if (parametrName != null) {

        final parametrId = await fetchParametrId(parametrName);
        if (parametrId == null) return null;


        final response = await supabase
            .from('ParametrProduct')
            .select('Quantity')
            .eq('ProductID', productId)
            .eq('ParametrID', parametrId)
            .single();

        return response['Quantity'] as int?;
      } else {

        final response = await supabase
            .from('Product')
            .select('ProductQuantity')
            .eq('ProductID', productId)
            .single();

        return response['ProductQuantity'] as int?;
      }
    } catch (e) {
      print('Ошибка получения количества: $e');
      return null;
    }
  }
  Future<int?> fetchParametrId(String parametrName) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('Parametr')
          .select('ParametrID')
          .eq('ParametrName', parametrName)
          .single();
      return response['ParametrID'];
    } catch (error) {
      print('Ошибка при получении ParametrID: $error');
      return null;
    }
  }
  Future<int?> fetchParametrQuantity(int productId, int parametrId) async {
    final supabase = Supabase.instance.client;
    try {
      final response = await supabase
          .from('ParametrProduct')
          .select('Quantity')
          .eq('ProductID', productId)
          .eq('ParametrID', parametrId)
          .single();

      return response['Quantity'] as int?;
    } catch (e) {
      print('Ошибка получения количества: $e');
      return null;
    }
  }


