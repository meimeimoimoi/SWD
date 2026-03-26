import 'package:dio/dio.dart';

import '../constants/api_config.dart';
import 'auth_api_service.dart';
import 'storage_service.dart';

class CartItemModel {
  CartItemModel({
    required this.cartItemId,
    required this.solutionId,
    this.solutionName,
    this.solutionType,
    this.description,
    this.imageUrl,
    this.addedAt,
    this.quantity = 1,
  });

  final int cartItemId;
  final int solutionId;
  final String? solutionName;
  final String? solutionType;
  final String? description;
  final String? imageUrl;
  final String? addedAt;
  final int quantity;

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      cartItemId: (json['cartItemId'] as num?)?.toInt() ?? 0,
      solutionId: (json['solutionId'] as num?)?.toInt() ?? 0,
      solutionName: json['solutionName'] as String?,
      solutionType: json['solutionType'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      addedAt: json['addedAt']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class CartApiService {
  CartApiService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: AuthApiService.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          );

  final Dio _dio;

  String _bearer(String token) {
    final t = token.trim();
    return t.toLowerCase().startsWith('bearer ') ? t : 'Bearer $t';
  }

  Future<List<CartItemModel>> getCartItems() async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty)
        headers['Authorization'] = _bearer(token);
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.cart,
        options: Options(headers: headers),
      );
      final data = response.data;
      if (data == null || data['success'] != true) return [];
      final raw = data['data'];
      if (raw == null) return [];
      final items = (raw['items'] is List)
          ? raw['items'] as List
          : (raw is List ? raw : []);
      return items
          .map(
            (e) => CartItemModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> removeCartItem(int cartItemId) async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty)
        headers['Authorization'] = _bearer(token);
      final resp = await _dio.delete<Map<String, dynamic>>(
        ApiPaths.cartRemoveItem(cartItemId),
        options: Options(headers: headers),
      );
      final data = resp.data;
      return data != null && data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
