import 'package:flutter/material.dart';
import 'storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  final StorageService _storage;

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('am'),
    Locale('om'),
  ];

  static const Map<String, String> localeNames = {
    'en': 'English',
    'am': 'Amharic',
    'om': 'Afaan Oromo',
  };

  LocaleProvider(this._storage) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final savedLocale = await _storage.getLocale();
    if (savedLocale != null) {
      _locale = Locale(savedLocale);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    await _storage.saveLocale(locale.languageCode);
  }
}
