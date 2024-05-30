import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserCache {
  static const _userIdKey = 'userId';
  static const _userNameKey = 'userName';
  static const _userEmailKey = 'userEmail';
  static const _userAvatarUrlKey = 'userAvatarUrl';

  static Future<void> saveUserData({
    required String userId,
    required String userName,
    required String userEmail,
    required String userAvatarUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
    await prefs.setString(_userAvatarUrlKey, userAvatarUrl);
  }

  static Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_userIdKey) ?? '';
    final userName = prefs.getString(_userNameKey) ?? '';
    final userEmail = prefs.getString(_userEmailKey) ?? '';
    final userAvatarUrl = prefs.getString(_userAvatarUrlKey) ?? '';
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatarUrl': userAvatarUrl,
    };
  }
}
