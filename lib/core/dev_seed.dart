import 'dart:convert';

import 'package:uuid/uuid.dart';
import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/default_categories.dart';
import 'package:wallet/counter/domain/income_expense.dart';

/// Populates the local store with realistic demo data for taking Play Store /
/// marketing screenshots that show off the newer UI (category icons in the
/// list, calendar net-total badges and daily summaries, and the monthly
/// category budgets with 80% / 100% alerts).
///
/// This is a DEV-ONLY helper. It is wired into `main_development.dart` and must
/// never be called from the production entry point. It writes straight to
/// [SingletonSharedPreference] (bypassing the repositories and their widget
/// sync) so it can run before the app's singletons read their initial state.
///
/// Call it after `SingletonSharedPreference.init(...)` and before the
/// bloc/cubit singletons are first constructed.
class DevSeed {
  const DevSeed._();

  /// The currency symbol shown next to every amount in the screenshots.
  static const String _currencySymbol = r'$';

  /// When true the demo data is rewritten on every launch so screenshots stay
  /// consistent. Set to false to keep whatever you have added by hand.
  static const bool _forceReseed = true;

  static const Uuid _uuid = Uuid();

  static Future<void> seed() async {
    final hasData =
        (SingletonSharedPreference.loadIncomeExpenseList() ?? '').isNotEmpty;
    if (hasData && !_forceReseed) return;

    final now = DateTime.now();
    final categories = buildDefaultCategories();

    // Look up categories by name so entries can reference them by their
    // human-readable label instead of a generated uuid.
    final byName = <String, CounterCategory>{
      for (final c in categories) c.name: c,
    };
    CounterCategory cat(String name) => byName[name]!;

    final entries = <IncomeExpense>[];

    // Builds a dated entry. [day] is the day-of-month; for the current month it
    // is clamped so nothing lands in the future. [monthsAgo] shifts the date
    // back whole months for building history.
    void add(
      double amount,
      String categoryName,
      String description, {
      int day = 1,
      int monthsAgo = 0,
      int hour = 10,
      int minute = 0,
    }) {
      final targetMonth = DateTime(now.year, now.month - monthsAgo);
      final safeDay = monthsAgo == 0 ? (day > now.day ? now.day : day) : day;
      final createdAt = DateTime(
        targetMonth.year,
        targetMonth.month,
        safeDay,
        hour,
        minute,
      );
      entries.add(
        IncomeExpense(
          uuid: _uuid.v1(),
          amount: amount,
          description: description,
          category: cat(categoryName),
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );
    }

    _seedCurrentMonth(add);
    _seedPreviousMonth(add, monthsAgo: 1);
    _seedPreviousMonth(add, monthsAgo: 2);

    // Monthly limits chosen against the current-month spend built above so the
    // budgets page shows the full range of states: one over budget (Food &
    // Drinks ~105%), one in the 80% warning band (Groceries ~86%), and several
    // comfortably under.
    final budgets = <CategoryBudget>[
      _budget(cat('Food & Drinks').uuid, 110, now),
      _budget(cat('Groceries').uuid, 250, now),
      _budget(cat('Transport').uuid, 180, now),
      _budget(cat('Shopping').uuid, 200, now),
      _budget(cat('Entertainment').uuid, 100, now),
      _budget(cat('Bills & Utilities').uuid, 200, now),
      _budget(cat('Health').uuid, 120, now),
    ];

    await SingletonSharedPreference.setCounterCategory(
      jsonEncode(categories.map((e) => e.toMap()).toList()),
    );
    await SingletonSharedPreference.setIncomeExpenseList(
      jsonEncode(entries.map((e) => e.toMap()).toList()),
    );
    await SingletonSharedPreference.setCategoryBudgetList(
      jsonEncode(budgets.map((e) => e.toMap()).toList()),
    );

    // Skip onboarding and keep the seeded categories/data as the source of
    // truth so the singletons don't re-seed or run the legacy migration.
    await SingletonSharedPreference.setDefaultCategoriesSeeded(value: true);
    await SingletonSharedPreference.setTitleCategoryMigrationDone(value: true);
    await SingletonSharedPreference.setOnboardingCompleted(value: true);
    await SingletonSharedPreference.setCurrencySymbol(_currencySymbol);
  }

  /// A monthly budget for [uuid] with the given [limit], timestamped [now].
  static CategoryBudget _budget(String uuid, double limit, DateTime now) {
    return CategoryBudget(
      categoryUuid: uuid,
      limit: limit,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Current-month activity. Expenses are negative, income positive. The
  /// per-category totals here are what the budget limits above are tuned to.
  static void _seedCurrentMonth(
    void Function(
      double amount,
      String categoryName,
      String description, {
      int day,
      int monthsAgo,
      int hour,
      int minute,
    }) add,
  ) {
    // Income
    add(4800, 'Salary', 'Monthly salary', day: 1, hour: 9);
    add(950, 'Business', 'Freelance project', day: 8, hour: 15);
    add(220, 'Investments', 'Dividends', day: 5, hour: 12);

    // Rent (no budget — the big fixed cost)
    add(-1300, 'Rent', 'Apartment rent', day: 1, hour: 8);

    // Bills & Utilities → ~140 / 200 (70%)
    add(-95, 'Bills & Utilities', 'Electricity', day: 3, hour: 18);
    add(-45, 'Bills & Utilities', 'Internet', day: 6, hour: 11);

    // Groceries → ~215 / 250 (86% — warning band)
    add(-62, 'Groceries', 'Weekly groceries', day: 2, hour: 17);
    add(-48, 'Groceries', 'Supermarket', day: 4, hour: 19);
    add(-71, 'Groceries', 'Weekly groceries', day: 7, hour: 18, minute: 30);
    add(-34, 'Groceries', 'Fruit & veg', day: 9, hour: 10);

    // Food & Drinks → ~115.5 / 110 (over budget)
    add(-4.50, 'Food & Drinks', 'Morning coffee', day: 1, hour: 8, minute: 15);
    add(-12, 'Food & Drinks', 'Lunch', day: 2, hour: 13);
    add(-6, 'Food & Drinks', 'Coffee', day: 3, hour: 9, minute: 30);
    add(-22, 'Food & Drinks', 'Dinner out', day: 4, hour: 20);
    add(-8.50, 'Food & Drinks', 'Bakery', day: 5, hour: 8, minute: 45);
    add(-15, 'Food & Drinks', 'Lunch', day: 6, hour: 13, minute: 15);
    add(-5.50, 'Food & Drinks', 'Coffee', day: 7, hour: 9);
    add(-18, 'Food & Drinks', 'Takeout', day: 8, hour: 19, minute: 30);
    add(-9, 'Food & Drinks', 'Snacks', day: 9, hour: 16);
    add(-15.50, 'Food & Drinks', 'Brunch', day: 10, hour: 11);

    // Transport → 73 / 180 (40%)
    add(-30, 'Transport', 'Fuel', day: 2, hour: 8);
    add(-25, 'Transport', 'Taxi', day: 7, hour: 22);
    add(-18, 'Transport', 'Bus pass top-up', day: 10, hour: 8, minute: 30);

    // Shopping → 130 / 200 (65%)
    add(-85, 'Shopping', 'New shoes', day: 4, hour: 14);
    add(-45, 'Shopping', 'Household items', day: 8, hour: 16, minute: 30);

    // Entertainment → 61 / 100 (61%)
    add(-14, 'Entertainment', 'Music subscription', day: 3, hour: 21);
    add(-35, 'Entertainment', 'Cinema', day: 6, hour: 20, minute: 30);
    add(-12, 'Entertainment', 'Streaming', day: 9, hour: 21);

    // Health → 40 / 120 (33%)
    add(-40, 'Health', 'Pharmacy', day: 5, hour: 17);
  }

  /// A lighter set of entries for a past month, used to give the charts and
  /// history something to show. Not tied to any budget.
  static void _seedPreviousMonth(
    void Function(
      double amount,
      String categoryName,
      String description, {
      int day,
      int monthsAgo,
      int hour,
      int minute,
    }) add, {
    required int monthsAgo,
  }) {
    add(4800, 'Salary', 'Monthly salary', day: 1, monthsAgo: monthsAgo);
    add(600, 'Business', 'Side project', day: 14, monthsAgo: monthsAgo);
    add(100, 'Gifts', 'Birthday gift', day: 20, monthsAgo: monthsAgo);

    add(-1300, 'Rent', 'Apartment rent', day: 1, monthsAgo: monthsAgo);
    add(-102, 'Bills & Utilities', 'Electricity', day: 3, monthsAgo: monthsAgo);
    add(-45, 'Bills & Utilities', 'Internet', day: 6, monthsAgo: monthsAgo);
    add(-58, 'Groceries', 'Weekly groceries', day: 5, monthsAgo: monthsAgo);
    add(-64, 'Groceries', 'Weekly groceries', day: 12, monthsAgo: monthsAgo);
    add(-77, 'Groceries', 'Weekly groceries', day: 19, monthsAgo: monthsAgo);
    add(-52, 'Groceries', 'Weekly groceries', day: 26, monthsAgo: monthsAgo);
    add(-12, 'Food & Drinks', 'Lunch', day: 4, monthsAgo: monthsAgo);
    add(-28, 'Food & Drinks', 'Dinner out', day: 11, monthsAgo: monthsAgo);
    add(-19, 'Food & Drinks', 'Takeout', day: 18, monthsAgo: monthsAgo);
    add(-24, 'Food & Drinks', 'Dinner out', day: 25, monthsAgo: monthsAgo);
    add(-55, 'Transport', 'Fuel', day: 8, monthsAgo: monthsAgo);
    add(-40, 'Transport', 'Taxi', day: 22, monthsAgo: monthsAgo);
    add(-120, 'Shopping', 'Clothes', day: 15, monthsAgo: monthsAgo);
    add(-30, 'Entertainment', 'Concert', day: 17, monthsAgo: monthsAgo);
    add(-90, 'Health', 'Dentist', day: 21, monthsAgo: monthsAgo);
    add(-300, 'Travel', 'Weekend trip', day: 24, monthsAgo: monthsAgo);
  }
}
