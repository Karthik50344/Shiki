import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shikokiroku/domain/models/reminder.dart';
import 'package:shikokiroku/presentation/views/widgets/reminder_action.dart';
import '../../bloc/reminder/reminder_bloc.dart';
import '../../bloc/recharge/recharge_bloc.dart';
import '../../router/app_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX: index is always 0 on HomeScreen — no state needed here because
      // each screen is its own route; index was wrong when returning from sub-routes
      body: const HomeTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              context.go(AppRouter.reminders);
              break;
            case 2:
              context.go(AppRouter.recharge);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Reminders',
          ),
          NavigationDestination(
            icon: Icon(Icons.phone_android_outlined),
            selectedIcon: Icon(Icons.phone_android),
            label: 'Recharge',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _AddOptionTile(
              icon: Icons.notifications,
              color: Colors.purple,
              title: 'Add Reminder',
              subtitle: 'Create a new reminder',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.addReminder);
              },
            ),
            const SizedBox(height: 10),
            _AddOptionTile(
              icon: Icons.phone_android,
              color: Colors.blue,
              title: 'Add Recharge',
              subtitle: 'Track mobile recharge',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.addRecharge);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          floating: false,
          pinned: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text(
            'Shiki',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                child: IconButton(
                  tooltip: 'Settings',
                  icon:
                      const Icon(Icons.settings_outlined, color: Colors.purple),
                  onPressed: () => context.push(AppRouter.settings),
                ),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/image/sakura.jfif',
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade900, Colors.purple.shade300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black54, Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Quick Stats'),
                const SizedBox(height: 12),
                _buildStatsSection(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Upcoming Reminders'),
                const SizedBox(height: 12),
                _buildUpcomingReminders(context),
                const SizedBox(height: 24),
                _buildSectionTitle('Recharge Status'),
                const SizedBox(height: 12),
                _buildRechargeStatus(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Icons.nightlight_round;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(greetingIcon, color: Colors.white, size: 36),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('EEEE, MMMM d').format(DateTime.now()),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, reminderState) {
        return BlocBuilder<RechargeBloc, RechargeState>(
          builder: (context, rechargeState) {
            int activeCount = 0, overdueCount = 0, expiringCount = 0;

            if (reminderState is ReminderLoaded) {
              activeCount = reminderState.activeReminders.length;
              overdueCount = reminderState.overdueReminders.length;
            }
            if (rechargeState is RechargeLoaded) {
              expiringCount = rechargeState.expiringSoonRecharges.length;
            }

            return Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Active',
                    value: activeCount,
                    icon: Icons.notifications_active,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Overdue',
                    value: overdueCount,
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Expiring',
                    value: expiringCount,
                    icon: Icons.phone_android,
                    color: Colors.red,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUpcomingReminders(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is ReminderLoaded) {
          final upcoming = state.activeReminders.take(3).toList();

          if (upcoming.isEmpty) {
            return _EmptyCard(
              icon: Icons.notifications_none,
              message: 'No upcoming reminders',
              actionLabel: 'Add Reminder',
              onAction: () => context.push(AppRouter.addReminder),
            );
          }

          return Column(
            children: upcoming.map((reminder) {
              return _ReminderCard(
                reminder: reminder,
                onEdit: () => ReminderActions.editReminder(context, reminder),
                onDelete: () =>
                    ReminderActions.quickDelete(context, reminder),
                onComplete: () =>
                    ReminderActions.toggleComplete(context, reminder),
                onTap: () =>
                    ReminderActions.showActionSheet(context, reminder),
              );
            }).toList(),
          );
        }

        return _EmptyCard(
          icon: Icons.notifications_none,
          message: 'No upcoming reminders',
          actionLabel: 'Add Reminder',
          onAction: () => context.push(AppRouter.addReminder),
        );
      },
    );
  }

  Widget _buildRechargeStatus(BuildContext context) {
    return BlocBuilder<RechargeBloc, RechargeState>(
      builder: (context, state) {
        if (state is RechargeLoaded) {
          final recharges = state.activeRecharges.take(3).toList();

          if (recharges.isEmpty) {
            return _EmptyCard(
              icon: Icons.phone_android_outlined,
              message: 'No active recharges',
              actionLabel: 'Add Recharge',
              onAction: () => context.push(AppRouter.addRecharge),
            );
          }

          return Column(
            children: recharges.map((recharge) {
              return _RechargeCard(recharge: recharge);
            }).toList(),
          );
        }

        return _EmptyCard(
          icon: Icons.phone_android_outlined,
          message: 'No active recharges',
          actionLabel: 'Add Recharge',
          onAction: () => context.push(AppRouter.addRecharge),
        );
      },
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _AddOptionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AddOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title:
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onComplete;
  final VoidCallback onTap;

  const _ReminderCard({
    required this.reminder,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: reminder.category.color.withValues(alpha: 0.15),
          child: Icon(reminder.category.icon, color: reminder.category.color),
        ),
        title: Text(
          reminder.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          DateFormat('MMM d, y · h:mm a').format(reminder.dateTime),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'delete') onDelete();
            if (value == 'complete') onComplete();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'edit',
                child: _MenuRow(icon: Icons.edit, label: 'Edit')),
            const PopupMenuItem(
                value: 'complete',
                child: _MenuRow(
                    icon: Icons.check_circle, label: 'Mark Complete')),
            const PopupMenuItem(
                value: 'delete',
                child: _MenuRow(
                    icon: Icons.delete, label: 'Delete', isDestructive: true)),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _RechargeCard extends StatelessWidget {
  final MobileRecharge recharge;

  const _RechargeCard({required this.recharge});

  @override
  Widget build(BuildContext context) {
    final isExpiringSoon = recharge.isExpiringSoon;
    final daysRemaining = recharge.daysRemaining;
    final statusColor = isExpiringSoon ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.15),
          child: Icon(Icons.phone_android, color: statusColor),
        ),
        title: Text(
          recharge.mobileNumber,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${recharge.operator} · ₹${recharge.amount}',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
        trailing: PopupMenuButton<String>(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$daysRemaining days',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                  fontSize: 13,
                ),
              ),
              Text(
                'remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'edit') {
              context.push(AppRouter.editRecharge, extra: recharge);
            } else if (value == 'delete') {
              RechargeActions.showActionSheet(context, recharge);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 'edit',
                child: _MenuRow(icon: Icons.edit, label: 'Edit')),
            const PopupMenuItem(
                value: 'delete',
                child: _MenuRow(
                    icon: Icons.delete, label: 'Delete', isDestructive: true)),
          ],
        ),
        onTap: () => RechargeActions.showActionSheet(context, recharge),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDestructive;

  const _MenuRow(
      {required this.icon, required this.label, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : null;
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _EmptyCard({
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
