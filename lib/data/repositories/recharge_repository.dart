import '../../domain/models/reminder.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

class RechargeRepository {
  final LocalStorageService _storageService;
  final NotificationService _notificationService;

  RechargeRepository(this._storageService, this._notificationService);

  // Get all recharges
  Future<List<MobileRecharge>> getAllRecharges() async {
    return await _storageService.getRecharges();
  }

  // Add recharge
  Future<bool> addRecharge(MobileRecharge recharge) async {
    final success = await _storageService.addRecharge(recharge);
    if (success) {
      // scheduleRechargeReminder already guards on reminderEnabled internally
      await _notificationService.scheduleRechargeReminder(recharge);
    }
    return success;
  }

  // Update recharge — FIX: uses typed cancel
  Future<bool> updateRecharge(MobileRecharge recharge) async {
    final success = await _storageService.updateRecharge(recharge);
    if (success) {
      await _notificationService.cancelRechargeNotification(recharge.id);
      if (recharge.reminderEnabled) {
        await _notificationService.scheduleRechargeReminder(recharge);
      }
    }
    return success;
  }

  // Delete recharge — FIX: uses typed cancel
  Future<bool> deleteRecharge(String id) async {
    await _notificationService.cancelRechargeNotification(id);
    return await _storageService.deleteRecharge(id);
  }

  // Get active recharges
  Future<List<MobileRecharge>> getActiveRecharges() async {
    final recharges = await getAllRecharges();
    return recharges.where((r) => !r.isExpired).toList();
  }

  // Get expiring soon recharges
  Future<List<MobileRecharge>> getExpiringSoonRecharges() async {
    final recharges = await getAllRecharges();
    return recharges.where((r) => r.isExpiringSoon).toList();
  }

  // Get expired recharges
  Future<List<MobileRecharge>> getExpiredRecharges() async {
    final recharges = await getAllRecharges();
    return recharges.where((r) => r.isExpired).toList();
  }

  // Get latest recharge for a number
  Future<MobileRecharge?> getLatestRechargeForNumber(
      String mobileNumber) async {
    final recharges = await getAllRecharges();
    final numberRecharges =
        recharges.where((r) => r.mobileNumber == mobileNumber).toList();

    if (numberRecharges.isEmpty) return null;

    return numberRecharges.reduce(
        (a, b) => a.rechargeDate.isAfter(b.rechargeDate) ? a : b);
  }

  // Get unique mobile numbers
  Future<List<String>> getUniqueMobileNumbers() async {
    final recharges = await getAllRecharges();
    return recharges.map((r) => r.mobileNumber).toSet().toList();
  }

  // Get recharges for a specific number
  Future<List<MobileRecharge>> getRechargesForNumber(
      String mobileNumber) async {
    final recharges = await getAllRecharges();
    return recharges.where((r) => r.mobileNumber == mobileNumber).toList();
  }
}
