
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class KeyManager {
  static const String _storageKeysJson = "online_api_keys";
  static const _storage = FlutterSecureStorage();
  static Future<void> saveKeys(Map<String, dynamic> keys) async { await _storage.write(key: _storageKeysJson, value: jsonEncode(keys)); }
  static Future<Map<String, dynamic>?> getSavedKeys() async { final jsonStr = await _storage.read(key: _storageKeysJson); if (jsonStr==null) return null; return jsonDecode(jsonStr); }
  static Future<void> clearKeys() async { await _storage.delete(key: _storageKeysJson); }
}
