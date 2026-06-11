import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/models/reminder.dart';
import '../../bloc/recharge/recharge_bloc.dart';

class AddRechargeScreen extends StatefulWidget {
  final MobileRecharge? recharge;

  const AddRechargeScreen({super.key, this.recharge});

  @override
  State<AddRechargeScreen> createState() => _AddRechargeScreenState();
}

class _AddRechargeScreenState extends State<AddRechargeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _mobileController;
  late TextEditingController _amountController;
  late TextEditingController _validityController;

  late String _selectedOperator;
  late DateTime _rechargeDate;
  late bool _reminderEnabled;
  late int _reminderDaysBefore;

  final List<String> _operators = [
    'Jio',
    'Airtel',
    'Vi (Vodafone Idea)',
    'BSNL',
    'MTNL',
    'Other',
  ];

  bool get _isEditing => widget.recharge != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _mobileController =
          TextEditingController(text: widget.recharge!.mobileNumber);
      _amountController =
          TextEditingController(text: widget.recharge!.amount.toString());
      _validityController =
          TextEditingController(text: widget.recharge!.validityDays.toString());
      _selectedOperator = widget.recharge!.operator;
      _rechargeDate = widget.recharge!.rechargeDate;
      _reminderEnabled = widget.recharge!.reminderEnabled;
      _reminderDaysBefore = widget.recharge!.reminderDaysBefore;
    } else {
      _mobileController = TextEditingController();
      _amountController = TextEditingController();
      _validityController = TextEditingController();
      _selectedOperator = _operators.first;
      _rechargeDate = DateTime.now();
      _reminderEnabled = true;
      _reminderDaysBefore = 3;
    }
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _amountController.dispose();
    _validityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Recharge' : 'Add Recharge',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saveRecharge,
            child: const Text('Save',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
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
            context.pop();
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
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // ── Mobile Number ───────────────────────────────────────────────
              TextFormField(
                controller: _mobileController,
                decoration: InputDecoration(
                  labelText: 'Mobile Number',
                  hintText: 'Enter 10-digit mobile number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.length != 10) {
                    return 'Mobile number must be 10 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Operator ────────────────────────────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedOperator,
                decoration: InputDecoration(
                  labelText: 'Operator',
                  prefixIcon: const Icon(Icons.sim_card),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                borderRadius: BorderRadius.circular(12),
                items: _operators.map((operator) {
                  return DropdownMenuItem(
                    value: operator,
                    child: Text(operator),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedOperator = value!);
                },
              ),
              const SizedBox(height: 14),

              // ── Amount ──────────────────────────────────────────────────────
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Recharge Amount',
                  hintText: 'Enter amount in ₹',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter recharge amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Recharge Date ───────────────────────────────────────────────
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Recharge Date'),
                  subtitle: Text(
                      DateFormat('EEEE, MMMM d, y').format(_rechargeDate)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 14),

              // ── Validity Days ───────────────────────────────────────────────
              TextFormField(
                controller: _validityController,
                decoration: InputDecoration(
                  labelText: 'Validity (Days)',
                  hintText: 'Enter validity in days',
                  prefixIcon: const Icon(Icons.event_available),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter validity days';
                  }
                  final days = int.tryParse(value);
                  if (days == null || days <= 0) {
                    return 'Please enter valid days';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // ── Expiry Info Card ─────────────────────────────────────────────
              if (_validityController.text.isNotEmpty &&
                  int.tryParse(_validityController.text) != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry Date',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat('EEEE, MMMM d, y')
                                  .format(_calculateExpiryDate()),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // ── Reminder Warning ─────────────────────────────────────────────
              // FIX: Warn when reminderDaysBefore >= validityDays.
              // In this case the reminder date would be before the recharge date
              // (or in the past), so the notification would be silently skipped.
              Builder(builder: (context) {
                final validity = int.tryParse(_validityController.text) ?? 0;
                if (_reminderEnabled &&
                    validity > 0 &&
                    _reminderDaysBefore >= validity) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Reminder is set to $_reminderDaysBefore days before expiry, '
                              'but validity is only $validity days. '
                              'Reduce the reminder days or the notification will fire immediately.',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),

              // ── Reminder Settings ────────────────────────────────────────────
              const Text(
                'Reminder Settings',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Reminder',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: const Text('Get notified before expiry'),
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications,
                            color: Colors.purple),
                      ),
                      value: _reminderEnabled,
                      onChanged: (value) {
                        setState(() => _reminderEnabled = value);
                      },
                    ),
                    if (_reminderEnabled) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Remind me before expiry',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.purple
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_reminderDaysBefore days',
                                    style: const TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _reminderDaysBefore.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: '$_reminderDaysBefore days',
                              activeColor: Colors.purple,
                              onChanged: (value) {
                                setState(
                                    () => _reminderDaysBefore = value.toInt());
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Save Button ───────────────────────────────────────────────
              FilledButton.icon(
                onPressed: _saveRecharge,
                icon: const Icon(Icons.save),
                label:
                    Text(_isEditing ? 'Update Recharge' : 'Add Recharge'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime _calculateExpiryDate() {
    final days = int.tryParse(_validityController.text) ?? 0;
    return _rechargeDate.add(Duration(days: days));
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _rechargeDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(), // recharge date can't be in the future
    );
    if (picked != null) {
      setState(() => _rechargeDate = picked);
    }
  }

  void _saveRecharge() {
    if (!_formKey.currentState!.validate()) return;

    final validityDays = int.parse(_validityController.text);
    final expiryDate = _rechargeDate.add(Duration(days: validityDays));

    final recharge = MobileRecharge(
      id: _isEditing ? widget.recharge!.id : const Uuid().v4(),
      mobileNumber: _mobileController.text,
      operator: _selectedOperator,
      amount: double.parse(_amountController.text),
      rechargeDate: _rechargeDate,
      validityDays: validityDays,
      expiryDate: expiryDate,
      reminderEnabled: _reminderEnabled,
      reminderDaysBefore: _reminderDaysBefore,
    );

    if (_isEditing) {
      context.read<RechargeBloc>().add(UpdateRecharge(recharge));
    } else {
      context.read<RechargeBloc>().add(AddRecharge(recharge));
    }
  }
}
