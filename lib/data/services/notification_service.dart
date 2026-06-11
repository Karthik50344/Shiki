import 'package:flutter/cupertino.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import '../../domain/models/reminder.dart';

typedef NotificationTapCallback = void Function(String? payload);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int _defaultReminderHour = 9;
  static const int _defaultReminderMinute = 0;

  static int _reminderNotificationId(String id) => id.hashCode & 0x3FFFFFFF;
  static int _rechargeNotificationId(String id) =>
      (id.hashCode & 0x3FFFFFFF) | 0x40000000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  NotificationTapCallback? onNotificationTap;

  Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
      onDidReceiveBackgroundNotificationResponse: _onBackgroundResponse,
      onDidReceiveNotificationResponse: _onForegroundResponse,
    );

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Notification permission (Android 13+ / iOS)
    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      await Permission.notification.request();
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();

      // Request exact alarm permission — required on Android 12+
      // This opens the "Alarms & reminders" system settings page if needed
      try {
        final canSchedule = await android.canScheduleExactNotifications();
        if (canSchedule == false) {
          await android.requestExactAlarmsPermission();
        }
      } catch (e) {
        debugPrint('Exact alarm permission request failed (non-fatal): $e');
      }
    }
  }

  /// Call once after initialize() to handle cold-start via notification tap.
  Future<void> handleAppLaunchNotification() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null &&
          details.didNotificationLaunchApp &&
          details.notificationResponse != null) {
        final payload = details.notificationResponse!.payload;
        debugPrint('App launched from notification: $payload');
        await Future.delayed(const Duration(milliseconds: 500));
        onNotificationTap?.call(payload);
      }
    } catch (e) {
      debugPrint('handleAppLaunchNotification error (non-fatal): $e');
    }
  }

  // ─── Reminder Notifications ───────────────────────────────────────────────

  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!reminder.notificationEnabled) return;
    if (reminder.isCompleted) return;
    if (reminder.dateTime.isBefore(DateTime.now())) {
      debugPrint('Reminder "${reminder.title}" is in the past, skipping');
      return;
    }

    try {
      final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);
      final notifId = _reminderNotificationId(reminder.id);

      await _plugin.zonedSchedule(
        notifId,
        reminder.title,
        reminder.description ?? 'You have a reminder',
        scheduledDate,
        _buildNotificationDetails(
          channelId: 'reminder_channel',
          channelName: 'Reminders',
          channelDesc: 'Reminder notifications',
        ),
        // FIX: exactAllowWhileIdle — fires precisely even in Doze mode.
        // On real devices, inexact alarms can be batched/delayed by HOURS.
        // exactAllowWhileIdle works with both SCHEDULE_EXACT_ALARM and
        // USE_EXACT_ALARM (whichever is granted).
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(reminder.repeat),
        payload: reminder.id,
      );

      debugPrint(
          'Scheduled reminder "${reminder.title}" at $scheduledDate (id: $notifId)');
    } catch (e) {
      debugPrint('Error scheduling reminder: $e');
      // If exact alarm is not permitted, fall back to inexact
      await _scheduleReminderInexact(reminder);
    }
  }

  // Inexact fallback — used when SCHEDULE_EXACT_ALARM is denied
  Future<void> _scheduleReminderInexact(Reminder reminder) async {
    try {
      final scheduledDate = tz.TZDateTime.from(reminder.dateTime, tz.local);
      final notifId = _reminderNotificationId(reminder.id);
      await _plugin.zonedSchedule(
        notifId,
        reminder.title,
        reminder.description ?? 'You have a reminder',
        scheduledDate,
        _buildNotificationDetails(
          channelId: 'reminder_channel',
          channelName: 'Reminders',
          channelDesc: 'Reminder notifications',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(reminder.repeat),
        payload: reminder.id,
      );
      debugPrint('Scheduled reminder (inexact fallback) "${reminder.title}"');
    } catch (e) {
      debugPrint('Inexact fallback also failed: $e');
    }
  }

  // ─── Recharge Notifications ───────────────────────────────────────────────

  Future<void> scheduleRechargeReminder(MobileRecharge recharge) async {
    if (!recharge.reminderEnabled) return;

    final rawDate = recharge.expiryDate
        .subtract(Duration(days: recharge.reminderDaysBefore));

    var reminderDateTime = DateTime(
      rawDate.year,
      rawDate.month,
      rawDate.day,
      _defaultReminderHour,
      _defaultReminderMinute,
    );

    final now = DateTime.now();

    if (reminderDateTime.isBefore(now)) {
      if (recharge.isExpired) {
        debugPrint('Recharge ${recharge.mobileNumber} expired, skipping');
        return;
      }
      debugPrint('Recharge reminder date passed — scheduling immediate');
      reminderDateTime = now.add(const Duration(seconds: 5));
    }

    try {
      final scheduledDate = tz.TZDateTime.from(reminderDateTime, tz.local);
      final notifId = _rechargeNotificationId(recharge.id);
      final daysLeft = recharge.daysRemaining;
      final body = daysLeft <= 0
          ? 'Your ${recharge.operator} recharge for ${recharge.mobileNumber} has expired'
          : 'Your ${recharge.operator} recharge for ${recharge.mobileNumber} '
              'expires in $daysLeft day${daysLeft == 1 ? '' : 's'}';

      await _plugin.zonedSchedule(
        notifId,
        'Recharge Reminder 📱',
        body,
        scheduledDate,
        _buildNotificationDetails(
          channelId: 'recharge_channel',
          channelName: 'Recharge Reminders',
          channelDesc: 'Mobile recharge expiry notifications',
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: recharge.id,
      );

      debugPrint(
          'Scheduled recharge reminder for ${recharge.mobileNumber} at $scheduledDate');
    } catch (e) {
      debugPrint('Error scheduling recharge reminder: $e');
      await _scheduleRechargeInexact(recharge, reminderDateTime);
    }
  }

  Future<void> _scheduleRechargeInexact(
      MobileRecharge recharge, DateTime reminderDateTime) async {
    try {
      final scheduledDate = tz.TZDateTime.from(reminderDateTime, tz.local);
      final notifId = _rechargeNotificationId(recharge.id);
      await _plugin.zonedSchedule(
        notifId,
        'Recharge Reminder 📱',
        'Check your ${recharge.operator} recharge for ${recharge.mobileNumber}',
        scheduledDate,
        _buildNotificationDetails(
          channelId: 'recharge_channel',
          channelName: 'Recharge Reminders',
          channelDesc: 'Mobile recharge expiry notifications',
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: recharge.id,
      );
      debugPrint('Scheduled recharge reminder (inexact fallback)');
    } catch (e) {
      debugPrint('Inexact recharge fallback also failed: $e');
    }
  }

  // ─── Cancel ───────────────────────────────────────────────────────────────

  Future<void> cancelReminderNotification(String id) async {
    try {
      await _plugin.cancel(_reminderNotificationId(id));
    } catch (e) {
      debugPrint('Cancel reminder notification error: $e');
    }
  }

  Future<void> cancelRechargeNotification(String id) async {
    try {
      await _plugin.cancel(_rechargeNotificationId(id));
    } catch (e) {
      debugPrint('Cancel recharge notification error: $e');
    }
  }

  Future<void> cancelNotification(int id) async {
    try {
      await _plugin.cancel(id);
    } catch (e) {
      debugPrint('Cancel notification error: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Cancel all notifications error: $e');
    }
  }

  // ─── Diagnostics ──────────────────────────────────────────────────────────

  Future<List<String>> diagnose() async {
    final issues = <String>[];

    final notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      issues.add('❌ Notification permission denied.\n'
          'Go to Settings → Apps → Shikokiroku → Notifications → Enable.');
    } else {
      issues.add('✓ Notification permission granted.');
    }

    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      try {
        final canExact = await android.canScheduleExactNotifications();
        if (canExact == true) {
          issues.add('✓ Exact alarm permission granted.');
        } else {
          issues.add('❌ Exact alarm permission NOT granted.\n'
              'Go to Settings → Apps → Special app access → '
              'Alarms & reminders → Shikokiroku → Allow.');
        }
      } catch (e) {
        issues.add('⚠ Could not check exact alarm permission: $e');
      }
    }

    // Battery optimization check
    final batteryStatus =
        await Permission.ignoreBatteryOptimizations.status;
    if (!batteryStatus.isGranted) {
      issues.add('❌ Battery optimization is ON for this app.\n'
          'This is the most common cause of missed notifications on real devices.\n'
          'Go to Settings → Battery → App battery usage → Shikokiroku → Unrestricted.\n'
          'OR tap "Fix" button below to open the system dialog.');
    } else {
      issues.add('✓ Battery optimization exemption granted.');
    }

    final pending = await plugin.pendingNotificationRequests();
    if (pending.isEmpty) {
      issues.add('⚠ No notifications are currently scheduled.\n'
          'Add a reminder or recharge to schedule one.');
    } else {
      issues.add('✓ ${pending.length} notification(s) scheduled:');
      for (final n in pending) {
        issues.add('   • ${n.title ?? "(no title)"}  [id: ${n.id}]');
      }
    }

    return issues;
  }

  /// Request battery optimization exemption — shows system dialog.
  Future<void> requestBatteryExemption() async {
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (e) {
      debugPrint('Battery exemption request error: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  NotificationDetails _buildNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDesc,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: Importance.max,     // MAX so heads-up shows on real devices
        priority: Priority.max,         // MAX priority
        enableVibration: true,
        playSound: true,
        enableLights: true,
        fullScreenIntent: true,         // Wake screen if locked
        visibility: NotificationVisibility.public, // Show on lock screen
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  DateTimeComponents? _getDateTimeComponents(RepeatType repeat) {
    switch (repeat) {
      case RepeatType.daily:
        return DateTimeComponents.time;
      case RepeatType.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatType.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepeatType.yearly:
        return DateTimeComponents.dateAndTime;
      default:
        return null;
    }
  }

  @pragma('vm:entry-point')
  static void _onBackgroundResponse(NotificationResponse r) {
    debugPrint('BG notification tapped: ${r.payload}');
  }

  void _onForegroundResponse(NotificationResponse r) {
    debugPrint('FG notification tapped: ${r.payload}');
    onNotificationTap?.call(r.payload);
  }
}
