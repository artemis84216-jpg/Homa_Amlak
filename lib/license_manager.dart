import 'database_helper.dart';
import 'license_helper.dart';

class LicenseManager {
  // دریافت اطلاعات پلن فعلی
  static Future<Map<String, dynamic>?> getCurrentPlan() async {
    final license = await LicenseHelper.getLicense();
    if (license == null || license['isActive'] != true) return null;
    
    final plans = await DatabaseHelper.instance.getAllPlans();
    final plan = plans.firstWhere((p) => p['id'] == license['planId'], orElse: () => {});
    return plan.isNotEmpty ? plan : null;
  }

  // بررسی امکان افزودن مشاور جدید
  static Future<Map<String, dynamic>> canAddAgent() async {
    final plan = await getCurrentPlan();
    if (plan == null) {
      return {'allowed': false, 'message': 'لایسنس فعال ندارید'};
    }

    final maxAgents = plan['max_agents'] ?? 0;
    // اگر 0 باشد یعنی نامحدود
    if (maxAgents == 0) {
      return {'allowed': true, 'current': 0, 'max': -1, 'isUnlimited': true};
    }

    final currentAgents = await DatabaseHelper.instance.getAllAgents();
    final activeAgents = currentAgents.where((a) => a['status'] == 'active').length;

    if (activeAgents >= maxAgents) {
      return {
        'allowed': false,
        'current': activeAgents,
        'max': maxAgents,
        'isUnlimited': false,
        'message': 'سقف مشاوران پلن شما پر شده است (${activeAgents} از $maxAgents)',
      };
    }

    return {
      'allowed': true,
      'current': activeAgents,
      'max': maxAgents,
      'isUnlimited': false,
    };
  }

  // بررسی امکان افزودن ملک جدید
  static Future<Map<String, dynamic>> canAddProperty() async {
    final plan = await getCurrentPlan();
    if (plan == null) {
      return {'allowed': false, 'message': 'لایسنس فعال ندارید'};
    }

    final maxProperties = plan['max_properties'] ?? 0;
    if (maxProperties == 0) {
      return {'allowed': true, 'current': 0, 'max': -1, 'isUnlimited': true};
    }

    final allProperties = await DatabaseHelper.instance.getAllProperties();
    final currentCount = allProperties.length;

    if (currentCount >= maxProperties) {
      return {
        'allowed': false,
        'current': currentCount,
        'max': maxProperties,
        'isUnlimited': false,
        'message': 'سقف فایل ملک پلن شما پر شده است ($currentCount از $maxProperties)',
      };
    }

    return {
      'allowed': true,
      'current': currentCount,
      'max': maxProperties,
      'isUnlimited': false,
    };
  }

  // دریافت آمار کلی برای نمایش در داشبورد
  static Future<Map<String, dynamic>> getUsageStats() async {
    final plan = await getCurrentPlan();
    if (plan == null) {
      return {
        'hasLicense': false,
        'planName': 'بدون لایسنس',
        'agents': {'current': 0, 'max': 0, 'isUnlimited': false},
        'properties': {'current': 0, 'max': 0, 'isUnlimited': false},
      };
    }

    final allAgents = await DatabaseHelper.instance.getAllAgents();
    final activeAgents = allAgents.where((a) => a['status'] == 'active').length;
    final maxAgents = plan['max_agents'] ?? 0;

    final allProperties = await DatabaseHelper.instance.getAllProperties();
    final maxProperties = plan['max_properties'] ?? 0;

    return {
      'hasLicense': true,
      'planName': plan['name'] ?? 'پلن نامشخص',
      'agents': {
        'current': activeAgents,
        'max': maxAgents,
        'isUnlimited': maxAgents == 0,
      },
      'properties': {
        'current': allProperties.length,
        'max': maxProperties,
        'isUnlimited': maxProperties == 0,
      },
    };
  }
}
