import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shikokiroku/presentation/views/widgets/reminder_action.dart';
import '../../../domain/models/reminder.dart';
import '../../bloc/reminder/reminder_bloc.dart';
import '../../router/app_router.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // FIX: index is always 1 on RemindersScreen
      bottomNavigationBar: NavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) {
          if (index == 0) context.go(AppRouter.home);
          if (index == 2) context.go(AppRouter.recharge);
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
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar.large(
              title: const Text(
                'Reminders',
                style: TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.purple),
                onPressed: () => context.go(AppRouter.home),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.purple),
                  onPressed: () => _showSearchDialog(context),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.purple,
                labelColor: Colors.purple,
                tabs: const [
                  Tab(text: 'Active'),
                  Tab(text: 'Completed'),
                  Tab(text: 'Overdue'),
                ],
              ),
            ),
          ];
        },
        body: BlocListener<ReminderBloc, ReminderState>(
          listener: (context, state) {
            if (state is ReminderOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            } else if (state is ReminderError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            }
          },
          child: TabBarView(
            controller: _tabController,
            children: [
              _RemindersList(filter: ReminderFilter.active),
              _RemindersList(filter: ReminderFilter.completed),
              _RemindersList(filter: ReminderFilter.overdue),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.addReminder),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Add Reminder', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Search Reminders'),
        content: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter search query',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            context.read<ReminderBloc>().add(SearchReminders(value));
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<ReminderBloc>().add(LoadReminders());
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

enum ReminderFilter { active, completed, overdue }

// ─── Reminders List Widget ───────────────────────────────────────────────────

class _RemindersList extends StatelessWidget {
  final ReminderFilter filter;

  const _RemindersList({required this.filter});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReminderBloc, ReminderState>(
      builder: (context, state) {
        if (state is ReminderLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is ReminderLoaded) {
          final List<Reminder> reminders;
          switch (filter) {
            case ReminderFilter.active:
              reminders = state.activeReminders;
              break;
            case ReminderFilter.completed:
              reminders = state.completedReminders;
              break;
            case ReminderFilter.overdue:
              reminders = state.overdueReminders;
              break;
          }

          if (reminders.isEmpty) {
            return _EmptyState(filter: filter);
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: reminders.length,
            itemBuilder: (context, index) {
              return _ReminderCard(reminder: reminders[index]);
            },
          );
        }

        return _EmptyState(filter: filter);
      },
    );
  }
}

// ─── Reminder Card ────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final Reminder reminder;

  const _ReminderCard({required this.reminder});

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) =>
                ReminderActions.editReminder(context, reminder),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
          SlidableAction(
            onPressed: (_) =>
                ReminderActions.quickDelete(context, reminder),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: InkWell(
          onTap: () => ReminderActions.showActionSheet(context, reminder),
          onLongPress: () =>
              ReminderActions.showActionSheet(context, reminder),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Checkbox(
                    value: reminder.isCompleted,
                    onChanged: (value) {
                      context
                          .read<ReminderBloc>()
                          .add(ToggleReminderComplete(reminder.id));
                    },
                    shape: const CircleBorder(),
                    activeColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: reminder.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: reminder.isCompleted
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45)
                              : null,
                        ),
                      ),
                      if (reminder.description != null &&
                          reminder.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          reminder.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _CategoryBadge(category: reminder.category),
                          _TimeBadge(dateTime: reminder.dateTime),
                          if (reminder.repeat != RepeatType.none)
                            _RepeatBadge(repeat: reminder.repeat),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Badge Widgets ────────────────────────────────────────────────────────────

class _CategoryBadge extends StatelessWidget {
  final ReminderCategory category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: 12, color: category.color),
          const SizedBox(width: 4),
          Text(
            category.name,
            style: TextStyle(fontSize: 11, color: category.color),
          ),
        ],
      ),
    );
  }
}

class _TimeBadge extends StatelessWidget {
  final DateTime dateTime;

  const _TimeBadge({required this.dateTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            DateFormat('MMM d, h:mm a').format(dateTime),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatBadge extends StatelessWidget {
  final RepeatType repeat;

  const _RepeatBadge({required this.repeat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 12, color: Colors.purple),
          const SizedBox(width: 4),
          Text(
            repeat.name,
            style: const TextStyle(fontSize: 11, color: Colors.purple),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ReminderFilter filter;

  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final String message;
    switch (filter) {
      case ReminderFilter.active:
        icon = Icons.notifications_none;
        message = 'No active reminders';
        break;
      case ReminderFilter.completed:
        icon = Icons.check_circle_outline;
        message = 'No completed reminders';
        break;
      case ReminderFilter.overdue:
        icon = Icons.warning_amber_outlined;
        message = 'No overdue reminders — great job!';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 72,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
