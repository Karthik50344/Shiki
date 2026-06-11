import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'data/services/local_storage_service.dart';
import 'data/services/notification_service.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/repositories/recharge_repository.dart';
import 'presentation/bloc/reminder/reminder_bloc.dart';
import 'presentation/bloc/recharge/recharge_bloc.dart';
import 'presentation/bloc/theme/theme_cubit.dart';
import 'presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch all unhandled Flutter framework errors — log instead of crash
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}\n${details.stack}');
  };

  // Catch unhandled async / platform channel errors — log instead of crash
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('PlatformDispatcher error: $error\n$stack');
    return true; // "handled" — prevents process kill
  };

  tz.initializeTimeZones();
  await _initTimezone();

  final prefs = await SharedPreferences.getInstance();
  final localStorageService = LocalStorageService(prefs);
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Request battery optimization exemption on first run.
  // This is the #1 fix for notifications not working on real devices.
  // The system dialog only shows once — if already granted, this is a no-op.
  await _requestBatteryExemptionIfNeeded();

  final reminderRepository =
  ReminderRepository(localStorageService, notificationService);
  final rechargeRepository =
  RechargeRepository(localStorageService, notificationService);

  // Wire up tap callback. Uses addPostFrameCallback so navigation never
  // fires mid-frame or before the router is mounted — both of which crash.
  notificationService.onNotificationTap = (String? payload) {
    if (payload == null || payload.isEmpty) return;
    debugPrint('Notification tapped, payload: $payload');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        AppRouter.router.go(AppRouter.reminders);
      } catch (e) {
        debugPrint('Notification navigation failed (non-fatal): $e');
      }
    });
  };

  runApp(MyApp(
    prefs: prefs,
    notificationService: notificationService,
    reminderRepository: reminderRepository,
    rechargeRepository: rechargeRepository,
  ));
}

Future<void> _requestBatteryExemptionIfNeeded() async {
  try {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  } catch (e) {
    debugPrint('Battery exemption request failed (non-fatal): $e');
  }
}

Future<void> _initTimezone() async {
  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    final tzName = timeZoneName is String
        ? timeZoneName
        : (timeZoneName as dynamic).identifier as String;
    tz.setLocalLocation(tz.getLocation(tzName.toString()));
    debugPrint('Timezone: $tzName');
  } catch (e) {
    debugPrint('FlutterTimezone failed ($e), using offset fallback');
    try {
      final offsetHours = DateTime.now().timeZoneOffset.inHours;
      final fallback = _guessTimezoneByOffset(offsetHours);
      tz.setLocalLocation(tz.getLocation(fallback));
      debugPrint('Timezone fallback: $fallback');
    } catch (e2) {
      debugPrint('Timezone fallback failed ($e2), using UTC');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}

String _guessTimezoneByOffset(int offsetHours) {
  switch (offsetHours) {
    case 5:  return 'Asia/Karachi';
    case 6:  return 'Asia/Dhaka';
    case 7:  return 'Asia/Bangkok';
    case 8:  return 'Asia/Shanghai';
    case 9:  return 'Asia/Tokyo';
    case 10: return 'Australia/Sydney';
    case 12: return 'Pacific/Auckland';
    case -5: return 'America/New_York';
    case -6: return 'America/Chicago';
    case -7: return 'America/Denver';
    case -8: return 'America/Los_Angeles';
    case 0:  return 'Europe/London';
    case 1:  return 'Europe/Paris';
    case 2:  return 'Europe/Helsinki';
    case 3:  return 'Europe/Moscow';
    default: return 'Asia/Kolkata'; // IST UTC+5:30
  }
}

class MyApp extends StatefulWidget {
  final SharedPreferences prefs;
  final NotificationService notificationService;
  final ReminderRepository reminderRepository;
  final RechargeRepository rechargeRepository;

  const MyApp({
    super.key,
    required this.prefs,
    required this.notificationService,
    required this.reminderRepository,
    required this.rechargeRepository,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Handle cold-start via notification tap (app was killed)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.notificationService.handleAppLaunchNotification();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(widget.prefs)),
        BlocProvider(
          create: (_) =>
          ReminderBloc(widget.reminderRepository)..add(LoadReminders()),
        ),
        BlocProvider(
          create: (_) =>
          RechargeBloc(widget.rechargeRepository)..add(LoadRecharges()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Shiki',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
            ),
            themeMode: themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}