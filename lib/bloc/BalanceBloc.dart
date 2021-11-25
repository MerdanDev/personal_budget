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
  final double value;
  final int catId;
  final String text;
  AddIncomeEvent({
    required this.value,
    required this.catId,
    required this.text,
  });
  @override
  List<Object> get props => [value, catId, text];
}

class AddExpenseEvent extends BalanceEvent {
  final double value;
  final int catId;
  final String text;
  AddExpenseEvent({
    required this.value,
    required this.catId,
    required this.text,
  });
  @override
  List<Object> get props => [value, catId, text];
}

// === === === === === === === === BLoC === === === === === === === ===

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  BalanceBloc() : super(EmptyState());
  Stream<BalanceState> mapEventToState(BalanceEvent event) async* {
    final _sharedPref = await SharedPreferences.getInstance();
    String accId = _sharedPref.getString(SharedPrefKeys.accId) ??
        SharedPrefKeys.defaultAcc;
    yield LoadingState();
    if (event is LoadEvent) {}
  }
}
