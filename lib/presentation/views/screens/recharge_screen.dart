import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shikokiroku/presentation/views/widgets/reminder_action.dart';
import '../../../domain/models/reminder.dart';
import '../../bloc/recharge/recharge_bloc.dart';
import '../../router/app_router.dart';

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: 2,
        onDestinationSelected: (index) {
          if (index == 0) context.go(AppRouter.home);
          if (index == 1) context.go(AppRouter.reminders);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Reminders'),
          NavigationDestination(icon: Icon(Icons.phone_android_outlined), selectedIcon: Icon(Icons.phone_android), label: 'Recharge'),
        ],
      ),
      body: BlocListener<RechargeBloc, RechargeState>(
        listener: (context, state) {
          if (state is RechargeOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          } else if (state is RechargeError) {
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
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text(
                'Mobile Recharge',
                style: TextStyle(
                    color: Colors.purple, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.purple),
                onPressed: () => context.go(AppRouter.home),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.purple),
                  tooltip: 'Recharge History',
                  onPressed: () => context.push(AppRouter.rechargeHistory),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCards(context),
                    const SizedBox(height: 24),
                    const Text(
                      'Active Recharges',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildRechargesList(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRouter.addRecharge),
        backgroundColor: Colors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Add Recharge', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context) {
    return BlocBuilder<RechargeBloc, RechargeState>(
      builder: (context, state) {
        int expiringSoon = 0, expired = 0, active = 0;

        if (state is RechargeLoaded) {
          expiringSoon = state.expiringSoonRecharges.length;
          expired = state.expiredRecharges.length;
          active = state.activeRecharges.length;
        }

        return Row(
          children: [
            Expanded(
              child: _SummaryCard(
                label: 'Active',
                value: active,
                icon: Icons.phone_android,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Expiring',
                value: expiringSoon,
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                label: 'Expired',
                value: expired,
                icon: Icons.error_outline,
                color: Colors.red,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRechargesList(BuildContext context) {
    return BlocBuilder<RechargeBloc, RechargeState>(
      builder: (context, state) {
        if (state is RechargeLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is RechargeLoaded) {
          final recharges = state.activeRecharges;

          if (recharges.isEmpty) {
            return SliverFillRemaining(
              child: _EmptyRechargeState(),
            );
          }

          return SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) =>
                    _buildRechargeCard(context, recharges[index]),
                childCount: recharges.length,
              ),
            ),
          );
        }

        return const SliverFillRemaining(
          child: Center(child: Text('Unable to load recharges')),
        );
      },
    );
  }

  Widget _buildRechargeCard(BuildContext context, MobileRecharge recharge) {
    final daysRemaining = recharge.daysRemaining;
    final isExpiringSoon = recharge.isExpiringSoon;
    // FIX: use model's clamped validityProgress instead of raw inline calc
    final progressValue = recharge.validityProgress;

    Color statusColor = Colors.green;
    if (isExpiringSoon) statusColor = Colors.orange;
    if (recharge.isExpired) statusColor = Colors.red;

    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) =>
                context.push(AppRouter.editRecharge, extra: recharge),
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
                RechargeActions.showActionSheet(context, recharge),
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
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: InkWell(
          onTap: () => _showRechargeDetails(context, recharge),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.phone_android,
                          color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recharge.mobileNumber,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _OperatorBadge(operator: recharge.operator),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${recharge.amount.toStringAsFixed(recharge.amount.truncateToDouble() == recharge.amount ? 0 : 2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            recharge.isExpired
                                ? 'Expired'
                                : '$daysRemaining days left',
                            style: TextStyle(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Validity Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${(progressValue * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressValue,
                        minHeight: 7,
                        backgroundColor: statusColor.withValues(alpha: 0.15),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date chips row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: DateFormat('MMM d, y')
                          .format(recharge.rechargeDate),
                      prefix: 'Recharged',
                    ),
                    _InfoChip(
                      icon: Icons.event,
                      label:
                          DateFormat('MMM d, y').format(recharge.expiryDate),
                      prefix: 'Expires',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRechargeDetails(BuildContext context, MobileRecharge recharge) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) => _RechargeDetailSheet(recharge: recharge),
    );
  }
}

// ─── Supporting Widgets ───────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
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
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _OperatorBadge extends StatelessWidget {
  final String operator;

  const _OperatorBadge({required this.operator});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        operator,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String prefix;

  const _InfoChip(
      {required this.icon, required this.label, required this.prefix});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 13,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: 4),
        Text(
          '$prefix: $label',
          style: TextStyle(
            fontSize: 11,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _EmptyRechargeState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_android_outlined,
            size: 72,
            color:
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'No active recharges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your mobile recharges here',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _RechargeDetailSheet extends StatelessWidget {
  final MobileRecharge recharge;

  const _RechargeDetailSheet({required this.recharge});

  @override
  Widget build(BuildContext context) {
    final statusColor = recharge.isExpired
        ? Colors.red
        : (recharge.isExpiringSoon ? Colors.orange : Colors.green);
    final statusText = recharge.isExpired
        ? 'This recharge has expired'
        : (recharge.isExpiringSoon
            ? 'Expiring soon! Recharge now.'
            : 'Recharge is active');
    final statusIcon = recharge.isExpired
        ? Icons.error
        : (recharge.isExpiringSoon ? Icons.warning : Icons.check_circle);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recharge Details',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () {
                    Navigator.pop(context);
                    context.push(AppRouter.editRecharge, extra: recharge);
                  },
                  tooltip: 'Edit',
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    statusText,
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow('Mobile Number', recharge.mobileNumber),
            _DetailRow('Operator', recharge.operator),
            _DetailRow('Amount', '₹${recharge.amount}'),
            _DetailRow('Recharge Date',
                DateFormat('MMM d, y').format(recharge.rechargeDate)),
            _DetailRow('Validity', '${recharge.validityDays} days'),
            _DetailRow('Expiry Date',
                DateFormat('MMM d, y').format(recharge.expiryDate)),
            _DetailRow(
              'Days Remaining',
              recharge.isExpired ? 'Expired' : '${recharge.daysRemaining} days',
            ),
            _DetailRow(
              'Reminder',
              recharge.reminderEnabled
                  ? '${recharge.reminderDaysBefore} days before'
                  : 'Disabled',
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color:
                  Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
