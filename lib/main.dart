import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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

  // Initialize timezone database
  tz.initializeTimeZones();

  // Set local timezone
  try {
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    // Extract timezone name as string
    String tzName;
    if (timeZoneName is String) {
      tzName = timeZoneName.toString();
    } else {
      // For TimezoneInfo object, access identifier property
      tzName = (timeZoneName as dynamic).identifier as String;
    }
    tz.setLocalLocation(tz.getLocation(tzName));
  } catch (e) {
    debugPrint("Could not get timezone, defaulting to UTC: $e");
    tz.setLocalLocation(tz.getLocation('UTC'));
  }

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialize services
  final localStorageService = LocalStorageService(prefs);

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  // Initialize repositories
  final reminderRepository =
  ReminderRepository(localStorageService, notificationService);
  final rechargeRepository =
  RechargeRepository(localStorageService, notificationService);

  runApp(MyApp(
    prefs: prefs,
    reminderRepository: reminderRepository,
    rechargeRepository: rechargeRepository,
  ));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  final ReminderRepository reminderRepository;
  final RechargeRepository rechargeRepository;

  const MyApp({
    super.key,
    required this.prefs,
    required this.reminderRepository,
    required this.rechargeRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ThemeCubit(prefs),
        ),
        BlocProvider(
          create: (context) =>
          ReminderBloc(reminderRepository)..add(LoadReminders()),
        ),
        BlocProvider(
          create: (context) =>
          RechargeBloc(rechargeRepository)..add(LoadRecharges()),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Smart Reminder',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.purple,
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.purple,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.purple,
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