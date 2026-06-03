import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/counter/domain/counter_category.dart';

/// Lightweight template describing a default category before it is
/// materialised into a [CounterCategory] (with uuid and timestamps).
class _DefaultCategory {
  const _DefaultCategory(this.name, this.type, this.icon, this.color);

  final String name;
  final CategoryType type;
  final IconData icon;
  final Color color;
}

/// Stable uuids for the fallback categories assigned when an entry has no
/// category selected. Kept fixed so migration and the empty-state lookup can
/// reference them reliably.
const String kDefaultExpenseCategoryUuid = 'default-expense';
const String kDefaultIncomeCategoryUuid = 'default-income';

const List<_DefaultCategory> _defaults = <_DefaultCategory>[
  // Expenses
  _DefaultCategory(
    'Food & Drinks',
    CategoryType.expense,
    Icons.restaurant,
    Colors.orange,
  ),
  _DefaultCategory(
    'Groceries',
    CategoryType.expense,
    Icons.local_grocery_store,
    Colors.green,
  ),
  _DefaultCategory(
    'Transport',
    CategoryType.expense,
    Icons.directions_car,
    Colors.blue,
  ),
  _DefaultCategory(
    'Shopping',
    CategoryType.expense,
    Icons.shopping_bag,
    Colors.pink,
  ),
  _DefaultCategory(
    'Bills & Utilities',
    CategoryType.expense,
    Icons.receipt_long,
    Colors.teal,
  ),
  _DefaultCategory(
    'Rent',
    CategoryType.expense,
    Icons.home,
    Colors.brown,
  ),
  _DefaultCategory(
    'Health',
    CategoryType.expense,
    Icons.local_hospital,
    Colors.red,
  ),
  _DefaultCategory(
    'Entertainment',
    CategoryType.expense,
    Icons.movie,
    Colors.purple,
  ),
  _DefaultCategory(
    'Education',
    CategoryType.expense,
    Icons.school,
    Colors.indigo,
  ),
  _DefaultCategory(
    'Travel',
    CategoryType.expense,
    Icons.flight,
    Colors.cyan,
  ),
  // Income
  _DefaultCategory(
    'Salary',
    CategoryType.income,
    Icons.payments,
    Colors.green,
  ),
  _DefaultCategory(
    'Business',
    CategoryType.income,
    Icons.business_center,
    Colors.blue,
  ),
  _DefaultCategory(
    'Investments',
    CategoryType.income,
    Icons.trending_up,
    Colors.teal,
  ),
  _DefaultCategory(
    'Gifts',
    CategoryType.income,
    Icons.card_giftcard,
    Colors.pink,
  ),
];

/// The fallback "Other" categories, one per type, assigned to entries that
/// have no category selected. They carry [kDefaultExpenseCategoryUuid] /
/// [kDefaultIncomeCategoryUuid] so they can be looked up by a stable identity.
CounterCategory _buildDefaultCategory(CategoryType type, DateTime now) {
  return CounterCategory(
    uuid: type == CategoryType.expense
        ? kDefaultExpenseCategoryUuid
        : kDefaultIncomeCategoryUuid,
    name: 'Other',
    type: type,
    iconCode: Icons.more_horiz.codePoint,
    colorCode: Colors.grey.toARGB32(),
    createdAt: now,
    updatedAt: now,
  );
}

/// Returns the fallback category for [type], reusing the one already present in
/// [categories] when available so embedded copies stay in sync with edits.
CounterCategory defaultCategoryFor(
  CategoryType type,
  List<CounterCategory> categories,
) {
  final uuid = type == CategoryType.expense
      ? kDefaultExpenseCategoryUuid
      : kDefaultIncomeCategoryUuid;
  for (final category in categories) {
    if (category.uuid == uuid) {
      return category;
    }
  }
  return _buildDefaultCategory(type, DateTime.now());
}

/// Builds the list of categories pre-populated on first launch so the user
/// does not have to set everything up by hand.
List<CounterCategory> buildDefaultCategories() {
  const uuid = Uuid();
  final now = DateTime.now();
  return [
    _buildDefaultCategory(CategoryType.expense, now),
    _buildDefaultCategory(CategoryType.income, now),
    ..._defaults.map(
      (d) => CounterCategory(
        uuid: uuid.v1(),
        name: d.name,
        type: d.type,
        iconCode: d.icon.codePoint,
        colorCode: d.color.toARGB32(),
        createdAt: now,
        updatedAt: now,
      ),
    ),
  ];
}
