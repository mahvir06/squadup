import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../constants/app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  
  bool get isDarkMode => _isDarkMode;
  ThemeData get themeData => _isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme;
  
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(AppConstants.themePreference) ?? false;
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.themePreference, _isDarkMode);
    
    notifyListeners();
  }
} 