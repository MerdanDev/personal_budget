import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/income_expense.dart';

final categoryList = [
  CounterCategory(
    uuid: '88dc04a0-6f3b-1f88-84f0-f978df2003db',
    name: 'Work',
    type: CategoryType.expense,
    colorCode: 4283848807,
    iconCode: 57622,
    createdAt: DateTime.parse('2024-04-22 19:51:34.542806'),
    updatedAt: DateTime.parse('2024-04-23 17:45:41.362922'),
  ),
  CounterCategory(
    uuid: '4247ddc0-6fd1-1f88-a514-01494298e55b',
    name: 'Transport',
    type: CategoryType.expense,
    colorCode: 4280992511,
    iconCode: 57728,
    createdAt: DateTime.parse('2024-04-22 19:52:38.849084'),
    updatedAt: DateTime.parse('2024-04-24 17:44:42.763317'),
  ),
  CounterCategory(
    uuid: 'a0ed5970-7050-1f88-a514-01494298e55b',
    name: 'Nahar',
    type: CategoryType.expense,
    colorCode: 4289572686,
    iconCode: 57946,
    createdAt: DateTime.parse('2024-04-22 19:53:33.549989'),
    updatedAt: DateTime.parse('2024-04-25 17:05:17.817019'),
  ),
  CounterCategory(
    uuid: '54a389e0-1af4-1f94-8698-116e48d07550',
    name: 'Gadget ',
    type: CategoryType.expense,
    colorCode: 4282563191,
    iconCode: 57804,
    createdAt: DateTime.parse('2024-04-26 15:06:38.031518'),
    updatedAt: DateTime.parse('2024-04-26 15:06:38.031518'),
  ),
  CounterCategory(
    uuid: '713a2c10-01ff-1fc2-9bbf-bf5e3294f43a',
    name: 'Transaction',
    type: CategoryType.income,
    colorCode: 4282279424,
    iconCode: 58459,
    createdAt: DateTime.parse('2024-05-11 14:00:38.921277'),
    updatedAt: DateTime.parse('2024-05-11 14:00:38.921277'),
  ),
  CounterCategory(
    uuid: '39ff6eb0-02ed-1fc2-9bbf-bf5e3294f43a',
    name: 'Aýlyk',
    type: CategoryType.income,
    createdAt: DateTime.parse('2024-05-11 14:02:21.045416'),
    updatedAt: DateTime.parse('2024-05-11 14:02:21.045416'),
  ),
];

final incomeExpenseList = [
  IncomeExpense(
    uuid: 'a547e340-5e6a-1fd1-a7e5-bd5bc590d70d',
    amount: -500,
    title: 'Sargyt',
    createdAt: DateTime.parse('2024-05-16 14:06:52.958501'),
    updatedAt: DateTime.parse('2024-05-16 14:06:52.958501'),
  ),
  IncomeExpense(
    uuid: '3c121f10-8d2e-1fb8-82ff-05c742b486c7',
    amount: 500,
    title: 'Algy',
    category: CounterCategory(
      uuid: '713a2c10-01ff-1fc2-9bbf-bf5e3294f43a',
      name: 'Transaction',
      type: CategoryType.income,
      colorCode: 4282279424,
      iconCode: 58459,
      createdAt: DateTime.parse('2024-05-11 14:00:38.921277'),
      updatedAt: DateTime.parse('2024-05-11 14:00:38.921277'),
    ),
    createdAt: DateTime.parse('2024-05-08 12:04:27.255515'),
    updatedAt: DateTime.parse('2024-05-11 14:00:49.604038'),
  ),
  IncomeExpense(
    uuid: '272028e0-8cac-1fb8-82ff-05c742b486c7',
    amount: -25,
    title: 'Nahar',
    category: CounterCategory(
      uuid: 'a0ed5970-7050-1f88-a514-01494298e55b',
      name: 'Nahar',
      type: CategoryType.expense,
      colorCode: 4289572686,
      iconCode: 57946,
      createdAt: DateTime.parse('2024-04-22 19:53:33.549989'),
      updatedAt: DateTime.parse('2024-04-25 17:05:17.817019'),
    ),
    createdAt: DateTime.parse('2024-05-08 12:03:31.387009'),
    updatedAt: DateTime.parse('2024-05-08 12:03:31.387009'),
  ),
  IncomeExpense(
    uuid: '77045570-8c5c-1fb8-82ff-05c742b486c7',
    amount: -50,
    title: 'Taksi',
    category: CounterCategory(
      uuid: '4247ddc0-6fd1-1f88-a514-01494298e55b',
      name: 'Transport',
      type: CategoryType.expense,
      colorCode: 4280992511,
      iconCode: 57728,
      createdAt: DateTime.parse('2024-04-22 19:52:38.849084'),
      updatedAt: DateTime.parse('2024-04-24 17:44:42.763317'),
    ),
    createdAt: DateTime.parse('2024-05-08 12:02:57.168704'),
    updatedAt: DateTime.parse('2024-05-08 12:03:17.395031'),
  ),
  IncomeExpense(
    uuid: 'bab0a750-4981-1f91-974c-53c976491ab5',
    amount: -20,
    title: 'Günortan nahar',
    category: CounterCategory(
      uuid: 'a0ed5970-7050-1f88-a514-01494298e55b',
      name: 'Nahar',
      type: CategoryType.expense,
      colorCode: 4289572686,
      iconCode: 57946,
      createdAt: DateTime.parse('2024-04-22 19:53:33.549989'),
      updatedAt: DateTime.parse('2024-04-25 17:05:17.817019'),
    ),
    createdAt: DateTime.parse('2024-04-25 17:04:34.044549'),
    updatedAt: DateTime.parse('2024-04-25 17:04:34.044549'),
  ),
  IncomeExpense(
    uuid: 'c0ab1170-5bd8-1f8e-badc-2d1de34b5641',
    amount: 2500,
    title: 'Awans',
    category: CounterCategory(
      uuid: '39ff6eb0-02ed-1fc2-9bbf-bf5e3294f43a',
      name: 'Aýlyk',
      type: CategoryType.income,
      colorCode: 4278231640,
      iconCode: 58474,
      createdAt: DateTime.parse('2024-05-11 14:02:21.045416'),
      updatedAt: DateTime.parse('2024-05-11 14:02:21.045416'),
    ),
    createdAt: DateTime.parse('2024-04-24 18:10:48.040158'),
    updatedAt: DateTime.parse('2024-05-11 14:02:25.796062'),
  ),
];

