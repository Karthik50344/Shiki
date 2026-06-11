import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/reminder.dart';
import '../../bloc/reminder/reminder_bloc.dart';
import '../../bloc/recharge/recharge_bloc.dart';
import '../../router/app_router.dart';

class ReminderActions {
  static void showActionSheet(BuildContext context, Reminder reminder) {
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
            _ActionTile(
              icon: Icons.edit,
              color: Colors.blue,
              title: 'Edit Reminder',
              subtitle: 'Modify reminder details',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.editReminder, extra: reminder);
              },
            ),
            const SizedBox(height: 6),
            _ActionTile(
              icon: reminder.isCompleted ? Icons.restart_alt : Icons.check_circle,
              color: reminder.isCompleted ? Colors.orange : Colors.green,
              title: reminder.isCompleted ? 'Mark as Active' : 'Mark as Complete',
              subtitle: reminder.isCompleted
                  ? 'Reactivate this reminder'
                  : 'Mark this reminder as done',
              onTap: () {
                Navigator.pop(context);
                context.read<ReminderBloc>().add(ToggleReminderComplete(reminder.id));
              },
            ),
            const SizedBox(height: 6),
            _ActionTile(
              icon: Icons.delete,
              color: Colors.red,
              title: 'Delete Reminder',
              subtitle: 'Remove this reminder permanently',
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, reminder);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showDeleteDialog(BuildContext context, Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Reminder'),
        content: Text(
          'Are you sure you want to delete "${reminder.title}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ReminderBloc>().add(DeleteReminder(reminder.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static void quickDelete(BuildContext context, Reminder reminder) {
    context.read<ReminderBloc>().add(DeleteReminder(reminder.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${reminder.title}" deleted'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            context.read<ReminderBloc>().add(AddReminder(reminder));
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void editReminder(BuildContext context, Reminder reminder) {
    context.push(AppRouter.editReminder, extra: reminder);
  }

  static void toggleComplete(BuildContext context, Reminder reminder) {
    context.read<ReminderBloc>().add(ToggleReminderComplete(reminder.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          reminder.isCompleted
              ? '"${reminder.title}" marked as active'
              : '"${reminder.title}" marked as complete',
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class RechargeActions {
  static void showActionSheet(BuildContext context, MobileRecharge recharge) {
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
            _ActionTile(
              icon: Icons.edit,
              color: Colors.blue,
              title: 'Edit Recharge',
              subtitle: 'Modify recharge details',
              onTap: () {
                Navigator.pop(context);
                context.push(AppRouter.editRecharge, extra: recharge);
              },
            ),
            const SizedBox(height: 6),
            _ActionTile(
              icon: Icons.delete,
              color: Colors.red,
              title: 'Delete Recharge',
              subtitle: 'Remove this recharge record',
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, recharge);
              },
            ),
          ],
        ),
      ),
    );
  }

  static void _showDeleteDialog(BuildContext context, MobileRecharge recharge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Recharge'),
        content: Text(
          'Are you sure you want to delete the recharge record for '
          '${recharge.mobileNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<RechargeBloc>().add(DeleteRecharge(recharge.id));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Shared tile widget ───────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
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
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6))),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      onTap: onTap,
    );
  }
}
