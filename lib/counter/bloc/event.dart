part of 'bloc.dart';

abstract class CounterEvent extends Equatable {}

class InitEvent extends CounterEvent {
  @override
  List<Object?> get props => [true];
}

class IncomeExpenseEvent extends CounterEvent {
  IncomeExpenseEvent({
    required this.amount,
    this.category,
    this.description,
    this.title,
  }) : uuid = const Uuid().v1();

  final String uuid;
  final double amount;
  final String? title;
  final String? description;
  final CounterCategory? category;
  @override
  List<Object?> get props => [uuid];
}

class UpdateIncomeExpenseEvent extends CounterEvent {
  UpdateIncomeExpenseEvent({
    required this.uuid,
    this.amount,
    this.category,
    this.description,
    this.title,
  });

  final String uuid;
  final double? amount;
  final String? title;
  final String? description;
  final CounterCategory? category;
  @override
  List<Object?> get props => [uuid];
}

class RemoveEvent extends CounterEvent {
  RemoveEvent(this.uuid);
  final String uuid;

  @override
  List<Object?> get props => [uuid];
}

class ChangeDateFilter extends CounterEvent {
  ChangeDateFilter(this.dateFilter);
  final DateFilter dateFilter;

  @override
  List<Object?> get props => [dateFilter];
}

class CategoryUpdate extends CounterEvent {
  CategoryUpdate({required this.category});
  final CounterCategory category;

  @override
  List<Object?> get props => [category];
}

class CategoryDelete extends CounterEvent {
  CategoryDelete({required this.uuid});
  final String uuid;

  @override
  List<Object?> get props => [uuid];
}

class RestoreBackUp extends CounterEvent {
  RestoreBackUp({required this.list});
  final List<IncomeExpense> list;

  @override
  List<Object?> get props => [list];
}
