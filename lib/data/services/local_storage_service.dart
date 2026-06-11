import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/reminder.dart';

class LocalStorageService {
  static const String _remindersKey = 'reminders';
  static const String _rechargesKey = 'recharges';

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  // ─── Reminder Operations ───────────────────────────────────────────────────

  Future<List<Reminder>> getReminders() async {
    try {
      final String? remindersJson = _prefs.getString(_remindersKey);
      if (remindersJson == null) return [];
      final List<dynamic> decoded = jsonDecode(remindersJson);
      return decoded.map((json) => Reminder.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveReminders(List<Reminder> reminders) async {
    try {
      final encoded = jsonEncode(reminders.map((r) => r.toJson()).toList());
      return await _prefs.setString(_remindersKey, encoded);
    } catch (e) {
      return false;
    }
  }

  Future<bool> addReminder(Reminder reminder) async {
    final reminders = await getReminders();
    reminders.add(reminder);
    return saveReminders(reminders);
  }

  Future<bool> updateReminder(Reminder reminder) async {
    final reminders = await getReminders();
    final index = reminders.indexWhere((r) => r.id == reminder.id);
    if (index == -1) return false;
    reminders[index] = reminder;
    return saveReminders(reminders);
  }

  Future<bool> deleteReminder(String id) async {
    final reminders = await getReminders();
    reminders.removeWhere((r) => r.id == id);
    return saveReminders(reminders);
  }

  // ─── Recharge Operations ──────────────────────────────────────────────────

  Future<List<MobileRecharge>> getRecharges() async {
    try {
      final String? rechargesJson = _prefs.getString(_rechargesKey);
      if (rechargesJson == null) return [];
      final List<dynamic> decoded = jsonDecode(rechargesJson);
      return decoded.map((json) => MobileRecharge.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> saveRecharges(List<MobileRecharge> recharges) async {
    try {
      final encoded = jsonEncode(recharges.map((r) => r.toJson()).toList());
      return await _prefs.setString(_rechargesKey, encoded);
    } catch (e) {
      return false;
    }
  }

  Future<bool> addRecharge(MobileRecharge recharge) async {
    final recharges = await getRecharges();
    recharges.add(recharge);
    return saveRecharges(recharges);
  }

  Future<bool> updateRecharge(MobileRecharge recharge) async {
    final recharges = await getRecharges();
    final index = recharges.indexWhere((r) => r.id == recharge.id);
    if (index == -1) return false;
    recharges[index] = recharge;
    return saveRecharges(recharges);
  }

  Future<bool> deleteRecharge(String id) async {
    final recharges = await getRecharges();
    recharges.removeWhere((r) => r.id == id);
    return saveRecharges(recharges);
  }

  // ─── Clear All ────────────────────────────────────────────────────────────

  Future<bool> clearAll() async {
    try {
      await _prefs.remove(_remindersKey);
      await _prefs.remove(_rechargesKey);
      return true;
    } catch (e) {
      return false;
    }
  }
}
