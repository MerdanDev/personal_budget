import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/data/local/sqlite_db.dart';
import 'package:personal_budget/helper/shared_pref_keys.dart';
import 'package:personal_budget/models/tbl_mv_acc_type.dart';
import 'package:personal_budget/models/tbl_mv_category.dart';
import 'package:personal_budget/models/tbl_mv_expense.dart';
import 'package:personal_budget/models/tbl_mv_income.dart';
import 'package:shared_preferences/shared_preferences.dart';

/* === === === === === === === === States === === === === === === === === */
abstract class BalanceState extends Equatable {
  @override
  List<Object> get props => [];
}

class EmptyState extends BalanceState {}

class LoadingState extends BalanceState {}

class ErrorState extends BalanceState {}

class LoadedState extends BalanceState {
  final List<TblMvCategory> categories;
  final List<TblMvAccType> accounts;
  final List<TempCat> expenseCats;
  final List<TempCat> incomeCats;
  final TblMvAccType account;
  LoadedState({
    required this.accounts,
    required this.categories,
    required this.expenseCats,
    required this.incomeCats,
    required this.account,
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

  final int accId;
  final int catId;
  final String text;
  AddIncomeEvent({
    required this.value,
    required this.catId,
    required this.accId,
    required this.text,
  });
  @override
  List<Object> get props => [value, catId, text];
}

class AddExpenseEvent extends BalanceEvent {
  final double value;
  final int catId;
  final int accId;
  final String text;
  AddExpenseEvent({
    required this.value,
    required this.catId,
    required this.accId,
    required this.text,
  });
  @override
  List<Object> get props => [value, catId, text];
}

/* === === === === === === === === BLoC === === === === === === === === */

class BalanceBloc extends Bloc<BalanceEvent, BalanceState> {
  BalanceBloc() : super(EmptyState());
  SqliteDB db = SqliteDB.instance;

  List<TblMvExpense> expenses = [];
  List<TblMvIncome> incomes = [];
  List<TblMvCategory> categories = [];
  List<TblMvAccType> accounts = [];
  List<TempCat> expenceCats = [];
  List<TempCat> incomeCats = [];

  Stream<BalanceState> _mapLoadedToState(BalanceEvent event) async* {
    final _sharedPref = await SharedPreferences.getInstance();
    int accId =
        _sharedPref.getInt(SharedPrefKeys.accId) ?? SharedPrefKeys.defaultAcc;
    TblMvAccType account =
        accounts.firstWhere((element) => element.id == accId);
    yield LoadedState(
      accounts: accounts,
      categories: categories,
      incomeCats: incomeCats,
      expenseCats: expenceCats,
      account: account,
    );
  }

  @override
  Stream<BalanceState> mapEventToState(BalanceEvent event) async* {
    final _sharedPref = await SharedPreferences.getInstance();
    int accId =
        _sharedPref.getInt(SharedPrefKeys.accId) ?? SharedPrefKeys.defaultAcc;
    yield LoadingState();
    if (event is LoadEvent) {
      expenses = await db.getAccExpenses(accId);
      incomes = await db.getAccIncomes(accId);
      categories = await db.getCategories();
      accounts = await db.getAccounts();
      expenceCats = categories.where((element) => element.type == -1).map((e) {
        double value = 0;
        if (expenses.isNotEmpty) {
          for (var item in expenses) {
            if (item.categoryId == e.id) {
              value += item.value;
            }
          }
        }
        return TempCat(name: e.name, type: e.type, value: value);
      }).toList();

      incomeCats = categories.where((element) => element.type == 1).map((e) {
        double value = 0;
        if (incomes.isNotEmpty) {
          for (var item in incomes) {
            if (item.categoryId == e.id) {
              value += item.value;
            }
          }
        }
        return TempCat(name: e.name, type: e.type, value: value);
      }).toList();

      yield* _mapLoadedToState(event);
    } else if (event is AddExpenseEvent) {
      int result = await db.insertExpense(
        TblMvExpense(
          id: 0,
          categoryId: event.catId,
          accId: event.accId,
          value: event.value,
          desc: event.text,
          createdDate: DateTime.now(),
          modifiedDate: DateTime.now(),
        ),
      );
      print('MerdanDev insertExpense result is $result');
      expenses = await db.getAccExpenses(accId);
      expenceCats = categories.where((element) => element.type == -1).map((e) {
        double value = 0;
        if (expenses.isNotEmpty) {
          for (var item in expenses) {
            if (item.categoryId == e.id) {
              value += item.value;
            }
          }
        }
        print('MerdanDev value: $value');
        return TempCat(name: e.name, type: e.type, value: value);
      }).toList();

      yield* _mapLoadedToState(event);
    } else if (event is AddIncomeEvent) {
      int result = await db.insertIncome(
        TblMvIncome(
          id: 0,
          categoryId: event.catId,
          accId: event.accId,
          value: event.value,
          desc: event.text,
          createdDate: DateTime.now(),
          modifiedDate: DateTime.now(),
        ),
      );
      print('MerdanDev insertIncome result is $result');
      incomes = await db.getAccIncomes(accId);
      incomeCats = categories.where((element) => element.type == 1).map((e) {
        double value = 0;
        if (incomes.isNotEmpty) {
          for (var item in incomes) {
            if (item.categoryId == e.id) {
              value += item.value;
            }
          }
        }
        return TempCat(name: e.name, type: e.type, value: value);
      }).toList();
      yield* _mapLoadedToState(event);
    }
  }
}
