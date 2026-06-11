import '../../domain/models/reminder.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';

class ReminderRepository {
  final LocalStorageService _storageService;
  final NotificationService _notificationService;

  ReminderRepository(this._storageService, this._notificationService);

  // Get all reminders
  Future<List<Reminder>> getAllReminders() async {
    return await _storageService.getReminders();
  }

  // Add reminder
  Future<bool> addReminder(Reminder reminder) async {
    final success = await _storageService.addReminder(reminder);
    if (success) {
      await _notificationService.scheduleReminderNotification(reminder);
    }
    return success;
  }

  // Update reminder — FIX: uses typed cancel so it hits the correct notification id
  Future<bool> updateReminder(Reminder reminder) async {
    final success = await _storageService.updateReminder(reminder);
    if (success) {
      // Always cancel existing notification first
      await _notificationService.cancelReminderNotification(reminder.id);
      // Re-schedule only when appropriate (not completed + notifications on)
      if (reminder.notificationEnabled && !reminder.isCompleted) {
        await _notificationService.scheduleReminderNotification(reminder);
      }
    }
    return success;
  }

  // Delete reminder
  Future<bool> deleteReminder(String id) async {
    await _notificationService.cancelReminderNotification(id); // FIX: typed cancel
    return await _storageService.deleteReminder(id);
  }

  // Get active reminders
  Future<List<Reminder>> getActiveReminders() async {
    final reminders = await getAllReminders();
    return reminders
        .where((r) => !r.isCompleted && r.dateTime.isAfter(DateTime.now()))
        .toList();
  }

  // Get completed reminders
  Future<List<Reminder>> getCompletedReminders() async {
    final reminders = await getAllReminders();
    return reminders.where((r) => r.isCompleted).toList();
  }

  // Get overdue reminders
  Future<List<Reminder>> getOverdueReminders() async {
    final reminders = await getAllReminders();
    return reminders
        .where((r) => !r.isCompleted && r.dateTime.isBefore(DateTime.now()))
        .toList();
  }

  // Search reminders
  Future<List<Reminder>> searchReminders(String query) async {
    if (query.isEmpty) return await getAllReminders();

    final reminders = await getAllReminders();
    final lowerQuery = query.toLowerCase();

    return reminders.where((r) {
      return r.title.toLowerCase().contains(lowerQuery) ||
          (r.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // Get reminders by category
  Future<List<Reminder>> getRemindersByCategory(
      ReminderCategory category) async {
    final reminders = await getAllReminders();
    return reminders.where((r) => r.category == category).toList();
  }
}
