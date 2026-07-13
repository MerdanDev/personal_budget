import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/cubit/budget_cubit.dart';
import 'package:wallet/counter/cubit/category_cubit.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/presentation/widgets/budget_editor.dart';
import 'package:wallet/counter/presentation/widgets/category_icon_widget.dart';
import 'package:wallet/l10n/l10n.dart';

class CandleChartPage extends StatefulWidget {
  const CandleChartPage({super.key});

  @override
  State<StatefulWidget> createState() => CandleChartPageState();
}

class CandleChartPageState extends State<CandleChartPage> {
  late bool isShowingMainData;
  int current = 0;

  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
  }

  @override
  Widget build(BuildContext context) {
    // Use most of the available screen height instead of a fixed 450px box, so
    // the budget-progress list has room to breathe on tall phones.
    final areaHeight =
        (MediaQuery.sizeOf(context).height * 0.68).clamp(420.0, 720.0);
    final chartHeight = areaHeight - 90;
    return DefaultTabController(
      length: 2,
      initialIndex: current,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.charts),
          bottom: TabBar(
            onTap: (value) {
              setState(() {
                current = value;
              });
            },
            tabs: [
              Tab(
                text: context.l10n.balance,
                icon: const Icon(Icons.show_chart),
              ),
              Tab(
                text: context.l10n.budgets,
                icon: const Icon(Icons.savings_outlined),
              ),
            ],
          ),
        ),
        body: SingleChildScrollView(
          child: SizedBox(
            height: areaHeight,
            child: BlocBuilder<CounterBloc, CounterState>(
              bloc: CounterBloc.instance,
              builder: (context, state) {
                if (CounterBloc.instance.data.isEmpty) {
                  return Center(
                    child: Text(context.l10n.noData),
                  );
                }
                final data = CounterBloc.instance.data
                  ..sort(
                    (a, b) => a.createdAt.compareTo(b.createdAt),
                  );
                final date =
                    data.isNotEmpty ? data.first.createdAt : DateTime.now();
                final now = DateTime.now();
                final itemCount = (now.year * 12 + now.month) -
                    (date.year * 12 + date.month) +
                    1;
                final pageDataList = <ChartPageDate<IncomeExpense>>[];

                for (var i = 0; i < itemCount; i++) {
                  final monthCount = (date.year * 12 + date.month) + i;
                  final pageDate = DateTime(monthCount ~/ 12, monthCount % 12);
                  final pageData = data
                      .where(
                        (element) => isSameMonth(
                          pageDate,
                          element.createdAt,
                        ),
                      )
                      .toList();
                  final filtered = data
                      .where((e) => pageDate.compareTo(e.createdAt) == 1)
                      .map((e) => e.amount);
                  final amount = filtered.isNotEmpty
                      ? filtered.reduce((a, b) => a + b)
                      : null;
                  pageDataList.insert(
                    0,
                    ChartPageDate(
                      startingAmount: amount,
                      data: pageData,
                      date: pageDate,
                    ),
                  );
                }

                return PageView.builder(
                  reverse: true,
                  itemBuilder: (context, index) {
                    final pageData = pageDataList[index];
                    final locale = context.l10n.localeName;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          '${pageData.date.year} '
                          '${DateFormat('MMMM', locale).format(pageData.date)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        SizedBox(
                          height: chartHeight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16, left: 6),
                            child: current == 0
                                ? BalanceChartWidget(
                                    data: pageData.data,
                                    date: pageData.date,
                                    amount: pageData.startingAmount,
                                  )
                                : RadialChartWidget(
                                    data: pageData.data,
                                  ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    );
                  },
                  itemCount: pageDataList.length,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class RadialChartWidget extends StatefulWidget {
  const RadialChartWidget({required this.data, super.key});

  final List<IncomeExpense> data;

  @override
  State<RadialChartWidget> createState() => _RadialChartWidgetState();
}

class _RadialChartWidgetState extends State<RadialChartWidget> {
  /// Total spent (as a positive amount) for [category] within this page's
  /// month. Expenses are stored as negative amounts, so only those are summed.
  double _spentFor(CounterCategory category) {
    var spent = 0.0;
    for (final e in widget.data) {
      if (e.category?.uuid == category.uuid && e.amount < 0) {
        spent += e.amount.abs();
      }
    }
    return spent;
  }

  Future<void> _edit(CounterCategory category, CategoryBudget? existing) async {
    await showBudgetEditor(context, category, existing);
    // The editor mutates BudgetCubit; rebuild so the new limit is reflected.
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Budget progress is shown as one horizontal bar per category — clearer to
    // track than concentric rings, where equal percentages look unequal because
    // inner rings are shorter. Categories with spending but no budget are
    // listed below with an "add budget" action so a limit can be set here.
    final budgeted = <CounterCategory>[];
    final unbudgeted = <CounterCategory>[];

    for (final category in CounterCategoryCubit.instance.state
        .where((e) => e.type == CategoryType.expense)) {
      final budget = BudgetCubit.instance.budgetFor(category.uuid);
      if (budget != null && budget.limit > 0) {
        budgeted.add(category);
      } else if (_spentFor(category) > 0) {
        // Only surface categories the user actually spent in this month.
        unbudgeted.add(category);
      }
    }

    if (budgeted.isEmpty && unbudgeted.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            context.l10n.budgetChartUnassignedNotice,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      children: [
        if (budgeted.isNotEmpty) ...[
          _OverallBudgetSummary(
            totalSpent: budgeted.fold<double>(0, (s, c) => s + _spentFor(c)),
            totalLimit: budgeted.fold<double>(
              0,
              (s, c) => s + BudgetCubit.instance.budgetFor(c.uuid)!.limit,
            ),
          ),
          const SizedBox(height: 8),
          for (final c in budgeted)
            _BudgetProgressTile(
              category: c,
              spent: _spentFor(c),
              budget: BudgetCubit.instance.budgetFor(c.uuid),
              onTap: () => _edit(c, BudgetCubit.instance.budgetFor(c.uuid)),
            ),
        ],
        if (unbudgeted.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
            child: Text(
              context.l10n.budgetChartUnassignedNotice,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final c in unbudgeted)
            _BudgetProgressTile(
              category: c,
              spent: _spentFor(c),
              budget: null,
              onTap: () => _edit(c, null),
            ),
        ],
      ],
    );
  }
}

/// A compact card showing the combined budget usage across every budgeted
/// category for the month — an at-a-glance overview above the category rows.
class _OverallBudgetSummary extends StatelessWidget {
  const _OverallBudgetSummary({
    required this.totalSpent,
    required this.totalLimit,
  });

  final double totalSpent;
  final double totalLimit;

  @override
  Widget build(BuildContext context) {
    final cls = Theme.of(context).colorScheme;
    final symbol = CurrencyCubit.instance.state;
    final ratio = totalLimit <= 0 ? 0.0 : totalSpent / totalLimit;
    final over = totalSpent > totalLimit;
    final color = over
        ? cls.error
        : ratio >= 0.8
            ? Colors.orange
            : cls.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cls.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.budgets,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  color: over ? cls.error : cls.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: cls.surface,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.budgetSpentOfLimit(
              formatAmount(totalSpent, symbol),
              formatAmount(totalLimit, symbol),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable row of the budget tracker. With a [budget] it shows a progress
/// bar (spent vs limit, colour-coded by how close to the limit); without one it
/// invites the user to set a limit for [category].
class _BudgetProgressTile extends StatelessWidget {
  const _BudgetProgressTile({
    required this.category,
    required this.spent,
    required this.budget,
    required this.onTap,
  });

  final CounterCategory category;
  final double spent;
  final CategoryBudget? budget;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cls = Theme.of(context).colorScheme;
    final symbol = CurrencyCubit.instance.state;

    final leading = CircleAvatar(
      radius: 18,
      backgroundColor: category.colorCode != null
          ? Color(category.colorCode!).withValues(alpha: 0.15)
          : cls.surfaceContainerHighest,
      child: CategoryIcon(
        iconCode: category.iconCode ?? 0,
        colorCode: category.colorCode,
        size: 20,
      ),
    );

    if (budget == null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.name),
                    Text(
                      context.l10n.noLimitSet,
                      style: TextStyle(color: cls.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.add_circle_outline, color: cls.primary),
            ],
          ),
        ),
      );
    }

    final limit = budget!.limit;
    final ratio = limit <= 0 ? 0.0 : spent / limit;
    final over = spent > limit;
    final Color barColor;
    if (over) {
      barColor = cls.error;
    } else if (ratio >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = cls.primary;
    }

    final remainingLabel = over
        ? context.l10n.budgetOverAmount(formatAmount(spent - limit, symbol))
        : context.l10n
            .budgetRemainingAmount(formatAmount(limit - spent, symbol));

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(category.name)),
                      Text(
                        '${(ratio * 100).round()}%',
                        style: TextStyle(
                          color: over ? cls.error : cls.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: ratio.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor: cls.surfaceContainerHighest,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.budgetSpentOfLimit(
                            formatAmount(spent, symbol),
                            formatAmount(limit, symbol),
                          ),
                          style: TextStyle(color: cls.onSurfaceVariant),
                        ),
                      ),
                      Text(
                        remainingLabel,
                        style: TextStyle(
                          color: over ? cls.error : cls.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BalanceChartWidget extends StatefulWidget {
  const BalanceChartWidget({
    required this.data,
    required this.date,
    required this.amount,
    super.key,
  });

  final List<IncomeExpense> data;
  final DateTime date;
  final double? amount;

  @override
  State<BalanceChartWidget> createState() => _BalanceChartWidgetState();
}

class _BalanceChartWidgetState extends State<BalanceChartWidget> {
  /// Running end-of-day balance for each day of the month. This carries the
  /// balance flat across days with no transactions, so the line reads as a
  /// continuous trend rather than gaps.
  final dataSource = <_BalancePoint>[];
  late double current;

  @override
  void initState() {
    current = widget.amount ?? 0;
    final today = DateTime.now();
    final lastDay = isSameMonth(widget.date, today)
        ? today.day
        : DateTime(widget.date.year, widget.date.month + 1, 0).day;
    var day = widget.amount != null
        ? 1
        : widget.data.isNotEmpty
            ? widget.data.first.createdAt.day
            : 1;
    for (; day <= lastDay; day++) {
      for (var i = 0; i < widget.data.length; i++) {
        if (isSameDay(
          widget.data[i].createdAt,
          DateTime(widget.date.year, widget.date.month, day),
        )) {
          current += widget.data[i].amount;
        }
      }
      dataSource.add(_BalancePoint(day.toString(), current));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cls = Theme.of(context).colorScheme;
    // Color the trend by how the month ended: red if the balance is negative,
    // otherwise the theme's primary — a quick at-a-glance health signal.
    final endedNegative = dataSource.isNotEmpty && dataSource.last.balance < 0;
    final lineColor = endedNegative ? cls.error : cls.primary;

    final tooltip = TooltipBehavior(
      enable: true,
      format: '${context.l10n.day}: point.x\n'
          '${context.l10n.balance}: point.y',
    );
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      tooltipBehavior: tooltip,
      series: <CartesianSeries<_BalancePoint, String>>[
        SplineAreaSeries<_BalancePoint, String>(
          dataSource: dataSource,
          xValueMapper: (_BalancePoint data, _) => data.x,
          yValueMapper: (_BalancePoint data, _) => data.balance,
          name: context.l10n.balance,
          borderColor: lineColor,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              lineColor.withValues(alpha: 0.35),
              lineColor.withValues(alpha: 0.02),
            ],
          ),
        ),
      ],
    );
  }
}

class ChartPageDate<E> {
  ChartPageDate({
    required this.startingAmount,
    required this.data,
    required this.date,
  });
  final DateTime date;
  final List<E> data;
  final double? startingAmount;
}

class _BalancePoint {
  _BalancePoint(this.x, this.balance);

  final String x;
  final double balance;
}