void main() {
  const filePath = 'category_list.csv';
  test(
    'CounterCategory csv write test',
    () => counterCategoryToCsv(categoryList, filePath),
  );

  test(
    'CounterCategory csv read test',
    () async {
      final result = await csvToCounterCategory(filePath);
      return expect(result, categoryList);
    },
  );

  const filePath2 = 'income_expense_list.csv';
  test(
    'IncomeExpense csv write test',
    () => writeIncomeExpenseToCsv(incomeExpenseList, filePath2),
  );
  test(
    'IncomeExpense csv read test',
    () async {
      final result = await csvToIncomeExpense(filePath2);
      return expect(result, incomeExpenseList);
    },
  );

  test('Read from note.csv and write to income_expense_list.csv', () async {
    final result = await noteToIncomeExpense('note.csv');
    await writeIncomeExpenseToCsv(result, filePath2);
  });

  test(
    'IncomeExpense csv read and categoryList test',
    () async {
      final result = await csvToIncomeExpense('note.csv');
      final categorySet = <CounterCategory>{};
      for (final item in result) {
        if (item.category != null) categorySet.add(item.category!);
      }
      // final categoryList = categorySet.toList();
      // print('Ended $categoryList');
      // return expect(result, incomeExpenseList);
    },
  );
}

Future<void> counterCategoryToCsv(
  List<CounterCategory> data,
  String filePath,
) async {
  final file = File(filePath);
  final sink = file.openWrite();
  for (final item in data) {
    final row = item.toListString();
    sink
      ..writeAll(row, ',')
      ..writeln();
  }
  // Write CSV data to a file
  await sink.close();
}

Future<List<CounterCategory>> csvToCounterCategory(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines();
  final data = <CounterCategory>[];
  for (final line in lines) {
    data.add(
      CounterCategory.fromList(line.split(',')),
    );
  }
  return data;
}

Future<void> writeIncomeExpenseToCsv(
  List<IncomeExpense> data,
  String filePath,
) async {
  final file = File(filePath);
  final sink = file.openWrite();
  for (final item in data) {
    final row = item.toListString();
    sink
      ..writeAll(row, ',')
      ..writeln();
  }
  // Write CSV data to a file
  await sink.close();
}

Future<List<IncomeExpense>> csvToIncomeExpense(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines();
  final data = <IncomeExpense>[];
  for (final line in lines) {
    data.add(
      IncomeExpense.fromList(line.split(',')),
    );
  }
  return data;
}

Future<List<IncomeExpense>> noteToIncomeExpense(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines();
  final data = <IncomeExpense>[];
  for (final line in lines) {
    final raw = line.split(',');
    final rawDate = raw[5].split('/');
    final createdAt = DateTime(
      int.parse(rawDate[2]),
      int.parse(rawDate[0]),
      int.parse(rawDate[1]),
    );
    final amount = double.parse(raw[1]);
    data.add(
      IncomeExpense(
        uuid: raw[0],
        amount: amount,
        title: raw[2],
        createdAt: createdAt,
        updatedAt: createdAt,
        category: amount > 5000
            ? categoryList.last
            : amount > 0
                ? categoryList[4]
                : null,
      ),
    );
  }
  return data;
}
