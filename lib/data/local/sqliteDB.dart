import 'dart:io';

import 'package:path_provider/path_provider.dart';
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
    print('DkPrint Db Path is:' + path);
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
          value BLOB NULL,
          desc TEXT NULL
        )
      ''',
    );

    await db.execute(
      '''
        CREATE TABLE tbl_mv_acc_type(
          id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          name TEXT NOT NULL,
          value BLOB NULL,
          desc TEXT NULL
        )
      ''',
    );
  }
}
