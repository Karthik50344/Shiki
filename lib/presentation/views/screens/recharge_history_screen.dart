import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/reminder.dart';
import '../../bloc/recharge/recharge_bloc.dart';
import '../../router/app_router.dart';

class RechargeHistoryScreen extends StatelessWidget {
  const RechargeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recharge History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: BlocBuilder<RechargeBloc, RechargeState>(
        builder: (context, state) {
          if (state is RechargeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RechargeLoaded) {
            final allRecharges = state.recharges;
            if (allRecharges.isEmpty) return _buildEmptyState(context);

            final activeRecharges =
                allRecharges.where((r) => !r.isExpired).toList();
            final expiredRecharges =
                allRecharges.where((r) => r.isExpired).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (activeRecharges.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Active Recharges',
                    icon: Icons.check_circle,
                    color: Colors.green,
                    count: activeRecharges.length,
                  ),
                  const SizedBox(height: 10),
                  ...activeRecharges.map(
                      (r) => _RechargeHistoryCard(recharge: r, isExpired: false)),
                  const SizedBox(height: 20),
                ],
                if (expiredRecharges.isNotEmpty) ...[
                  _SectionHeader(
                    title: 'Expired Recharges',
                    icon: Icons.history,
                    color: Colors.grey,
                    count: expiredRecharges.length,
                  ),
                  const SizedBox(height: 10),
                  ...expiredRecharges.map(
                      (r) => _RechargeHistoryCard(recharge: r, isExpired: true)),
                ],
              ],
            );
          }

          return _buildEmptyState(context);
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 72,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'No recharge history',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recharge records will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push(AppRouter.addRecharge),
            icon: const Icon(Icons.add),
            label: const Text('Add First Recharge'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Recharge History Card ────────────────────────────────────────────────────

class _RechargeHistoryCard extends StatelessWidget {
  final MobileRecharge recharge;
  final bool isExpired;

  const _RechargeHistoryCard({
    required this.recharge,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isExpired
        ? Colors.grey
        : (recharge.isExpiringSoon ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: statusColor.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: () => _showRechargeDetails(context, recharge),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.phone_android,
                    color: statusColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recharge.mobileNumber,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${recharge.operator} · ₹${recharge.amount}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat('MMM d, y').format(recharge.rechargeDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      isExpired
                          ? 'Expired'
                          : (recharge.isExpiringSoon ? 'Expiring' : 'Active'),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${recharge.validityDays}d validity',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRechargeDetails(BuildContext context, MobileRecharge recharge) {
    final statusColor = recharge.isExpired
        ? Colors.red
        : (recharge.isExpiringSoon ? Colors.orange : Colors.green);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recharge Details',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
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
            const SizedBox(height: 12),
            // Status banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    recharge.isExpired
                        ? Icons.error
                        : (recharge.isExpiringSoon
                            ? Icons.warning
                            : Icons.check_circle),
                    color: statusColor,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    recharge.isExpired
                        ? 'This recharge has expired'
                        : (recharge.isExpiringSoon
                            ? 'Expiring soon! Recharge now.'
                            : 'Recharge is active'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: statusColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
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
