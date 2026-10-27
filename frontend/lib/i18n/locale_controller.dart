import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the active app language and persists the user's choice.
/// Defaults to the device locale (th if Thai, otherwise en).
class LocaleController extends ChangeNotifier {
  static const _kKey = 'app_locale';
  static const supported = ['th', 'en'];

  String _lang = 'th';
  String get lang => _lang;
  bool get isThai => _lang == 'th';

  /// Load the saved choice, or fall back to the device locale.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kKey);
    if (saved != null && supported.contains(saved)) {
      _lang = saved;
    } else {
      final device =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _lang = device == 'th' ? 'th' : 'en';
    }
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    if (!supported.contains(lang) || lang == _lang) return;
    _lang = lang;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kKey, lang);
  }

  Future<void> toggle() => setLang(isThai ? 'en' : 'th');
}
