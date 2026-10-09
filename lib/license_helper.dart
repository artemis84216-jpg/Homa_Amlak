import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LicenseHelper {
  static const String _secretKey = 'HOMA_AMLAK_2026_DEV_SECRET_KEY';
  
  // تولید کد لایسنس
  static String generateLicense({
    required String deviceId,
    required DateTime expiryDate,
    required int planId,
  }) {
    final expiryStr = '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}';
    final checksum = _generateChecksum(deviceId, expiryStr, planId);
    final payload = '$deviceId|$expiryStr|$planId|$checksum';
    return base64Encode(utf8.encode(payload));
  }
  
  // بررسی اعتبار کد لایسنس
  static Map<String, dynamic>? validateLicense(String licenseCode, String currentDeviceId) {
    try {
      final payload = utf8.decode(base64Decode(licenseCode.trim()));
      final parts = payload.split('|');
      if (parts.length != 4) return null;
      
      final deviceId = parts[0];
      final expiryStr = parts[1];
      final planId = int.parse(parts[2]);
      final checksum = parts[3];
      
      // چک Device ID
      if (deviceId != currentDeviceId) return {'error': 'device_mismatch'};
      
      // چک checksum
      final expectedChecksum = _generateChecksum(deviceId, expiryStr, planId);
      if (checksum != expectedChecksum) return {'error': 'invalid_checksum'};
      
      // چک تاریخ
      final expiryDate = DateTime.parse(expiryStr);
      if (DateTime.now().isAfter(expiryDate)) return {'error': 'expired'};
      
      return {
        'deviceId': deviceId,
        'expiryDate': expiryDate,
        'planId': planId,
        'daysRemaining': expiryDate.difference(DateTime.now()).inDays,
      };
    } catch (e) {
      return {'error': 'invalid_format'};
    }
  }
  
  // تولید checksum
  static String _generateChecksum(String deviceId, String expiryStr, int planId) {
    final input = '$deviceId|$expiryStr|$planId|$_secretKey';
    int hash = 0;
    for (int i = 0; i < input.length; i++) {
      hash = (hash * 31 + input.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
  
  // ذخیره اطلاعات لایسنس
  static Future<void> saveLicense(String licenseCode, int planId, DateTime expiryDate) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('license_code', licenseCode);
    await prefs.setInt('license_plan_id', planId);
    await prefs.setString('license_expiry', expiryDate.toIso8601String());
    await prefs.setString('license_activated_at', DateTime.now().toIso8601String());
  }
  
  // دریافت اطلاعات لایسنس
  static Future<Map<String, dynamic>?> getLicense() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('license_code');
    final planId = prefs.getInt('license_plan_id');
    final expiry = prefs.getString('license_expiry');
    if (code == null || planId == null || expiry == null) return null;
    
    final expiryDate = DateTime.parse(expiry);
    final daysRemaining = expiryDate.difference(DateTime.now()).inDays;
    
    return {
      'code': code,
      'planId': planId,
      'expiry': expiryDate,
      'daysRemaining': daysRemaining,
      'isActive': daysRemaining >= 0,
    };
  }
  
  // پاک کردن لایسنس
  static Future<void> clearLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('license_code');
    await prefs.remove('license_plan_id');
    await prefs.remove('license_expiry');
    await prefs.remove('license_activated_at');
  }
}
