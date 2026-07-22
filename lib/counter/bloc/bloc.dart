import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/core/notification_service.dart';
import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/cubit/budget_cubit.dart';
import 'package:wallet/counter/cubit/category_cubit.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/domain/default_categories.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/infrastructure/counter_repository.dart';
import 'package:wallet/l10n/application/localization_cubit.dart';
import 'package:wallet/l10n/l10n.dart';

part 'event.dart';
part 'state.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  factory CounterBloc() => instance;
  CounterBloc._internal()
      : super(
          const CounterState(
            data: [],
            dateFilter: DateFilter.all,
            loading: true,
          ),
        ) {
    on<InitEvent>(
      (event, emit) {
        final migrationDone =
            SingletonSharedPreference.loadTitleCategoryMigrationDone();

        // Before the title→category migration first rewrites the store, keep a
        // one-time snapshot of the original raw JSON as a recovery net for
        // upgrading users (who never see onboarding again).
        if (!migrationDone) {
          final raw = SingletonSharedPreference.loadIncomeExpenseList();
          if (raw != null && raw.isNotEmpty) {
            SingletonSharedPreference.setIncomeExpenseBackup(raw);
          }
        }

        // get data from cache;
        final dataFromCache = CounterRepository.getIncomeExpenseList();
        // Migration: entries without a category get the type-appropriate
        // fallback so the list always has a label. (Legacy `title` text is
        // already folded into the description by IncomeExpense.fromMap.)
        final migrated = dataFromCache.any((e) => e.category == null);
        data.addAll(_withDefaultCategories(dataFromCache));
        // Persist a clean store on the first migrated launch (drops legacy
        // `title` keys, folds them into descriptions, fills default
        // categories), and on any later launch that still had to fill a gap.
        if (!migrationDone || migrated) {
          CounterRepository.setIncomeExpenseList(data);
        }
        if (!migrationDone) {
          SingletonSharedPreference.setTitleCategoryMigrationDone(value: true);
        }
        // get date filter from cache;
        dateFilter = CounterRepository.getDateFilter();
        // complete loading;
        emit(_loaded());
      },
    );
    on<IncomeExpenseEvent>((event, emit) {
      final now = DateTime.now();
      final category = event.category ??
          defaultCategoryFor(
            event.amount < 0 ? CategoryType.expense : CategoryType.income,
            CounterCategoryCubit.instance.state,
          );
      // Snapshot the month-to-date spend before this entry lands so a budget
      // threshold crossing can be detected (expenses are negative amounts).
      final spentBefore =
          event.amount < 0 ? BudgetCubit.spentThisMonth(category.uuid) : 0.0;
      data.add(
        IncomeExpense(
          uuid: event.uuid,
          amount: event.amount,
          category: category,
          description: event.description,
          createdAt: now,
          updatedAt: now,
        ),
      );

      CounterRepository.setIncomeExpenseList(data);
      if (event.amount < 0) {
        unawaited(
          maybeNotifyBudgetThreshold(
            category: category,
            spentBefore: spentBefore,
            spentAfter: spentBefore + event.amount.abs(),
          ),
        );
      }
      emit(_loaded());
    });

    on<UpdateIncomeExpenseEvent>(
      (event, emit) {
        final now = DateTime.now();
        final element = data.firstWhere(
          (element) => element.uuid == event.uuid,
        );
        final index = data.indexWhere((element) => element.uuid == event.uuid);
        data
          ..removeAt(index)
          ..insert(
            index,
            element.copyWith(
              amount: event.amount,
              category: event.category,
              description: event.description,
              updatedAt: now,
            ),
          );

        CounterRepository.setIncomeExpenseList(data);
        emit(_loaded());
      },
    );

    on<SelectUpdateCategory>(
      (event, emit) {
        final now = DateTime.now();
        for (final uuid in event.uuids) {
          final element = data.firstWhere(
            (element) => element.uuid == uuid,
          );
          final index = data.indexWhere((element) => element.uuid == uuid);
          data
            ..removeAt(index)
            ..insert(
              index,
              element.copyWith(
                category: event.category,
                updatedAt: now,
              ),
            );
        }

        CounterRepository.setIncomeExpenseList(data);
        emit(_loaded());
      },
    );

    on<RemoveEvent>(
      (event, emit) {
        data.removeWhere((element) => element.uuid == event.uuid);

        CounterRepository.setIncomeExpenseList(data);
        emit(_loaded());
      },
    );

    on<ChangeDateFilter>((event, emit) {
      dateFilter = event.dateFilter;
      CounterRepository.setDateFilter(event.dateFilter);
      emit(_loaded());
    });

    on<ChangeSearchQuery>((event, emit) {
      searchQuery = event.query;
      emit(_loaded());
    });

    on<CategoryUpdate>((event, emit) {
      final result = data.map(
        (e) {
          if (e.category?.uuid == event.category.uuid) {
            return e.copyWith(category: event.category);
          } else {
            return e;
          }
        },
      ).toList();
      data
        ..clear()
        ..addAll(result);
      CounterRepository.setIncomeExpenseList(data);
      emit(_loaded());
    });

    on<CategoryDelete>((event, emit) {
      final result = data.map(
        (e) {
          if (e.category?.uuid == event.uuid) {
            // Reassign the fallback category so the entry keeps a label
            // instead of dropping back to an uncategorised state.
            return e.copyWith(
              category: defaultCategoryFor(
                e.amount < 0 ? CategoryType.expense : CategoryType.income,
                CounterCategoryCubit.instance.state,
              ),
            );
          } else {
            return e;
          }
        },
      ).toList();
      data
        ..clear()
        ..addAll(result);
      CounterRepository.setIncomeExpenseList(data);
      emit(_loaded());
    });

    on<RestoreBackUp>(
      (event, emit) {
        for (final item in event.list) {
          final elements = data.where((e) => e.uuid == item.uuid);
          final compare = elements.firstOrNull?.updatedAt.compareTo(
            item.updatedAt,
          );
          if (compare != null && compare != 0) {
            final element = elements.first;

            final index = data.indexWhere(
              (element) => element.uuid == item.uuid,
            );
            data
              ..removeAt(index)
              ..insert(
                index,
                compare > 0 ? element : item,
              );
          } else if (compare == null) {
            data.add(item);
          }
        }
        // data.addAll(event.list);

        final categoryList = <CounterCategory>{};
        for (final item in event.list) {
          if (item.category != null) {
            categoryList.add(item.category!);
          }
        }

        final updateList = CounterCategoryCubit.instance.restoreBackup(
          categoryList.toList(),
        );

        final result = data.map(
          (e) {
            if (updateList.any(
              (element) => e.category?.uuid == element.uuid,
            )) {
              return e.copyWith(
                category: updateList.firstWhere(
                  (element) => e.category?.uuid == element.uuid,
                ),
              );
            } else {
              return e;
            }
          },
        ).toList();

        data
          ..clear()
          ..addAll(result);
        CounterRepository.setIncomeExpenseList(data);
        emit(_loaded());
      },
    );

    on<RestorePreUpdateBackup>((event, emit) {
      final backup = CounterRepository.getIncomeExpenseBackup();
      if (backup == null) {
        return;
      }
      data
        ..clear()
        ..addAll(_withDefaultCategories(backup));
      CounterRepository.setIncomeExpenseList(data);
      // The snapshot has served its purpose; drop it so it can't later
      // overwrite newer data and the restore option disappears.
      CounterRepository.clearIncomeExpenseBackup();
      emit(_loaded());
    });

    add(InitEvent());
  }

  static CounterBloc instance = CounterBloc._internal();

  final List<IncomeExpense> data = [];
  DateFilter dateFilter = DateFilter.all;

  /// Active free-text search query. Empty means no search is applied.
  String searchQuery = '';

  /// Builds the standard post-mutation state: the master list run through the
  /// active date and search filters, with loading complete.
  CounterState _loaded() => CounterState(
        data: [...filterByDate()],
        dateFilter: dateFilter,
        loading: false,
        searchQuery: searchQuery,
      );

  /// Returns [items] with every uncategorised entry assigned the
  /// type-appropriate fallback category, so the list always has a label.
  static List<IncomeExpense> _withDefaultCategories(List<IncomeExpense> items) {
    final categories = CounterCategoryCubit.instance.state;
    return items
        .map(
          (e) => e.category != null
              ? e
              : e.copyWith(
                  category: defaultCategoryFor(
                    e.amount < 0 ? CategoryType.expense : CategoryType.income,
                    categories,
                  ),
                ),
        )
        .toList();
  }

  /// Fraction of the limit that raises the "approaching" alert.
  static const double _budgetWarnRatio = 0.8;

  List<IncomeExpense> filterByDate() {
    return data.reversed.where(
      (element) {
        if (!_matchesQuery(element)) {
          return false;
        }
        final now = DateTime.now();
        // print('Is same week ${isSameWeek(
        //   now,
        //   element.createdAt,
        // )} now:$now, '
        //     'element:${element.createdAt}');
        if (dateFilter == DateFilter.all) {
          return true;
        } else if (dateFilter == DateFilter.year &&
            element.createdAt.year == now.year) {
          return true;
        } else if (dateFilter == DateFilter.month &&
            isSameMonth(
              now,
              element.createdAt,
            )) {
          return true;
        } else if (dateFilter == DateFilter.week &&
            isSameWeek(
              now,
              element.createdAt,
            )) {
          return true;
        } else if (dateFilter == DateFilter.day &&
            isSameDay(
              now,
              element.createdAt,
            )) {
          return true;
        } else {
          return false;
        }
      },
    ).toList();
  }

  /// Whether [element] matches the active [searchQuery]. An empty query matches
  /// everything. The match is case-insensitive and substring-based against the
  /// entry's description, category name, amount and date, so a single query
  /// like "coffee", "food", "12.50" or "2026-07" narrows the list the same way.
  bool _matchesQuery(IncomeExpense element) {
    final query = searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }
    final locale = LocalizationCubit.instance.state.languageCode;
    final haystack = [
      element.description ?? '',
      element.category?.name ?? '',
      // Both the signed and unsigned amount so "12.5" matches an expense
      // stored as -12.5.
      element.amount.toStringAsFixed(2),
      element.amount.abs().toStringAsFixed(2),
      // Numeric date (locale-independent) plus a spelled-out form so month
      // names in the current language are searchable too.
      DateFormat('yyyy-MM-dd').format(element.createdAt),
      DateFormat.yMMMMd(locale).format(element.createdAt),
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }
}

