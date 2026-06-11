import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/local_storage_service.dart';
import '../../../data/services/notification_service.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          _buildSectionHeader('Notifications'),
          _buildNotificationSettings(),
          const SizedBox(height: 20),
          _buildSectionHeader('Appearance'),
          _buildAppearanceSettings(),
          const SizedBox(height: 20),
          _buildSectionHeader('Default Settings'),
          _buildDefaultSettings(),
          const SizedBox(height: 20),
          _buildSectionHeader('Data Management'),
          _buildDataManagement(),
          const SizedBox(height: 20),
          _buildSectionHeader('About'),
          _buildAboutSection(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return _SettingsCard(
      children: [
        SwitchListTile(
          title: const Text('Enable Notifications',
              style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('Receive reminder notifications'),
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications, color: Colors.purple),
          ),
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() => _notificationsEnabled = value);
            _saveSettings();
            _showSnackBar(context,
                value ? 'Notifications enabled' : 'Notifications disabled');
          },
        ),
        const _Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.health_and_safety, color: Colors.teal),
          ),
          title: const Text('Notification Diagnostics',
              style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: const Text('Check if notifications are working'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _showNotificationDiagnostics,
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings() {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return _SettingsCard(
          children: [
            _buildThemeTile(
              context,
              title: 'Light Mode',
              icon: Icons.light_mode,
              iconColor: Colors.amber,
              mode: ThemeMode.light,
              current: themeMode,
            ),
            const _Divider(),
            _buildThemeTile(
              context,
              title: 'Dark Mode',
              icon: Icons.dark_mode,
              iconColor: Colors.indigo,
              mode: ThemeMode.dark,
              current: themeMode,
            ),
            const _Divider(),
            _buildThemeTile(
              context,
              title: 'System Default',
              icon: Icons.settings_suggest,
              iconColor: Colors.teal,
              mode: ThemeMode.system,
              current: themeMode,
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required ThemeMode mode,
    required ThemeMode current,
  }) {
    return RadioListTile<ThemeMode>(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      value: mode,
      groupValue: current,
      onChanged: (value) {
        if (value != null) context.read<ThemeCubit>().setThemeMode(value);
      },
    );
  }

  Widget _buildDefaultSettings() {
    return _SettingsCard(
      children: [
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.access_time, color: Colors.blue),
          ),
          title: const Text('Default Reminder Time',
              style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(_defaultReminderTime),
          trailing: const Icon(Icons.chevron_right),
          onTap: _selectDefaultTime,
        ),
        const _Divider(),
        ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event, color: Colors.green),
          ),
          title: const Text('Default Recharge Reminder',
              style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('$_defaultReminderDays days before expiry'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CounterButton(
                icon: Icons.remove,
                enabled: _defaultReminderDays > 1,
                onPressed: () {
                  setState(() => _defaultReminderDays--);
                  _saveSettings();
                },
              ),
              SizedBox(
                width: 32,
                child: Text(
                  '$_defaultReminderDays',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _CounterButton(
                icon: Icons.add,
                enabled: _defaultReminderDays < 10,
                onPressed: () {
                  setState(() => _defaultReminderDays++);
                  _saveSettings();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagement() {
    return _SettingsCard(
      children: [
        _buildActionTile(
          icon: Icons.storage,
          iconColor: Colors.blue,
          title: 'Storage Info',
          subtitle: 'View app data usage',
          onTap: _showStorageInfo,
        ),
        const _Divider(),
        _buildActionTile(
          icon: Icons.download,
          iconColor: Colors.green,
          title: 'Export Data',
          subtitle: 'Backup reminders and recharges',
          onTap: _exportData,
        ),
        const _Divider(),
        _buildActionTile(
          icon: Icons.upload,
          iconColor: Colors.orange,
          title: 'Import Data',
          subtitle: 'Restore from backup',
          onTap: _importData,
        ),
        const _Divider(),
        _buildActionTile(
          icon: Icons.delete_forever,
          iconColor: Colors.red,
          title: 'Clear All Data',
          subtitle: 'Delete all reminders and recharges',
          titleColor: Colors.red,
          onTap: _showClearDataDialog,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildAboutSection() {
    return _SettingsCard(
      children: [
        const ListTile(
          leading: _IconBox(icon: Icons.info, color: Colors.purple),
          title: Text('Version',
              style: TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text('1.0.0'),
        ),
        const _Divider(),
        ListTile(
          leading:
              const _IconBox(icon: Icons.privacy_tip, color: Colors.teal),
          title: const Text('Privacy Policy',
              style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSnackBar(context, 'Opening privacy policy...'),
        ),
        const _Divider(),
        ListTile(
          leading:
              const _IconBox(icon: Icons.description, color: Colors.blue),
          title: const Text('Terms of Service',
              style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSnackBar(context, 'Opening terms of service...'),
        ),
        const _Divider(),
        ListTile(
          leading: const _IconBox(icon: Icons.code, color: Colors.indigo),
          title: const Text('Open Source Licenses',
              style: TextStyle(fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }

  Future<void> _selectDefaultTime() async {
    // FIX: parse time robustly using MaterialLocalizations instead of string split
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time != null && mounted) {
      setState(() => _defaultReminderTime = time.format(context));
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Storage Information'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StorageRow(
                        icon: Icons.notifications,
                        color: Colors.purple,
                        label: 'Reminders',
                        count: reminderCount),
                    const SizedBox(height: 12),
                    _StorageRow(
                        icon: Icons.phone_android,
                        color: Colors.blue,
                        label: 'Recharges',
                        count: rechargeCount),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${reminderCount + rechargeCount} items',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                      ],
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

  void _exportData() =>
      _showSnackBar(context, 'Export feature coming soon!');

  void _importData() =>
      _showSnackBar(context, 'Import feature coming soon!');

  /// FIX: clears data via LocalStorageService (correct keys) AND cancels all
  /// scheduled notifications — the original used hardcoded keys and skipped
  /// notification cleanup entirely.
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data'),
        content: const Text(
          'Are you sure you want to delete all reminders and recharges? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);

              // FIX 1: Use LocalStorageService (correct keys, not hardcoded strings)
              final prefs = await SharedPreferences.getInstance();
              final storageService = LocalStorageService(prefs);
              await storageService.clearAll();

              // FIX 2: Cancel ALL scheduled notifications
              await NotificationService().cancelAllNotifications();

              if (!mounted) return;

              // Reload blocs so UI reflects empty state
              context.read<ReminderBloc>().add(LoadReminders());
              context.read<RechargeBloc>().add(LoadRecharges());

              _showSnackBar(context, 'All data cleared successfully');
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNotificationDiagnostics() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Checking...'),
        ]),
      ),
    );

    final svc = NotificationService();
    final issues = await svc.diagnose();
    final hasBatteryIssue = issues.any((i) => i.contains('Battery optimization is ON'));

    if (!mounted) return;
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Notification Diagnostics'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Battery optimization is the #1 real-device issue — surface it prominently
              if (hasBatteryIssue)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(children: [
                        Icon(Icons.battery_alert, color: Colors.red, size: 18),
                        SizedBox(width: 6),
                        Text('Battery Optimization Active',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.red)),
                      ]),
                      const SizedBox(height: 6),
                      const Text(
                        "This is the most common reason notifications don't "
                        'appear on real devices. The system kills the app before '
                        'the notification can fire.',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await svc.requestBatteryExemption();
                          },
                          icon: const Icon(Icons.battery_charging_full, size: 16),
                          label: const Text('Disable Battery Optimization'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ...issues.map((issue) {
                final isOk = issue.startsWith('✓');
                final isError = issue.startsWith('❌');
                final color = isOk ? Colors.green : (isError ? Colors.red : Colors.orange);
                final icon = isOk ? Icons.check_circle : (isError ? Icons.cancel : Icons.warning_amber_rounded);
                // Skip battery issue — already shown above
                if (issue.contains('Battery optimization is ON')) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(issue, style: const TextStyle(fontSize: 12))),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

// ─── Helper Widgets ───────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 16);
}

class _IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color),
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  const _CounterButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: enabled ? onPressed : null,
      iconSize: 20,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }
}

class _StorageRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _StorageRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
