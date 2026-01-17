import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bloc/reminder/reminder_bloc.dart';
import '../../bloc/recharge/recharge_bloc.dart';
import '../../bloc/theme/theme_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _defaultReminderTime = '09:00 AM';
  int _defaultReminderDays = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _defaultReminderTime =
          prefs.getString('default_reminder_time') ?? '09:00 AM';
      _defaultReminderDays = prefs.getInt('default_reminder_days') ?? 3;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
    await prefs.setString('default_reminder_time', _defaultReminderTime);
    await prefs.setInt('default_reminder_days', _defaultReminderDays);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Notifications'),
          const SizedBox(height: 8),
          _buildNotificationSettings(),
          const SizedBox(height: 24),
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 8),
          _buildAppearanceSettings(),
          const SizedBox(height: 24),
          _buildSectionHeader('Default Settings'),
          const SizedBox(height: 8),
          _buildDefaultSettings(),
          const SizedBox(height: 24),
          _buildSectionHeader('Data Management'),
          const SizedBox(height: 8),
          _buildDataManagement(),
          const SizedBox(height: 24),
          _buildSectionHeader('About'),
          const SizedBox(height: 8),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive reminder notifications'),
            secondary: const Icon(Icons.notifications),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _saveSettings();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    value
                        ? 'Notifications enabled'
                        : 'Notifications disabled',
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettings() {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return Card(
          child: Column(
            children: [
              RadioListTile<ThemeMode>(
                title: const Text('Light Mode'),
                secondary: const Icon(Icons.light_mode),
                value: ThemeMode.light,
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeCubit>().setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Dark Mode'),
                secondary: const Icon(Icons.dark_mode),
                value: ThemeMode.dark,
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeCubit>().setThemeMode(value);
                  }
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('System Default'),
                secondary: const Icon(Icons.settings_suggest),
                value: ThemeMode.system,
                groupValue: themeMode,
                onChanged: (value) {
                  if (value != null) {
                    context.read<ThemeCubit>().setThemeMode(value);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultSettings() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.access_time),
            title: const Text('Default Reminder Time'),
            subtitle: Text(_defaultReminderTime),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _selectDefaultTime(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Default Recharge Reminder'),
            subtitle: Text('$_defaultReminderDays days before expiry'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: _defaultReminderDays > 1
                      ? () {
                    setState(() {
                      _defaultReminderDays--;
                    });
                    _saveSettings();
                  }
                      : null,
                ),
                Text('$_defaultReminderDays'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: _defaultReminderDays < 10
                      ? () {
                    setState(() {
                      _defaultReminderDays++;
                    });
                    _saveSettings();
                  }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagement() {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.storage, color: Colors.blue),
            title: const Text('Storage Info'),
            subtitle: const Text('View app data usage'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showStorageInfo(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text('Export Data'),
            subtitle: const Text('Backup reminders and recharges'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.upload, color: Colors.orange),
            title: const Text('Import Data'),
            subtitle: const Text('Restore from backup'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _importData(),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all reminders and recharges'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearDataDialog(),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Column(
        children: [
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('Version'),
            subtitle: Text('1.0.0'),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening privacy policy...')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening terms of service...')),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source Licenses'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(context: context);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _selectDefaultTime() async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_defaultReminderTime.split(':')[0]),
        minute: int.parse(_defaultReminderTime.split(':')[1].split(' ')[0]),
      ),
    );

    if (time != null) {
      setState(() {
        _defaultReminderTime = time.format(context);
      });
      _saveSettings();
    }
  }

  void _showStorageInfo() {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<ReminderBloc, ReminderState>(
        builder: (context, reminderState) {
          return BlocBuilder<RechargeBloc, RechargeState>(
            builder: (context, rechargeState) {
              int reminderCount = 0;
              int rechargeCount = 0;

              if (reminderState is ReminderLoaded) {
                reminderCount = reminderState.reminders.length;
              }
              if (rechargeState is RechargeLoaded) {
                rechargeCount = rechargeState.recharges.length;
              }

              return AlertDialog(
                title: const Text('Storage Information'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStorageItem('Reminders', reminderCount),
                    const SizedBox(height: 8),
                    _buildStorageItem('Recharges', rechargeCount),
                    const SizedBox(height: 16),
                    Text(
                      'Total: ${reminderCount + rechargeCount} items',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStorageItem(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _importData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Import feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all reminders and recharges? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('reminders');
              await prefs.remove('recharges');

              if (mounted) {
                context.read<ReminderBloc>().add(LoadReminders());
                context.read<RechargeBloc>().add(LoadRecharges());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data cleared')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}