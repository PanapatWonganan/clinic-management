import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  String? _token;
  Map<String, dynamic>? _userData;

  // Get current token
  String? get token => _token;
  
  // Get current user data
  Map<String, dynamic>? get userData => _userData;
  
  // Check if user is logged in
  bool get isLoggedIn {
    debugPrint('AuthService.isLoggedIn: $_token != null = ${_token != null}');
    return _token != null;
  }

  // Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      final data = ApiService.parseResponse(response);
      
      if (data['token'] != null) {
        _token = data['token'];
        _userData = data['user'];
        
        // Save to local storage
        await _saveTokenToStorage(_token!);
        await _saveUserToStorage(_userData!);
        
        return {
          'success': true,
          'message': 'เข้าสู่ระบบสำเร็จ',
          'user': _userData,
        };
      } else {
        return {
          'success': false,
          'message': 'ข้อมูลเข้าสู่ระบบไม่ถูกต้อง',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาด: $e',
      };
    }
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await ApiService.post('/auth/register', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
      });

      final data = ApiService.parseResponse(response);
      
      if (data['token'] != null) {
        _token = data['token'];
        _userData = data['user'];
        
        await _saveTokenToStorage(_token!);
        await _saveUserToStorage(_userData!);
        
        return {
          'success': true,
          'message': 'สมัครสมาชิกสำเร็จ',
          'user': _userData,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'เกิดข้อผิดพลาดในการสมัครสมาชิก',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาด: $e',
      };
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      if (_token != null) {
        // Call logout API
        await ApiService.post('/auth/logout', {});
      }
    } catch (e) {
      debugPrint('Logout API error: $e');
    } finally {
      // Clear local data
      _token = null;
      _userData = null;
      await _clearStorage();
    }
  }

  // Load token from storage
  Future<void> loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      
      final userString = prefs.getString(_userKey);
      if (userString != null) {
        _userData = json.decode(userString);
      }
    } catch (e) {
      debugPrint('Error loading token: $e');
    }
  }

  // Save token to storage
  Future<void> _saveTokenToStorage(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Save user data to storage
  Future<void> _saveUserToStorage(Map<String, dynamic> user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, json.encode(user));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Clear storage
  Future<void> _clearStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  // Get headers with authorization
  Map<String, String> getAuthHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    
    return headers;
  }
}