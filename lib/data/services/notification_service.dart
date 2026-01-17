import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../domain/models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
      _onDidReceiveBackgroundNotificationResponse,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }

    // Request exact alarm permission for Android 12+
    final androidImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!reminder.notificationEnabled) return;
    if (reminder.dateTime.isBefore(DateTime.now())) {
      debugPrint('Reminder time is in the past, skipping notification');
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'reminder_channel',
        'Reminders',
        channelDescription: 'Channel for reminder notifications',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        reminder.id.hashCode,
        reminder.title,
        reminder.description ?? 'Reminder notification',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(reminder.repeat),
        payload: reminder.id,
      );

      debugPrint('Scheduled notification for ${reminder.title} at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  DateTimeComponents? _getDateTimeComponents(RepeatType repeat) {
    switch (repeat) {
      case RepeatType.daily:
        return DateTimeComponents.time;
      case RepeatType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatType.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      default:
        return null;
    }
  }

  Future<void> scheduleRechargeReminder(MobileRecharge recharge) async {
    if (!recharge.reminderEnabled) return;

    final reminderDate = recharge.expiryDate.subtract(
      Duration(days: recharge.reminderDaysBefore),
    );

    if (reminderDate.isBefore(DateTime.now())) {
      debugPrint('Reminder date is in the past, skipping notification');
      return;
    }

    try {
      const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
        'recharge_channel',
        'Recharge Reminders',
        channelDescription: 'Channel for mobile recharge reminders',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final scheduledDate = tz.TZDateTime.from(reminderDate, tz.local);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        recharge.id.hashCode,
        'Recharge Reminder',
        'Your ${recharge.operator} recharge for ${recharge.mobileNumber} expires in ${recharge.reminderDaysBefore} days',
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
        payload: recharge.id,
      );

      debugPrint('Scheduled recharge notification for ${recharge.mobileNumber} at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling recharge notification: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _onDidReceiveBackgroundNotificationResponse(
      NotificationResponse notificationResponse) {
    debugPrint('Background notification payload: ${notificationResponse.payload}');
  }

  void _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) {
    debugPrint('Notification payload: ${notificationResponse.payload}');
    // Implement navigation or logic here
  }

  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      debugPrint('Cancelled notification with id: $id');
    } catch (e) {
      debugPrint('Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('Cancelled all notifications');
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}