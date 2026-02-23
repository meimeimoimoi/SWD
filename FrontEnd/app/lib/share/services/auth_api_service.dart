import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// HTTP client for authentication API calls.
/// Contracts directly match backend DTOs:
/// - RegisterRequestDTO: {username, password}
/// - LoginRequestDTO: {usernameOrEmail, password}
class AuthApiService {
  static const String baseUrl = 'http://10.0.2.2:5299';
  static const String registerEndpoint = '/api/Auth/register';
  static const String loginEndpoint = '/api/Auth/login';
  static const Duration timeout = Duration(seconds: 30);

  /// Register new user with username and password.
  /// Request: {username: "<username>", password: "<password>"}
  /// Response (200/201): {message: "Registration successful."}
  static Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    try {
      final url = Uri.parse('$baseUrl$registerEndpoint');
      final payload = {'username': username.trim(), 'password': password};

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
}
