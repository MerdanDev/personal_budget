part of 'bloc.dart';

class CounterState extends Equatable {
  const CounterState({
    required this.data,
    required this.dateFilter,
    required this.loading,
    this.searchQuery = '',
  });

  final List<IncomeExpense> data;
  final DateFilter dateFilter;
  final bool loading;

  /// The active free-text search query. Empty means no search is applied.
  final String searchQuery;

  @override
  List<Object?> get props => [data, dateFilter, loading, searchQuery];
}
