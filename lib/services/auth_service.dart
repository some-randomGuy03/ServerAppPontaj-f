import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request.dart';
import '../models/login_response.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static String get baseUrl {
    return 'https://api.pontaj.binarysquad.club';
  }

  static const String loginEndpoint = '/admin/login';
  static const String _tokenKey = 'auth_token';
  static const String _usernameKey = 'auth_username';
  static const String _adminKey = 'auth_admin';

  Future<void> saveSession(String token, String username, int admin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usernameKey, username);
    await prefs.setInt(_adminKey, admin);
  }

  Future<Map<String, String>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final username = prefs.getString(_usernameKey);
    final admin = prefs.getInt(_adminKey);

    if (token != null && username != null) {
      return {
        'token': token,
        'username': username,
        'admin': (admin ?? 0).toString(),
      };
    }
    return null;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<LoginResponse> login(String username, String password) async {
    try {
      final request = LoginRequest(username: username, password: password);

      final uri = Uri.parse('$baseUrl$loginEndpoint');

      print('Making request to: $uri');

      final response = await http.post(
        uri,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': request.username,
          'password': request.password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          return LoginResponse.fromJson(responseData);
        } catch (e) {
          return LoginResponse(
            detail:
                'Failed to parse response: ${e.toString()}\nResponse: ${response.body}',
          );
        }
      } else {
        try {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          return LoginResponse.fromJson(responseData);
        } catch (e) {
          return LoginResponse(
            detail:
                'Request failed with status ${response.statusCode}: ${response.body}',
          );
        }
      }
    } catch (e, stackTrace) {
      print('Error occurred: $e');
      print('Stack trace: $stackTrace');

      String errorMessage = e.toString();

      // Check if it's a CORS error
      if (errorMessage.contains('Failed to fetch') ||
          errorMessage.contains('CORS') ||
          errorMessage.contains('NetworkError')) {
        if (kIsWeb) {
          errorMessage = '''Network/CORS Error: Cannot connect to API server.
          
If you are running in debug mode, make sure you are using the "Chrome (CORS Disabled)" launch configuration.
          
Original error: ${e.toString()}''';
        } else {
          errorMessage = '''Network Error: ${e.toString()}''';
        }
      }

      return LoginResponse(detail: errorMessage);
    }
  }
}
