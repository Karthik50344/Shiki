import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../domain/models/reminder.dart';
import '../../../data/repositories/reminder_repository.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class ReminderEvent extends Equatable {
  const ReminderEvent();
  @override
  List<Object?> get props => [];
}

class LoadReminders extends ReminderEvent {}

class AddReminder extends ReminderEvent {
  final Reminder reminder;
  const AddReminder(this.reminder);
  @override
  List<Object?> get props => [reminder];
}

class UpdateReminder extends ReminderEvent {
  final Reminder reminder;
  const UpdateReminder(this.reminder);
  @override
  List<Object?> get props => [reminder];
}

class DeleteReminder extends ReminderEvent {
  final String id;
  const DeleteReminder(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleReminderComplete extends ReminderEvent {
  final String id;
  const ToggleReminderComplete(this.id);
  @override
  List<Object?> get props => [id];
}

class SearchReminders extends ReminderEvent {
  final String query;
  const SearchReminders(this.query);
  @override
  List<Object?> get props => [query];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class ReminderState extends Equatable {
  const ReminderState();
  @override
  List<Object?> get props => [];
}

class ReminderInitial extends ReminderState {}

class ReminderLoading extends ReminderState {}

class ReminderLoaded extends ReminderState {
  final List<Reminder> reminders;
  final List<Reminder> activeReminders;
  final List<Reminder> completedReminders;
  final List<Reminder> overdueReminders;

  const ReminderLoaded({
    required this.reminders,
    required this.activeReminders,
    required this.completedReminders,
    required this.overdueReminders,
  });

  @override
  List<Object?> get props =>
      [reminders, activeReminders, completedReminders, overdueReminders];
}

class ReminderError extends ReminderState {
  final String message;
  const ReminderError(this.message);
  @override
  List<Object?> get props => [message];
}

class ReminderOperationSuccess extends ReminderState {
  final String message;
  const ReminderOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class ReminderBloc extends Bloc<ReminderEvent, ReminderState> {
  final ReminderRepository repository;

  ReminderBloc(this.repository) : super(ReminderInitial()) {
    on<LoadReminders>(_onLoadReminders);
    on<AddReminder>(_onAddReminder);
    on<UpdateReminder>(_onUpdateReminder);
    on<DeleteReminder>(_onDeleteReminder);
    on<ToggleReminderComplete>(_onToggleReminderComplete);
    on<SearchReminders>(_onSearchReminders);
  }

  Future<void> _onLoadReminders(
    LoadReminders event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      emit(ReminderLoading());
      final reminders = await repository.getAllReminders();
      final activeReminders = await repository.getActiveReminders();
      final completedReminders = await repository.getCompletedReminders();
      final overdueReminders = await repository.getOverdueReminders();
      emit(ReminderLoaded(
        reminders: reminders,
        activeReminders: activeReminders,
        completedReminders: completedReminders,
        overdueReminders: overdueReminders,
      ));
    } catch (e) {
      emit(ReminderError('Failed to load reminders: $e'));
    }
  }

  Future<void> _onAddReminder(
    AddReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final success = await repository.addReminder(event.reminder);
      if (success) {
        emit(const ReminderOperationSuccess('Reminder added successfully'));
        add(LoadReminders());
      } else {
        emit(const ReminderError('Failed to add reminder'));
      }
    } catch (e) {
      emit(ReminderError('Failed to add reminder: $e'));
    }
  }

  Future<void> _onUpdateReminder(
    UpdateReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final success = await repository.updateReminder(event.reminder);
      if (success) {
        emit(const ReminderOperationSuccess('Reminder updated successfully'));
        add(LoadReminders());
      } else {
        emit(const ReminderError('Failed to update reminder'));
      }
    } catch (e) {
      emit(ReminderError('Failed to update reminder: $e'));
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminder event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final success = await repository.deleteReminder(event.id);
      if (success) {
        emit(const ReminderOperationSuccess('Reminder deleted successfully'));
        add(LoadReminders());
      } else {
        emit(const ReminderError('Failed to delete reminder'));
      }
    } catch (e) {
      emit(ReminderError('Failed to delete reminder: $e'));
    }
  }

  Future<void> _onToggleReminderComplete(
    ToggleReminderComplete event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      final reminders = await repository.getAllReminders();

      // FIX: original used firstWhere with no orElse — throws StateError if id
      // not found (e.g. rapid double-tap or stale UI). Use firstWhereOrNull
      // pattern instead so we fail gracefully.
      final reminder = reminders.cast<Reminder?>().firstWhere(
            (r) => r?.id == event.id,
            orElse: () => null,
          );

      if (reminder == null) {
        emit(const ReminderError('Reminder not found'));
        return;
      }

      final updated = reminder.copyWith(isCompleted: !reminder.isCompleted);
      final success = await repository.updateReminder(updated);

      if (success) {
        add(LoadReminders());
      } else {
        emit(const ReminderError('Failed to toggle reminder'));
      }
    } catch (e) {
      emit(ReminderError('Failed to toggle reminder: $e'));
    }
  }

  Future<void> _onSearchReminders(
    SearchReminders event,
    Emitter<ReminderState> emit,
  ) async {
    try {
      emit(ReminderLoading());
      final reminders = await repository.searchReminders(event.query);
      final now = DateTime.now();
      emit(ReminderLoaded(
        reminders: reminders,
        activeReminders: reminders
            .where((r) => !r.isCompleted && r.dateTime.isAfter(now))
            .toList(),
        completedReminders: reminders.where((r) => r.isCompleted).toList(),
        overdueReminders: reminders
            .where((r) => !r.isCompleted && r.dateTime.isBefore(now))
            .toList(),
      ));
    } catch (e) {
      emit(ReminderError('Failed to search reminders: $e'));
    }
  }
}
