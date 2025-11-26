import 'package:supabase_flutter/supabase_flutter.dart';


  final _supabase = Supabase.instance.client;
  final _parametrCache = <String, int>{};

  Future<int?> fetchAvailableQuantity(int productId, [String? parametrName]) async {
    try {
      if (parametrName != null) {
        final parametrId = await fetchParametrId(parametrName);
        if (parametrId == null) return null;

        return await fetchParametrQuantity(productId, parametrId);
      } else {
        final response = await _supabase
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
    if (_parametrCache.containsKey(parametrName)) {
      return _parametrCache[parametrName];
    }

    try {
      final response = await _supabase
          .from('Parametr')
          .select('ParametrID')
          .eq('ParametrName', parametrName)
          .single();

      _parametrCache[parametrName] = response['ParametrID'];
      return response['ParametrID'];
    } catch (error) {
      print('Ошибка при получении ParametrID: $error');
      return null;
    }
  }

  Future<int?> fetchParametrQuantity(int productId, int parametrId) async {
    try {
      final response = await _supabase
          .from('ParametrProduct')
          .select('Quantity')
          .eq('ProductID', productId)
          .eq('ParametrID', parametrId)
          .single();

      return response['Quantity'] as int?;
    } catch (e) {
      print('Ошибка получения количества параметра: $e');
      return null;
    }
  }
