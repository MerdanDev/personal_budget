import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/data/local/sqlite_db.dart';
import 'package:personal_budget/helper/shared_pref_keys.dart';
import 'package:personal_budget/models/tbl_mv_acc_type.dart';
import 'package:personal_budget/models/tbl_mv_category.dart';
import 'package:personal_budget/models/tbl_mv_expense.dart';
import 'package:personal_budget/models/tbl_mv_income.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* === === === === === === === === Statesa === === === === === === === === */
abstract class BalanceState extends Equatable {
  @override
  List<Object> get props => [];
}

class EmptyState extends BalanceState {}

class LoadingState extends BalanceState {}

class ErrorState extends BalanceState {}

class LoadedState extends BalanceState {
  final List<TblMvExpense> expenses;
  final List<TblMvIncome> incomes;
  final List<TblMvCategory> categories;
  final List<TblMvAccType> accounts;
  LoadedState({
    required this.accounts,
    required this.categories,
    required this.expenses,
    required this.incomes,
  });
}

/* === === === === === === === === Events === === === === === === === === */

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

/* === === === === === === === === BLoC === === === === === === === === */

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  BalanceBloc() : super(EmptyState());

  List<TblMvExpense> expenses = [];
  List<TblMvIncome> incomes = [];
  List<TblMvCategory> categories = [];
  List<TblMvAccType> accounts = [];

  Stream<BalanceState> mapEventToState(BalanceEvent event) async* {
    final _sharedPref = await SharedPreferences.getInstance();
    int accId =
        _sharedPref.getInt(SharedPrefKeys.accId) ?? SharedPrefKeys.defaultAcc;
    yield LoadingState();
    if (event is LoadEvent) {
      expenses = await SqliteDB.getAccExpenses(accId);
      incomes = await SqliteDB.getAccIncomes(accId);
      categories = await SqliteDB.getCategories();
      accounts = await SqliteDB.getAccounts();

      yield LoadedState(
        accounts: accounts,
        categories: categories,
        expenses: expenses,
        incomes: incomes,
      );
    }
  }
}
