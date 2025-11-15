import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import 'api_service.dart';
import 'auth_service.dart';

class ProfileService {
  static const String _profileKey = 'user_profile';
  static ProfileService? _instance;
  static ProfileService get instance => _instance ??= ProfileService._();
  ProfileService._();

  UserProfile _currentProfile = UserProfile();

  // ดึงข้อมูลโปรไฟล์ปัจจุบัน
  UserProfile get currentProfile => _currentProfile;

  // โหลดข้อมูลโปรไฟล์จาก API หรือ local storage
  Future<UserProfile> loadProfile() async {
    try {
      debugPrint('ProfileService.loadProfile() called');
      debugPrint('AuthService.isLoggedIn: ${AuthService.instance.isLoggedIn}');
      
      // ถ้า user login แล้ว ให้ดึงข้อมูลจาก API
      if (AuthService.instance.isLoggedIn) {
        debugPrint('User is logged in, fetching from API...');
        final response = await ApiService.get('/profile');
        debugPrint('API response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          final data = ApiService.parseResponse(response);
          debugPrint('Profile API response: ${data['profile']}'); // Debug log
          _currentProfile = UserProfile.fromMap(data['profile']);
          await _saveProfileToStorage(_currentProfile);
          debugPrint('Profile saved to storage and cache');
          return _currentProfile;
        } else {
          debugPrint('API failed with status ${response.statusCode}');
        }
      } else {
        debugPrint('User not logged in, using local storage');
      }

      // ถ้าไม่ได้ login หรือ API error ให้ใช้ข้อมูลจาก local storage
      final prefs = await SharedPreferences.getInstance();
      final profileString = prefs.getString(_profileKey);

      if (profileString != null) {
        final profileMap = json.decode(profileString);
        _currentProfile = UserProfile.fromMap(profileMap);
      } else {
        // ถ้าไม่มีข้อมูล ให้ใส่ข้อมูลตัวอย่าง
        _currentProfile = UserProfile(
          name: 'Name Clinic',
          email: 'clinic@example.com',
          phone: '081-234-5678',
          address: '123/45 หมู่ 6 ซอยลาดพร้าว 15 แยก 3\nถนนลาดพร้าว',
          district: 'จอมพล',
          province: 'กรุงเทพมหานคร',
          postalCode: '10900',
        );
        await _saveProfileToStorage(_currentProfile);
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      _currentProfile = UserProfile();
    }

    return _currentProfile;
  }

  // บันทึกข้อมูลโปรไฟล์ไปยัง API และ local storage
  Future<bool> saveProfile(UserProfile profile) async {
    try {
      // ถ้า user login แล้ว ให้บันทึกไปยัง API
      if (AuthService.instance.isLoggedIn) {
        final response = await ApiService.put('/profile', profile.toMap());
        if (response.statusCode == 200) {
          _currentProfile = profile;
          await _saveProfileToStorage(profile);
          return true;
        } else {
          return false;
        }
      }

      // ถ้าไม่ได้ login ให้บันทึกเฉพาะ local storage
      final success = await _saveProfileToStorage(profile);
      if (success) {
        _currentProfile = profile;
      }
      return success;
    } catch (e) {
      debugPrint('Error saving profile: $e');
      return false;
    }
  }

  // บันทึกข้อมูลลง local storage
  Future<bool> _saveProfileToStorage(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileString = json.encode(profile.toMap());
      return await prefs.setString(_profileKey, profileString);
    } catch (e) {
      debugPrint('Error saving profile to storage: $e');
      return false;
    }
  }

  // บังคับรีโหลดโปรไฟล์จาก API
  Future<UserProfile> forceReloadProfile() async {
    try {
      if (AuthService.instance.isLoggedIn) {
        final response = await ApiService.get('/profile');
        if (response.statusCode == 200) {
          final data = ApiService.parseResponse(response);
          _currentProfile = UserProfile.fromMap(data['profile']);
          await _saveProfileToStorage(_currentProfile);
        }
      }
    } catch (e) {
      debugPrint('Error force reloading profile: $e');
    }
    return _currentProfile;
  }

  // อัปเดตข้อมูลโปรไฟล์
  Future<bool> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? district,
    String? province,
    String? postalCode,
  }) async {
    try {
      final updatedProfile = UserProfile(
        name: name ?? _currentProfile.name,
        email: email ?? _currentProfile.email,
        phone: phone ?? _currentProfile.phone,
        address: address ?? _currentProfile.address,
        district: district ?? _currentProfile.district,
        province: province ?? _currentProfile.province,
        postalCode: postalCode ?? _currentProfile.postalCode,
      );

      return await saveProfile(updatedProfile);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // ดึงข้อมูล membership progress จาก API
  Future<Map<String, dynamic>?> getMembershipProgress() async {
    try {
      debugPrint('ProfileService.getMembershipProgress() called');

      if (!AuthService.instance.isLoggedIn) {
        debugPrint('User not logged in, returning null');
        return null;
      }

      final response = await ApiService.get('/membership/progress');
      debugPrint('Membership progress API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        debugPrint('Membership progress data: ${data['data']}');
        return data['data'];
      } else {
        debugPrint('API failed with status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching membership progress: $e');
      return null;
    }
  }

  // แลกรางวัลสมาชิก
  Future<Map<String, dynamic>?> claimReward(int level) async {
    try {
      debugPrint('ProfileService.claimReward() called with level: $level');

      if (!AuthService.instance.isLoggedIn) {
        debugPrint('User not logged in, cannot claim reward');
        return null;
      }

      final response = await ApiService.post('/membership/claim-reward', {
        'level': level,
        'reward_type': 'bundle_deal',
      });

      debugPrint('Claim reward API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        debugPrint('Claim reward response: $data');
        return data;
      } else {
        debugPrint('Claim reward API failed with status ${response.statusCode}');
        final errorData = ApiService.parseResponse(response);
        debugPrint('Error response: $errorData');
        return {
          'success': false,
          'message': errorData['message'] ?? 'เกิดข้อผิดพลาดในการแลกรางวัล',
          'error': errorData['error'] ?? 'UNKNOWN_ERROR'
        };
      }
    } catch (e) {
      debugPrint('Error claiming reward: $e');
      return {
        'success': false,
        'message': 'เกิดข้อผิดพลาดในการเชื่อมต่อ',
        'error': 'CONNECTION_ERROR'
      };
    }
  }

  // ล้างข้อมูลโปรไฟล์
  Future<bool> clearProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.remove(_profileKey);
      if (success) {
        _currentProfile = UserProfile();
      }
      return success;
    } catch (e) {
      debugPrint('Error clearing profile: $e');
      return false;
    }
  }
}
