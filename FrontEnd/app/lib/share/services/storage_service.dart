import 'package:shared_preferences/shared_preferences.dart';

/// Service for storing and retrieving user authentication data
class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _usernameKey = 'username';
  static const String _roleKey = 'role';
  static const String _expiresInKey = 'expires_in';
  static const String _expiresAtKey = 'expires_at';

  /// Save authentication token and user info
  static Future<bool> saveAuthToken({
    required String accessToken,
    required String? refreshToken,
    required String? username,
    required String? role,
    required String? expiresIn,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, accessToken);
      if (refreshToken != null) {
        await prefs.setString(_refreshTokenKey, refreshToken);
      }
      if (username != null) {
        await prefs.setString(_usernameKey, username);
      }
      if (role != null) {
        await prefs.setString(_roleKey, role);
      }
      if (expiresIn != null) {
        await prefs.setString(_expiresInKey, expiresIn);
        final expiresInSeconds = int.tryParse(expiresIn);
        if (expiresInSeconds != null && expiresInSeconds > 0) {
          final expiresAt = DateTime.now().add(
            Duration(seconds: expiresInSeconds),
          );
          await prefs.setString(_expiresAtKey, expiresAt.toIso8601String());
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get stored access token
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored refresh token
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored username
  static Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored role
  static Future<String?> getRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleKey);
    } catch (e) {
      return null;
    }
  }

  /// Get stored token expiration timestamp in ISO 8601.
  static Future<String?> getExpiresAt() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_expiresAtKey);
    } catch (e) {
      return null;
    }
  }

  /// Returns true when token is missing, malformed, or already expired.
  static Future<bool> isTokenExpired() async {
    final token = await getAccessToken();
    if (token == null || token.isEmpty) {
      return true;
    }

    final expiresAtRaw = await getExpiresAt();
    if (expiresAtRaw == null || expiresAtRaw.isEmpty) {
      return false;
    }

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) {
      return false;
    }

    return DateTime.now().isAfter(expiresAt);
  }

  /// Clear all authentication data
  static Future<bool> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_roleKey);
      await prefs.remove(_expiresInKey);
      await prefs.remove(_expiresAtKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear all authentication data.
  static Future<bool> clearAuth() async {
    return clearAuthData();
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
