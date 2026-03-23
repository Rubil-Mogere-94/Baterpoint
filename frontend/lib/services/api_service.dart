import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product.dart';
import '../constants.dart';

class ApiService {
  static const String _baseUrl = kBaseUrl;
  static const String _v1 = kApiV1;

  Future<List<Product>> getListings({String? category}) async {
    try {
      final queryParams = category != null ? '?category=$category' : '';
      final response = await http.get(Uri.parse('$_baseUrl$_v1/listings/$queryParams'));
      
      if (response.statusCode == 200) {
        List<dynamic> body = jsonDecode(response.body);
        return body.map((dynamic item) => Product.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load listings');
      }
    } catch (e) {
      print('Error fetching listings: $e');
      return [];
    }
  }

  Future<Product> getListing(int id) async {
    final response = await http.get(Uri.parse('$_baseUrl$_v1/listings/$id'));
    
    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load listing');
    }
  }
}
