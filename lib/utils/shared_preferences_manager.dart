import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  static SharedPreferencesManager _manager;
  static SharedPreferences _preferences;

  static const String keyAccessToken = 'accessToken';
  static const String keyRefreshToken = 'refreshToken';
  static const String keyIsLogin = 'isLogin';
  static const String keyUsername = 'username';
  static const String keyAuthMSecs = 'authMSecs';

  static Future<SharedPreferencesManager> getInstance() async {
    if (_manager == null) {
      _manager = SharedPreferencesManager();
    }
    if (_preferences == null) {
      _preferences = await SharedPreferences.getInstance();
    }
    return _manager;
  }

  Future<bool> putBool(String key, bool value) => _preferences.setBool(key, value);

  bool getBool(String key) => _preferences.getBool(key);

  Future<bool> putDouble(String key, double value) => _preferences.setDouble(key, value);

  double getDouble(String key) => _preferences.getDouble(key);

  Future<bool> putInt(String key, int value) => _preferences.setInt(key, value);

  int getInt(String key) => _preferences.getInt(key);

  Future<bool> putString(String key, String value) => _preferences.setString(key, value);

  String getString(String key) => _preferences.getString(key);

  Future<bool> putStringList(String key, List<String> value) => _preferences.setStringList(key, value);

  List<String> getStringList(String key) => _preferences.getStringList(key);

  bool isKeyExists(String key) => _preferences.containsKey(key);

  Future<bool> clearKey(String key) => _preferences.remove(key);

  Future<bool> clearAll() => _preferences.clear();
}