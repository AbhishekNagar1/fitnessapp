import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userId;
  String? _username;
  String? _email;

  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get username => _username;
  String? get email => _email;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool('isAuthenticated') ?? false;
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');
    _email = prefs.getString('email');
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    // TODO: Implement actual login logic with your backend
    // For now, we'll just simulate a successful login
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = true;
    _userId = 'abhishek';
    _username = 'Abhishek';
    _email = email;

    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('userId', _userId!);
    await prefs.setString('username', _username!);
    await prefs.setString('email', _email!);

    notifyListeners();
  }

  Future<void> signup(String email, String password, String username) async {
    // TODO: Implement actual signup logic with your backend
    // For now, we'll just simulate a successful signup
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = true;
    _userId = 'user123';
    _username = username;
    _email = email;

    await prefs.setBool('isAuthenticated', true);
    await prefs.setString('userId', _userId!);
    await prefs.setString('username', _username!);
    await prefs.setString('email', _email!);

    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isAuthenticated = false;
    _userId = null;
    _username = null;
    _email = null;

    notifyListeners();
  }
} 