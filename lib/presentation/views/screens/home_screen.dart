import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shiki/domain/models/reminder.dart';
import 'package:shiki/presentation/views/widgets/reminder_action.dart';
import '../../bloc/reminder/reminder_bloc.dart';
import '../../bloc/recharge/recharge_bloc.dart';
import '../../router/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.reminders);
        break;
      case 2:
        context.go(AppRouter.recharge);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const HomeTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
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
        icon: const Icon(Icons.add, color: Colors.white,),
        label: const Text("Add", style: TextStyle(color: Colors.white),),
      ),
    );
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.notifications, color: Colors.purple),
              ),
              title: const Text('Add Reminder'),
              subtitle: const Text('Create a new reminder'),
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.addReminder);
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_android, color: Colors.blue),
              ),
              title: const Text('Add Recharge'),
              subtitle: const Text('Track mobile recharge'),
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
    String gifPath = 'assets/image/sakura.jfif';
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          floating: false,
          pinned: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text('Shiki', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
          actions: [
            Container(
              height: 40,
              width: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey
              ),
              child: IconButton(
                tooltip: "Settings",
                icon: const Icon(Icons.settings_outlined, color: Colors.purple,),
                onPressed: () => context.push(AppRouter.settings),
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  gifPath,
                  fit: BoxFit.cover,
                  gaplessPlayback: true, // prevents flicker
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
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(context),
                const SizedBox(height: 20),
                const Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildStatsSection(context),
                const SizedBox(height: 24),
                const Text(
                  'Upcoming Reminders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildUpcomingReminders(context),
                const SizedBox(height: 24),
                const Text(
                  'Recharge Status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildRechargeStatus(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good Morning';
    IconData greetingIcon = Icons.wb_sunny;

    if (hour >= 12 && hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour >= 17) {
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(greetingIcon, color: Colors.white, size: 32),
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
            int activeCount = 0;
            int overdueCount = 0;
            int expiringCount = 0;

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
                  child: _buildStatCard(
                    context,
                    'Active',
                    activeCount.toString(),
                    Icons.notifications_active,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Overdue',
                    overdueCount.toString(),
                    Icons.warning,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Expiring',
                    expiringCount.toString(),
                    Icons.phone_android,
                    Colors.red,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
      BuildContext context,
      String label,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingReminders(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is ReminderLoaded) {
          final upcomingReminders = state.activeReminders.take(3).toList();

          if (upcomingReminders.isEmpty) {
            return _buildEmptyState(
              context,
              'No upcoming reminders',
              Icons.notifications_none,
            );
          }

          return Column(
            children: upcomingReminders.map((reminder) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: reminder.category.color.withOpacity(0.2),
                    child: Icon(
                      reminder.category.icon,
                      color: reminder.category.color,
                    ),
                  ),
                  title: Text(reminder.title),
                  subtitle: Text(
                    DateFormat('MMM d, y - h:mm a').format(reminder.dateTime),
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        ReminderActions.editReminder(context, reminder);
                      } else if (value == 'delete') {
                        ReminderActions.quickDelete(context, reminder);
                      } else if (value == 'complete') {
                        ReminderActions.toggleComplete(context, reminder);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'complete',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20),
                            SizedBox(width: 8),
                            Text('Mark Complete'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => ReminderActions.showActionSheet(context, reminder),
                ),
              );
            }).toList(),
          );
        }

        return _buildEmptyState(
          context,
          'No upcoming reminders',
          Icons.notifications_none,
        );
      },
    );
  }

  Widget _buildRechargeStatus(BuildContext context) {
    return BlocBuilder<RechargeBloc, RechargeState>(
      builder: (context, state) {
        if (state is RechargeLoaded) {
          final recharges = state.activeRecharges;

          if (recharges.isEmpty) {
            return _buildEmptyState(
              context,
              'No active recharges',
              Icons.phone_android_outlined,
            );
          }

          return Column(
            children: recharges.take(3).map((recharge) {
              final isExpiringSoon = recharge.isExpiringSoon;
              final daysRemaining = recharge.daysRemaining;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isExpiringSoon
                        ? Colors.red.withOpacity(0.2)
                        : Colors.green.withOpacity(0.2),
                    child: Icon(
                      Icons.phone_android,
                      color: isExpiringSoon ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(recharge.mobileNumber),
                  subtitle: Text('${recharge.operator} - ₹${recharge.amount}'),
                  trailing: PopupMenuButton(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$daysRemaining days',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpiringSoon ? Colors.red : Colors.green,
                          ),
                        ),
                        Text(
                          'remaining',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
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
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => RechargeActions.showActionSheet(context, recharge),
                ),
              );
            }).toList(),
          );
        }

        return _buildEmptyState(
          context,
          'No active recharges',
          Icons.phone_android_outlined,
        );
      },
    );
  }

  Widget _buildEmptyState(
      BuildContext context, String message, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}