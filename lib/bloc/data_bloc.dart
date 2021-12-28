import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/data/local/sqlite_db.dart';
import 'package:personal_budget/models/tbl_mv_acc_type.dart';
import 'package:personal_budget/models/tbl_mv_category.dart';
import 'package:personal_budget/models/tbl_mv_expense.dart';
import 'package:personal_budget/models/tbl_mv_income.dart';

/* === === === === === === === === States === === === === === === === === */

abstract class DataState extends Equatable {
  @override
  List<Object> get props => [];
}

class EmptyState extends DataState {}

class LoadingState extends DataState {}

class ErrorState extends DataState {}

class LoadedIncomeState extends DataState {
  final List<TblMvIncome> incomes;
  LoadedIncomeState({required this.incomes});
}

class LoadedExpenseState extends DataState {
  final List<TblMvExpense> expenses;
  LoadedExpenseState({required this.expenses});
}

/* === === === === === === === === Events === === === === === === === === */

abstract class DataEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadEvent extends DataEvent {
  final TblMvCategory category;
  final TblMvAccType account;
  LoadEvent({required this.category, required this.account});
}

/* === === === === === === === === BLoC === === === === === === === === */

class DataBloc extends Bloc<DataEvent, DataState> {
  DataBloc() : super(EmptyState());
  SqliteDB db = SqliteDB.instance;
  List<TblMvExpense> expenses = [];
  List<TblMvIncome> incomes = [];

  @override
  Stream<DataState> mapEventToState(DataEvent event) async* {
    yield LoadingState();
    if (event is LoadEvent) {
      if (event.category.type == -1) {
        expenses = await db.getCatExpenses(event.account.id, event.category.id);
        yield LoadedExpenseState(expenses: expenses);
      } else if (event.category.type == 1) {
        incomes = await db.getCatIncomes(event.account.id, event.category.id);
        yield LoadedIncomeState(incomes: incomes);
      }
    }
  }
}
