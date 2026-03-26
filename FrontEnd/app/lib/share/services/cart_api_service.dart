import 'dart:convert';

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
    this.shopeeUrl,
    this.addedAt,
    this.quantity = 1,
  });

  final int cartItemId;
  final int solutionId;
  final String? solutionName;
  final String? solutionType;
  final String? description;
  final String? imageUrl;
  final String? shopeeUrl;
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
      shopeeUrl:
          (json['shopeeUrl'] ?? json['shoppeUrl'] ?? json['shopee_url'])
              as String?,
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

  Future<int?> _extractUserIdFromToken(String? token) async {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;
      var payload = parts[1];
      // Add padding if necessary
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = String.fromCharCodes(base64Url.decode(payload));
      final map = Map<String, dynamic>.from(jsonDecode(decoded) as Map);
      // Try common claim keys
      final candidates = [map['nameid'], map['sub'], map['nameidentifier']];
      for (final c in candidates) {
        if (c != null) {
          final s = c.toString();
          final n = int.tryParse(s);
          if (n != null) return n;
        }
      }
      // Try to find any key containing 'nameidentifier' or 'nameid' or 'sub'
      for (final entry in map.entries) {
        final k = entry.key.toLowerCase();
        if (k.contains('nameidentifier') ||
            k.contains('nameid') ||
            k == 'sub') {
          final v = entry.value?.toString();
          if (v != null) {
            final n = int.tryParse(v);
            if (n != null) return n;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<bool> addToCart({required int solutionId, int quantity = 1}) async {
    try {
      final token = await StorageService.getAccessToken();
      final headers = <String, dynamic>{};
      if (token != null && token.isNotEmpty)
        headers['Authorization'] = _bearer(token);

      final userId = await _extractUserIdFromToken(token);
      final body = <String, dynamic>{
        'userId': userId ?? 0,
        'solutionId': solutionId,
        'quantity': quantity > 0 ? quantity : 1,
      };

      final resp = await _dio.post<Map<String, dynamic>>(
        ApiPaths.cartAdd,
        data: body,
        options: Options(headers: headers),
      );
      final data = resp.data;
      return data != null && data['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
