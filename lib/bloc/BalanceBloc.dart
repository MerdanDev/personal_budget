import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/helper/SharedPrefKeys.dart';
import 'package:personal_budget/models/tbl_mv_expense.dart';
import 'package:personal_budget/models/tbl_mv_income.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BalanceState extends Equatable {
  @override
  List<Object> get props => [];
}

class EmptyState extends BalanceState {}

class LoadingState extends BalanceState {}

class ErrorState extends BalanceState {}

class LoadedState extends BalanceState {}

// === === === === === === === === Events === === === === === === === ===

abstract class BalanceEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadEvent extends BalanceEvent {}

class AddIncomeEvent extends BalanceEvent {
  final TblMvIncome income;
  AddIncomeEvent({required this.income});
  @override
  List<Object> get props => [income];
}

class AddExpenseEvent extends BalanceEvent {
  final TblMvExpence expence;
  AddExpenseEvent({required this.expence});
  @override
  List<Object> get props => [expence];
}

// === === === === === === === === BLoC === === === === === === === ===

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  BalanceBloc() : super(EmptyState());
  Stream<BalanceState> mapEventToState(BalanceEvent event) async* {
    final _sharedPref = await SharedPreferences.getInstance();
    String accId =
        _sharedPref.getString(SharedPrefKeys.accId) ?? SharedPrefKeys.accId;
    if (event is LoadEvent) {}
  }
}
