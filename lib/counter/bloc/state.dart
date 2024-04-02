part of 'bloc.dart';

class CounterState extends Equatable {
  const CounterState({
    required this.data,
    required this.dateFilter,
    required this.loading,
  });

  final List<IncomeExpense> data;
  final DateFilter dateFilter;
  final bool loading;

  @override
  List<Object?> get props => [data, dateFilter, loading];
}
