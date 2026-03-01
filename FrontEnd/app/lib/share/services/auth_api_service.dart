import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'storage_service.dart';

/// HTTP client for authentication API calls.
/// Contracts directly match backend DTOs:
/// - RegisterRequestDTO: {username, email, password}
/// - LoginRequestDTO: {usernameOrEmail, password}
class AuthApiService {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final configured = _envBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured;
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5299';
    }
    return 'http://localhost:5299';
  }

  static const String registerEndpoint = '/api/Auth/register';
  static const String loginEndpoint = '/api/Auth/login';
  // TODO: If backend uses /auth/* instead of /api/Auth/*, update these paths.
  static const String profileEndpoint = '/api/User/profile';
  static const String refreshTokenEndpoint = '/api/Auth/refresh-token';
  static const Duration timeout = Duration(seconds: 30);

  static bool _isRefreshing = false;
  static Future<String?>? _refreshFuture;
  static void Function()? onSessionExpired;

  /// Register new user with username, email and password.
  /// Request: {username: "<username>", email: "<email>", password: "<password>"}
  /// Response (200/201): {message: "Registration successful."}
  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$registerEndpoint');
      final payload = {
        'username': username.trim(),
        'email': email.trim(),
        'password': password,
      };

      final client = HttpClient();
      client.connectionTimeout = timeout;

      try {
        final request = await client.postUrl(url).timeout(timeout);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Accept', 'application/json');

        request.write(jsonEncode(payload));

        final response = await request.close().timeout(timeout);
        final responseBody = await response.transform(utf8.decoder).join();

        late Map<String, dynamic> data;
        try {
          data = jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (e) {
          data = {'message': responseBody};
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': data['message'] ?? 'Registration successful.',
          };
        } else if (response.statusCode == 400) {
          return {
            'success': false,
            'message': data['message'] ?? 'Validation error',
          };
        } else if (response.statusCode == 409) {
          return {
            'success': false,
            'message': data['message'] ?? 'Username already exists',
          };
        } else {
          return {
            'success': false,
            'message': 'Server error (${response.statusCode})',
          };
        }
      } finally {
        client.close();
      }
    } on SocketException catch (e) {
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timeout (30s)'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Login with username or email and password.
  /// Request: {usernameOrEmail: "<username/email>", password: "<password>"}
  /// Response (200): {token: "...", ...} or custom data
  static Future<Map<String, dynamic>> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$loginEndpoint');
      final payload = {
        'usernameOrEmail': usernameOrEmail.trim(),
        'password': password,
      };

      final client = HttpClient();
      client.connectionTimeout = timeout;

      try {
        final request = await client.postUrl(url).timeout(timeout);
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Accept', 'application/json');

        request.write(jsonEncode(payload));

        final response = await request.close().timeout(timeout);
        final responseBody = await response.transform(utf8.decoder).join();

        late Map<String, dynamic> data;
        try {
          data = jsonDecode(responseBody) as Map<String, dynamic>;
        } catch (e) {
          data = {'message': responseBody};
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'data': data,
            'message': data['message'] ?? 'Login successful',
          };
        } else if (response.statusCode == 401) {
          return {
            'success': false,
            'message': data['message'] ?? 'Invalid credentials',
          };
        } else if (response.statusCode == 400) {
          return {
            'success': false,
            'message': data['message'] ?? 'Validation error',
          };
        } else {
          return {
            'success': false,
            'message': 'Server error (${response.statusCode})',
          };
        }
      } finally {
        client.close();
      }
    } on SocketException catch (e) {
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timeout (30s)'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  /// Get current user profile (authorized).
  static Future<Map<String, dynamic>> getProfile() async {
    return _authorizedJsonRequest(method: 'GET', endpoint: profileEndpoint);
  }

  /// Update current user profile (authorized).
  static Future<Map<String, dynamic>> updateProfile(
    Map<String, dynamic> payload,
  ) async {
    return _authorizedJsonRequest(
      method: 'PUT',
      endpoint: profileEndpoint,
      payload: payload,
    );
  }

  /// Refresh token.
  static Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    if (refreshToken.trim().isEmpty) {
      return {'success': false, 'message': 'Refresh token is missing'};
    }

    final response = await _sendJsonRequest(
      method: 'POST',
      endpoint: refreshTokenEndpoint,
      payload: {'refreshToken': refreshToken.trim()},
      accessToken: null,
    );

    if (response['success'] != true) {
      return response;
    }

    final data = _asMap(response['data']);
    final tokenData = _asMap(data['token']);
    final source = tokenData.isNotEmpty ? tokenData : data;

    final newAccessToken = source['accessToken']?.toString();
    if (newAccessToken == null || newAccessToken.isEmpty) {
      return {
        'success': false,
        'message': 'Refresh succeeded but access token is missing',
      };
    }

    final oldUsername = await StorageService.getUsername();
    final oldRole = await StorageService.getRole();
    final oldRefreshToken = await StorageService.getRefreshToken();

    await StorageService.saveAuthToken(
      accessToken: newAccessToken,
      refreshToken: source['refreshToken']?.toString() ?? oldRefreshToken,
      username: source['username']?.toString() ?? oldUsername,
      role: source['role']?.toString() ?? oldRole,
      expiresIn: source['expiresIn']?.toString(),
    );

    return {
      'success': true,
      'message': response['message'] ?? 'Token refreshed',
      'data': {'accessToken': newAccessToken},
    };
  }

  static Future<Map<String, dynamic>> _authorizedJsonRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? payload,
    bool retryOnUnauthorized = true,
  }) async {
    final accessToken = await StorageService.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      return {
        'success': false,
        'statusCode': 401,
        'message': 'Unauthorized. Please login again.',
      };
    }

    final response = await _sendJsonRequest(
      method: method,
      endpoint: endpoint,
      payload: payload,
      accessToken: accessToken,
    );

    final statusCode = response['statusCode'] as int?;
    if (statusCode == 401 && retryOnUnauthorized) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _authorizedJsonRequest(
          method: method,
          endpoint: endpoint,
          payload: payload,
          retryOnUnauthorized: false,
        );
      }

      await StorageService.clearAuth();
      onSessionExpired?.call();
      return {
        'success': false,
        'statusCode': 401,
        'message': 'Session expired. Please login again.',
      };
    }

    return response;
  }

  static Future<bool> _refreshAccessToken() async {
    if (_isRefreshing && _refreshFuture != null) {
      final token = await _refreshFuture;
      return token != null && token.isNotEmpty;
    }

    _isRefreshing = true;
    _refreshFuture = _performRefresh();

    try {
      final token = await _refreshFuture;
      return token != null && token.isNotEmpty;
    } finally {
      _isRefreshing = false;
      _refreshFuture = null;
    }
  }

  static Future<String?> _performRefresh() async {
    final currentRefreshToken = await StorageService.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return null;
    }

    final refreshResponse = await refreshToken(currentRefreshToken);
    if (refreshResponse['success'] != true) {
      return null;
    }

    final data = _asMap(refreshResponse['data']);
    return data['accessToken']?.toString();
  }

  static Future<Map<String, dynamic>> _sendJsonRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? payload,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (accessToken != null && accessToken.trim().isNotEmpty) {
        headers['Authorization'] = _formatBearerToken(accessToken);
      }

      late http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: jsonEncode(payload ?? {}))
              .timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(payload ?? {}))
              .timeout(timeout);
          break;
        default:
          return {
            'success': false,
            'message': 'Unsupported HTTP method: $method',
          };
      }

      final data = _tryParseJsonMap(response.body);
      final message = _extractMessage(
        data,
        fallback: response.statusCode >= 200 && response.statusCode < 300
            ? ''
            : 'Request failed (${response.statusCode})',
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'statusCode': response.statusCode,
          'message': message.isEmpty ? null : message,
          'data': data,
        };
      }

      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': message.isEmpty ? null : message,
        'data': data,
      };
    } on SocketException catch (e) {
      return {'success': false, 'message': 'Network error: ${e.message}'};
    } on TimeoutException {
      return {'success': false, 'message': 'Request timeout (30s)'};
    } catch (e) {
      return {'success': false, 'message': 'Error: ${e.toString()}'};
    }
  }

  static String _formatBearerToken(String token) {
    final trimmed = token.trim();
    if (trimmed.toLowerCase().startsWith('bearer ')) {
      return trimmed;
    }
    return 'Bearer $trimmed';
  }

  static Map<String, dynamic> _tryParseJsonMap(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {'message': body};
  }

  static String _extractMessage(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final directMessage = data['message']?.toString();
    if (directMessage != null && directMessage.isNotEmpty) {
      return directMessage;
    }

    final errors = _asMap(data['errors']);
    if (errors.isNotEmpty) {
      final firstEntry = errors.entries.first;
      final value = firstEntry.value;
      if (value is List && value.isNotEmpty) {
        final first = value.first?.toString();
        if (first != null && first.isNotEmpty) {
          return first;
        }
      }
      final errorText = value?.toString();
      if (errorText != null && errorText.isNotEmpty) {
        return errorText;
      }
    }

    return fallback;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return <String, dynamic>{};
  }
}
