import 'dart:convert';
import 'dart:math';

class InvitationHelper {
  // تولید کد دعوت یکتا (۸ کاراکتری)
  static String generateInvitationCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    final code = String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
    return code;
  }

  // تولید محتوای QR کد
  static String generateQRContent({
    required String invitationCode,
    required String apkDownloadUrl,
  }) {
    final data = {
      'app': 'Homa_Amlak',
      'version': '1.0.0',
      'code': invitationCode,
      'apk': apkDownloadUrl,
    };
    return base64Encode(utf8.encode(jsonEncode(data)));
  }

  // تجزیه محتوای QR کد
  static Map<String, dynamic>? parseQRContent(String qrContent) {
    try {
      final decoded = utf8.decode(base64Decode(qrContent.trim()));
      final data = jsonDecode(decoded);
      if (data['app'] != 'Homa_Amlak') return null;
      return {
        'code': data['code'],
        'apk': data['apk'],
      };
    } catch (e) {
      return null;
    }
  }
}
