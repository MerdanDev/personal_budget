import 'package:bloc/bloc.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/infrastructure/counter_repository.dart';

/// Holds the per-category monthly spending limits and exposes the derived
/// "spent this month" figures used by the budgets UI and threshold alerts.
///
/// Budgets are keyed by category uuid; a category has at most one budget.
class BudgetCubit extends Cubit<List<CategoryBudget>> {
  factory BudgetCubit() => instance;
  BudgetCubit._internal() : super(CounterRepository.getCategoryBudgetList());

  static final BudgetCubit instance = BudgetCubit._internal();

  /// The budget for [categoryUuid], or null if none is set.
  CategoryBudget? budgetFor(String categoryUuid) {
    for (final b in state) {
      if (b.categoryUuid == categoryUuid) return b;
    }
    return null;
  }

  /// Creates or updates the monthly [limit] for [categoryUuid]. A non-positive
  /// limit clears the budget instead (treated as "no limit").
  void setBudget({required String categoryUuid, required double limit}) {
    if (limit <= 0) {
      removeBudget(categoryUuid);
      return;
    }
    final now = DateTime.now();
    final existing = budgetFor(categoryUuid);
    final update = [...state];
    if (existing == null) {
      update.add(
        CategoryBudget(
          categoryUuid: categoryUuid,
          limit: limit,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      final index = update.indexWhere((b) => b.categoryUuid == categoryUuid);
      update[index] = existing.copyWith(limit: limit, updatedAt: now);
    }
    CounterRepository.setCategoryBudgetList(update);
    emit(update);
  }

  void removeBudget(String categoryUuid) {
    final update = [...state]
      ..removeWhere((b) => b.categoryUuid == categoryUuid);
    if (update.length == state.length) return;
    CounterRepository.setCategoryBudgetList(update);
    emit(update);
  }

  /// Merges the budgets from a restored backup into the current set. Matched by
  /// category uuid, keeping whichever record was updated more recently
  /// (last-write-wins), and appending budgets for categories not yet present.
  void restoreBackup(List<CategoryBudget> incoming) {
    if (incoming.isEmpty) return;
    final update = [...state];
    for (final budget in incoming) {
      final index =
          update.indexWhere((b) => b.categoryUuid == budget.categoryUuid);
      if (index == -1) {
        update.add(budget);
      } else if (budget.updatedAt.isAfter(update[index].updatedAt)) {
        update[index] = budget;
      }
    }
    CounterRepository.setCategoryBudgetList(update);
    emit(update);
  }

  /// Drops budgets whose category no longer exists, so a deleted category does
  /// not leave an orphan limit behind. Call after category deletions.
  void pruneOrphans(List<CounterCategory> categories) {
    final ids = categories.map((c) => c.uuid).toSet();
    final update = state.where((b) => ids.contains(b.categoryUuid)).toList();
    if (update.length == state.length) return;
    CounterRepository.setCategoryBudgetList(update);
    emit(update);
  }

  /// Total spent this calendar month against [categoryUuid], as a positive
  /// amount. Sums only expense entries (stored as negative amounts) dated in
  /// the current month, read from the single source of truth in [CounterBloc].
  static double spentThisMonth(String categoryUuid) {
    final now = DateTime.now();
    var total = 0.0;
    for (final e in CounterBloc.instance.data) {
      if (e.category?.uuid == categoryUuid &&
          e.amount < 0 &&
          isSameMonth(now, e.createdAt)) {
        total += e.amount.abs();
      }
    }
    return total;
  }
}
