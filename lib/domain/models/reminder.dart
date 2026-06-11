import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ─── Reminder Model ───────────────────────────────────────────────────────────

class Reminder extends Equatable {
  final String id;
  final String title;
  final String? description;
  final DateTime dateTime;
  final ReminderCategory category;
  final RepeatType repeat;
  final bool isCompleted;
  final bool notificationEnabled;

  const Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.dateTime,
    this.category = ReminderCategory.other,
    this.repeat = RepeatType.none,
    this.isCompleted = false,
    this.notificationEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'category': category.index,
      'repeat': repeat.index,
      'isCompleted': isCompleted,
      'notificationEnabled': notificationEnabled,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dateTime: DateTime.parse(json['dateTime'] as String),
      category: ReminderCategory.values[json['category'] as int],
      repeat: RepeatType.values[json['repeat'] as int],
      isCompleted: json['isCompleted'] as bool,
      notificationEnabled: json['notificationEnabled'] as bool,
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dateTime,
    ReminderCategory? category,
    RepeatType? repeat,
    bool? isCompleted,
    bool? notificationEnabled,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateTime: dateTime ?? this.dateTime,
      category: category ?? this.category,
      repeat: repeat ?? this.repeat,
      isCompleted: isCompleted ?? this.isCompleted,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dateTime,
        category,
        repeat,
        isCompleted,
        notificationEnabled,
      ];
}

// ─── Mobile Recharge Model ────────────────────────────────────────────────────

class MobileRecharge extends Equatable {
  final String id;
  final String mobileNumber;
  final String operator;
  final double amount;
  final DateTime rechargeDate;
  final int validityDays;
  final DateTime expiryDate;
  final bool reminderEnabled;
  final int reminderDaysBefore;

  const MobileRecharge({
    required this.id,
    required this.mobileNumber,
    required this.operator,
    required this.amount,
    required this.rechargeDate,
    required this.validityDays,
    required this.expiryDate,
    this.reminderEnabled = true,
    this.reminderDaysBefore = 3,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mobileNumber': mobileNumber,
      'operator': operator,
      'amount': amount,
      'rechargeDate': rechargeDate.toIso8601String(),
      'validityDays': validityDays,
      'expiryDate': expiryDate.toIso8601String(),
      'reminderEnabled': reminderEnabled,
      'reminderDaysBefore': reminderDaysBefore,
    };
  }

  factory MobileRecharge.fromJson(Map<String, dynamic> json) {
    return MobileRecharge(
      id: json['id'] as String,
      mobileNumber: json['mobileNumber'] as String,
      operator: json['operator'] as String,
      amount: (json['amount'] as num).toDouble(), // FIX: safe num→double cast
      rechargeDate: DateTime.parse(json['rechargeDate'] as String),
      validityDays: json['validityDays'] as int,
      expiryDate: DateTime.parse(json['expiryDate'] as String),
      reminderEnabled: json['reminderEnabled'] as bool,
      reminderDaysBefore: json['reminderDaysBefore'] as int,
    );
  }

  // FIX: added copyWith (was missing from original)
  MobileRecharge copyWith({
    String? id,
    String? mobileNumber,
    String? operator,
    double? amount,
    DateTime? rechargeDate,
    int? validityDays,
    DateTime? expiryDate,
    bool? reminderEnabled,
    int? reminderDaysBefore,
  }) {
    return MobileRecharge(
      id: id ?? this.id,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      operator: operator ?? this.operator,
      amount: amount ?? this.amount,
      rechargeDate: rechargeDate ?? this.rechargeDate,
      validityDays: validityDays ?? this.validityDays,
      expiryDate: expiryDate ?? this.expiryDate,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
    );
  }

  /// Days remaining until expiry. Negative means expired.
  int get daysRemaining =>
      expiryDate.difference(DateTime.now()).inDays;

  /// True when expiry is between 0 and reminderDaysBefore days away (inclusive)
  bool get isExpiringSoon =>
      daysRemaining <= reminderDaysBefore && daysRemaining >= 0;

  bool get isExpired => daysRemaining < 0;

  /// Progress of consumed validity: 0.0 (just recharged) → 1.0 (expired).
  /// Clamped to [0, 1] so the progress bar never overflows.
  double get validityProgress {
    if (validityDays <= 0) return 1.0;
    final elapsed = validityDays - daysRemaining;
    return (elapsed / validityDays).clamp(0.0, 1.0); // FIX: clamped
  }

  @override
  List<Object?> get props => [
        id,
        mobileNumber,
        operator,
        amount,
        rechargeDate,
        validityDays,
        expiryDate,
        reminderEnabled,
        reminderDaysBefore,
      ];
}

// ─── Enums ────────────────────────────────────────────────────────────────────

enum ReminderCategory {
  personal,
  work,
  health,
  shopping,
  bills,
  other,
}

enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
}

// ─── Extensions ──────────────────────────────────────────────────────────────

extension ReminderCategoryExtension on ReminderCategory {
  String get displayName {
    switch (this) {
      case ReminderCategory.personal:
        return 'Personal';
      case ReminderCategory.work:
        return 'Work';
      case ReminderCategory.health:
        return 'Health';
      case ReminderCategory.shopping:
        return 'Shopping';
      case ReminderCategory.bills:
        return 'Bills';
      case ReminderCategory.other:
        return 'Other';
    }
  }

  // Keep backward compat — callers used `.name` which conflicts with Dart enum .name
  // Redirect to displayName
  String get name => displayName;

  IconData get icon {
    switch (this) {
      case ReminderCategory.personal:
        return Icons.person;
      case ReminderCategory.work:
        return Icons.work;
      case ReminderCategory.health:
        return Icons.local_hospital;
      case ReminderCategory.shopping:
        return Icons.shopping_cart;
      case ReminderCategory.bills:
        return Icons.receipt;
      case ReminderCategory.other:
        return Icons.info;
    }
  }

  Color get color {
    switch (this) {
      case ReminderCategory.personal:
        return Colors.blue;
      case ReminderCategory.work:
        return Colors.orange;
      case ReminderCategory.health:
        return Colors.red;
      case ReminderCategory.shopping:
        return Colors.green;
      case ReminderCategory.bills:
        return Colors.purple;
      case ReminderCategory.other:
        return Colors.grey;
    }
  }
}

extension RepeatTypeExtension on RepeatType {
  String get displayName {
    switch (this) {
      case RepeatType.none:
        return 'No Repeat';
      case RepeatType.daily:
        return 'Daily';
      case RepeatType.weekly:
        return 'Weekly';
      case RepeatType.monthly:
        return 'Monthly';
      case RepeatType.yearly:
        return 'Yearly';
    }
  }

  String get name => displayName;
}
