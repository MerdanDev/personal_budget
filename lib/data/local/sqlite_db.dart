import 'package:path_provider/path_provider.dart';
import 'package:personal_budget/helper/default_item.dart';
import 'package:personal_budget/models/tbl_mv_acc_type.dart';
import 'package:personal_budget/models/tbl_mv_category.dart';
import 'package:personal_budget/models/tbl_mv_expense.dart';
import 'package:personal_budget/models/tbl_mv_income.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SqliteDB {
  SqliteDB._init();
  static final SqliteDB instance = SqliteDB._init();
  final String _dbName = 'local.db';

  get _dbVersion => 1;
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    _db = await _initDB(_dbName);
    return _db!;
  }

  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _dbName);
    print('MerdanDev db path:' + path);
    try {
      Database db =
          await openDatabase(path, version: _dbVersion, onCreate: _onCreate);
      print('Result super');
      return db;
    } catch (e) {
      print(e);
    }
    throw Exception('DB was not created');
  }

  Future _onCreate(Database db, int version) async {
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
    // DefaultItem.categories
    //     .map((e) => TblMvCategory.initMap(e))
    //     .forEach((element) async {
    //   categories.add(await element);
    // });
    for (var item in DefaultItem.categories) {
      categories.add(await TblMvCategory.initMap(item));
    }

    print('MerdanDev categories.length:${categories.length}');

    // categories.map((e) async {
    //   int result = await db.insert('tbl_mv_category', e.toMap());
    //   print('MerdanDev category result is:$result');
    // });

    for (var item in categories) {
      int result = await db.insert('tbl_mv_category', item.toMap());
      print('MerdanDev category result is:$result');
    }

    List<TblMvAccType> accounts = [];
    // DefaultItem.accounts
    //     .map((e) => TblMvAccType.initMap(e))
    //     .forEach((element) async {
    //   accounts.add(await element);
    // });
    for (var item in DefaultItem.accounts) {
      accounts.add(await TblMvAccType.initMap(item));
    }

    print('MerdanDev accounts.length:${accounts.length}');
    // accounts.map((e) async {
    //   int result = await db.insert('tbl_mv_acc_type', e.toMap());
    //   print('MerdanDev account result is:$result');
    // });
    for (var item in accounts) {
      int result = await db.insert('tbl_mv_acc_type', item.toMap());
      print('MerdanDev account result is:$result');
    }
  }

  Future<List<TblMvAccType>> getAccounts() async {
    final db = await instance.database;
    List list = await db.rawQuery('''
      SELECT * FROM tbl_mv_acc_type
    ''');

    return list.map((e) => TblMvAccType.fromMap(e)).toList();
  }

  Future<TblMvAccType> getAccount(int id) async {
    final db = await instance.database;
    List list = await db.rawQuery('''
      SELECT * FROM tbl_mv_acc_type WHERE id = $id
    ''');

    return TblMvAccType.fromMap(list.first);
  }

  Future<List<TblMvCategory>> getCategories() async {
    final db = await instance.database;
    List list = await db.rawQuery('''
      SELECT * FROM tbl_mv_category
    ''');
    return list.map((e) => TblMvCategory.fromMap(e)).toList();
  }

  Future<List<TblMvExpense>> getExpenses() async {
    final db = await instance.database;
    List list = await db.rawQuery('''
      SELECT * FROM tbl_mv_expense
    ''');
    return list.map((e) => TblMvExpense.fromMap(e)).toList();
  }

  Future<List<TblMvIncome>> getIncomes() async {
    final db = await instance.database;
    List list = await db.rawQuery('''
      SELECT * FROM tbl_mv_income
    ''');
    return list.map((e) => TblMvIncome.fromMap(e)).toList();
  }

  Future<List<TblMvExpense>> getAccExpenses(int id) async {
    final db = await instance.database;
    List list = await db.rawQuery('''
      SELECT * FROM tbl_mv_expense WHERE acc_id = $id
    ''');
    return list.map((e) => TblMvExpense.fromMap(e)).toList();
  }

  Future<List<TblMvIncome>> getAccIncomes(int id) async {
    final db = await instance.database;
    List list = await db.rawQuery('''
      SELECT * FROM tbl_mv_income WHERE acc_id = $id
    ''');
    return list.map((e) => TblMvIncome.fromMap(e)).toList();
  }

  Future<int> insertIncome(TblMvIncome income) async {
    final db = await instance.database;
    int result = await db.rawInsert('''
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
        '${income.desc}',
        datetime('${income.createdDate}'),
        datetime('${income.modifiedDate}')
      )
    ''');
    return result;
  }

  Future<int> insertExpense(TblMvExpense expense) async {
    final db = await instance.database;
    int result = await db.rawInsert('''
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
        '${expense.desc}',
        datetime('${expense.createdDate}'),
        datetime('${expense.modifiedDate}')
      )
    ''');
    return result;
  }

  Future<int> insertAccount(TblMvAccType account) async {
    final db = await instance.database;
    int result = await db.rawInsert('''
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

  Future<int> insertCategory(TblMvCategory category) async {
    final db = await instance.database;
    int result = await db.rawInsert('''
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

  Future<int> modifyIncome(TblMvIncome income) async {
    final db = await instance.database;
    int result = await db.rawUpdate('''
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

  Future<int> modifyExpense(TblMvExpense expense) async {
    final db = await instance.database;
    int result = await db.rawUpdate('''
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

  Future<int> modifyAccount(TblMvAccType account) async {
    final db = await instance.database;
    int result = await db.rawUpdate('''
      UPDATE tbl_mv_acc_type SET
        name = ${account.name},
        image = ${account.image},
        desc = ${account.desc}
        WHERE id = ${account.id}
    ''');
    return result;
  }

  Future<int> modifyCategory(TblMvCategory category) async {
    final db = await instance.database;
    int result = await db.rawInsert('''
      UPDATE tbl_mv_category SET
        name = ${category.name},
        image = ${category.image},
        desc = ${category.desc}
        WHERE id = ${category.id}
    ''');
    return result;
  }

  Future<int> deleteIncome(TblMvIncome income) async {
    final db = await instance.database;
    int result = await db.rawDelete('''
        DELETE FROM tbl_mv_income 
        WHERE id = ${income.id}
    ''');
    return result;
  }

  Future<int> deleteExpense(TblMvExpense expense) async {
    final db = await instance.database;
    int result = await db.rawDelete('''
        DELETE FROM tbl_mv_expense 
        WHERE id = ${expense.id}
    ''');
    return result;
  }

  Future<int> deleteCategory(TblMvCategory category) async {
    final db = await instance.database;
    int result = await db.rawDelete('''
        DELETE FROM tbl_mv_category
        WHERE id = ${category.id}
    ''');
    return result;
  }

  Future<int> deleteAccount(TblMvAccType account) async {
    final db = await instance.database;
    int result = await db.rawDelete('''
        DELETE FROM tbl_mv_acc_type 
        WHERE id = ${account.id}
    ''');
    return result;
  }
}
