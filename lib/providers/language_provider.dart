import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English
  
  Locale get locale => _locale;
  
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isSwahili => _locale.languageCode == 'sw';

  LanguageProvider() {
    _loadLanguage();
  }

  void _loadLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  void setLanguage(String languageCode) async {
    if (languageCode == _locale.languageCode) return;
    
    _locale = Locale(languageCode);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    notifyListeners();
  }

  void changeLanguage(String languageCode) {
    setLanguage(languageCode);
  }

  void toggleLanguage() {
    String newLanguage = _locale.languageCode == 'en' ? 'sw' : 'en';
    setLanguage(newLanguage);
  }
}
