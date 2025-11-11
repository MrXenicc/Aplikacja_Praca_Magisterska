import 'package:shared_preferences/shared_preferences.dart';

class AvailabilityService {
  static const String keyStartHour = "available_start_hour";
  static const String keyEndHour = "available_end_hour";

  Future<void> setAvailableHours(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyStartHour, startHour);
    await prefs.setInt(keyEndHour, endHour);
  }

  Future<Map<String, int>> getAvailableHours() async {
    final prefs = await SharedPreferences.getInstance();
    int start = prefs.getInt(keyStartHour) ?? 9;
    int end = prefs.getInt(keyEndHour) ?? 21;
    return {'start': start, 'end': end};
  }
}
