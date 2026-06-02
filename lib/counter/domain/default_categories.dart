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

/// Builds the list of categories pre-populated on first launch so the user
/// does not have to set everything up by hand.
List<CounterCategory> buildDefaultCategories() {
  const uuid = Uuid();
  final now = DateTime.now();
  return _defaults
      .map(
        (d) => CounterCategory(
          uuid: uuid.v1(),
          name: d.name,
          type: d.type,
          iconCode: d.icon.codePoint,
          colorCode: d.color.toARGB32(),
          createdAt: now,
          updatedAt: now,
        ),
      )
      .toList();
}