/// Fires a local notification when a new expense pushes [category]'s
/// month-to-date spend across its budget's 100% or 80% threshold.
///
/// Only the highest threshold newly crossed is announced (so a single large
/// expense that blows straight past both shows one "over budget" alert, not
/// two). Nothing fires when the category has no budget or the threshold was
/// already crossed before this expense. Best-effort: notification failures are
/// swallowed so they can never disrupt saving a transaction.
Future<void> maybeNotifyBudgetThreshold({
  required CounterCategory category,
  required double spentBefore,
  required double spentAfter,
}) async {
  final budget = BudgetCubit.instance.budgetFor(category.uuid);
  if (budget == null) return;
  final limit = budget.limit;
  if (limit <= 0) return;

  final warnAt = limit * CounterBloc._budgetWarnRatio;
  bool crossed(double threshold) =>
      spentBefore < threshold && spentAfter >= threshold;

  final l10n = lookupAppLocalizations(LocalizationCubit.instance.state);
  final symbol = CurrencyCubit.instance.state;

  String? title;
  String? body;
  var id = category.uuid.hashCode & 0x7fffffff;
  if (crossed(limit)) {
    title = l10n.budgetAlertOverTitle(category.name);
    body = l10n.budgetAlertOverBody(
      category.name,
      formatAmount(limit, symbol),
    );
  } else if (crossed(warnAt)) {
    title = l10n.budgetAlertWarnTitle(category.name);
    body = l10n.budgetAlertWarnBody(
      category.name,
      formatAmount(spentAfter, symbol),
      formatAmount(limit, symbol),
    );
    // Distinct id from the "over" alert so the warning is not overwritten if
    // both fire across separate expenses in the same month.
    id ^= 1;
  } else {
    return;
  }

  try {
    await NotificationService().showNotification(
      id: id,
      title: title,
      body: body,
    );
  } on Object {
    // Ignore: a failed budget alert must never block recording an expense.
  }
}
