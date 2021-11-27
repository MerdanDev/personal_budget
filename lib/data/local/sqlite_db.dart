import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:personal_budget/helper/default_item.dart';
import 'package:personal_budget/models/tbl_mv_acc_type.dart';
import 'package:personal_budget/models/tbl_mv_category.dart';
import 'package:personal_budget/models/tbl_mv_expense.dart';
import 'package:personal_budget/models/tbl_mv_income.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

abstract class SqliteDB {
  static final _dbName = 'personalBudget.db';

  static get _dbVersion => 1;
  static Database? _db;

  static Future<void> init() async {
    if (_db != null) {
      return;
    }

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    print('MerdanDev Db Path is:' + path);
    _db = await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
  }

  static Future _onCreate(Database db, int version) async {
    await db.execute(
      '''
        CREATE TABLE tbl_mv_income(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          category_id INTEGER NOT NULL,
          acc_id INTEGER NOT NULL,
          value REAL NOT NULL,
          desc TEXT NULL,
          created_date  DATETIME NULL,
          modified_date  DATETIME NULL
        )
      ''',
    );

    await db.execute(
      '''
        CREATE TABLE tbl_mv_expense(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          category_id INTEGER NOT NULL,
          acc_id INTEGER NOT NULL,
          value REAL NOT NULL,
          desc TEXT NULL,
          created_date  DATETIME NULL,
          modified_date  DATETIME NULL
        )
      ''',
    );

    await db.execute(
      '''
        CREATE TABLE tbl_mv_category(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          name TEXT NOT NULL,
          image TEXT NULL,
          type INTEGER NOT NULL,
          desc TEXT NULL
        )
      ''',
    );

    await db.execute(
      '''
        CREATE TABLE tbl_mv_acc_type(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          name TEXT NOT NULL,
          image TEXT NULL,
          desc TEXT NULL
        )
      ''',
    );
    List<TblMvCategory> categories = [];
    DefaultItem.categories
        .map((e) => TblMvCategory.initMap(e))
        .forEach((element) async {
      categories.add(await element);
    });

    categories.map((e) async => await db.insert('tbl_mv_category', e.toMap()));

    List<TblMvAccType> accounts = [];
    DefaultItem.accounts
        .map((e) => TblMvAccType.initMap(e))
        .forEach((element) async {
      accounts.add(await element);
    });
    accounts.map((e) async => await db.insert('tbl_mv_acc_type', e.toMap()));
  }

  static Future<List<TblMvAccType>> getAccounts() async {
    List list = await _db!.rawQuery('''
      SELECT * FROM tbl_mv_acc_type
    ''');

    return list.map((e) => TblMvAccType.fromMap(e)).toList();
  }

  static Future<TblMvAccType> getAccount(int id) async {
    List list = await _db!.rawQuery('''
      SELECT * FROM tbl_mv_acc_type WHERE id = $id
    ''');

    return TblMvAccType.fromMap(list.first);
  }

  static Future<List<TblMvCategory>> getCategories() async {
    List list = await _db!.rawQuery('''
      SELECT * FROM tbl_mv_category
    ''');
    return list.map((e) => TblMvCategory.fromMap(e)).toList();
  }

  static Future<List<TblMvExpense>> getExpenses() async {
    List list = await _db!.rawQuery('''
      SELECT * FROM tbl_mv_expense
    ''');
    return list.map((e) => TblMvExpense.fromMap(e)).toList();
  }

  static Future<List<TblMvIncome>> getIncomes() async {
    List list = await _db!.rawQuery('''
      SELECT * FROM tbl_mv_income
    ''');
    return list.map((e) => TblMvIncome.fromMap(e)).toList();
  }

  static Future<List<TblMvExpense>> getAccExpenses(int id) async {
    List list = await _db!.rawQuery('''
      SELECT * FROM tbl_mv_expense WHERE acc_id = $id
    ''');
    return list.map((e) => TblMvExpense.fromMap(e)).toList();
  }

  static Future<List<TblMvIncome>> getAccIncomes(int id) async {
    List list = await _db!.rawQuery('''
      SELECT * FROM tbl_mv_income WHERE acc_id = $id
    ''');
    return list.map((e) => TblMvIncome.fromMap(e)).toList();
  }

