import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _key = 'technovate_assistant_onboarding';

  static Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) != true;
  }

  static Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
