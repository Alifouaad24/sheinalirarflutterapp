/// Every SharedPreferences key lives here — never use raw strings elsewhere.
abstract final class StorageKeys {
  static const String cartItems = 'cart_items';
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String languageCode = 'language_code';
  static const String themeMode = 'theme_mode';
}