  static Future<int> insertIncome(TblMvIncome income) async {
    int result = await _db!.rawInsert('''
      INSERT INTO tbl_mv_income (
        category_id,
        acc_id,
        value,
        desc,
        created_date,
        modified_date
      ) VALUES (
        ${income.categoryId},
        ${income.accId},
        ${income.value},
        ${income.desc},
        datetime('${income.createdDate}'),
        datetime('${income.modifiedDate}')
      )
    ''');
    return result;
  }

  static Future<int> insertExpense(TblMvExpense expense) async {
    int result = await _db!.rawInsert('''
      INSERT INTO tbl_mv_expense (
        category_id,
        acc_id,
        value,
        desc,
        created_date,
        modified_date
      ) VALUES (
        ${expense.categoryId},
        ${expense.accId},
        ${expense.value},
        ${expense.desc},
        datetime('${expense.createdDate}'),
        datetime('${expense.modifiedDate}')
      )
    ''');
    return result;
  }

  static Future<int> insertAccount(TblMvAccType account) async {
    int result = await _db!.rawInsert('''
      INSERT INTO tbl_mv_acc_type (
        name,
        image,
        desc
      ) VALUES (
        ${account.name},
        ${account.image},
        ${account.desc}
      )
    ''');
    return result;
  }

  static Future<int> insertCategory(TblMvCategory category) async {
    int result = await _db!.rawInsert('''
      INSERT INTO tbl_mv_category (
        name,
        image,
        desc
      ) VALUES (
        ${category.name},
        ${category.image},
        ${category.desc}
      )
    ''');
    return result;
  }

  static Future<int> modifyIncome(TblMvIncome income) async {
    int result = await _db!.rawUpdate('''
      UPDATE tbl_mv_income SET
      category_id = ${income.categoryId},
      acc_id = ${income.accId},
      value = ${income.value},
      desc = '${income.desc}',
      created_date = datetime('${income.createdDate}'),
      modified_date = datetime('${DateTime.now()}')      
      WHERE id = ${income.id}
    ''');
    return result;
  }

  static Future<int> modifyExpense(TblMvExpense expense) async {
    int result = await _db!.rawUpdate('''
      UPDATE tbl_mv_expense SET
      category_id = ${expense.categoryId},
      acc_id = ${expense.accId},
      value = ${expense.value},
      desc = '${expense.desc}',
      created_date = datetime('${expense.createdDate}'),
      modified_date = datetime('${DateTime.now()}')    
      WHERE id = ${expense.id}
    ''');
    return result;
  }

  static Future<int> modifyAccount(TblMvAccType account) async {
    int result = await _db!.rawUpdate('''
      UPDATE tbl_mv_acc_type SET
        name = ${account.name},
        image = ${account.image},
        desc = ${account.desc}
        WHERE id = ${account.id}
    ''');
    return result;
  }

  static Future<int> modifyCategory(TblMvCategory category) async {
    int result = await _db!.rawInsert('''
      UPDATE tbl_mv_category SET
        name = ${category.name},
        image = ${category.image},
        desc = ${category.desc}
        WHERE id = ${category.id}
    ''');
    return result;
  }

  static Future<int> deleteIncome(TblMvIncome income) async {
    int result = await _db!.rawDelete('''
        DELETE FROM tbl_mv_income 
        WHERE id = ${income.id}
    ''');
    return result;
  }

  static Future<int> deleteExpense(TblMvExpense expense) async {
    int result = await _db!.rawDelete('''
        DELETE FROM tbl_mv_expense 
        WHERE id = ${expense.id}
    ''');
    return result;
  }

  static Future<int> deleteCategory(TblMvCategory category) async {
    int result = await _db!.rawDelete('''
        DELETE FROM tbl_mv_category
        WHERE id = ${category.id}
    ''');
    return result;
  }

  static Future<int> deleteAccount(TblMvAccType account) async {
    int result = await _db!.rawDelete('''
        DELETE FROM tbl_mv_acc_type 
        WHERE id = ${account.id}
    ''');
    return result;
  }
}
