import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/presentation/widgets/income_expense_widget.dart';
import 'package:wallet/l10n/l10n.dart';

/// Resolves the display color for a transaction: its category color when set,
/// otherwise a green/red fallback keyed off the income/expense sign.
Color eventColor(IncomeExpense e) {
  final code = e.category?.colorCode;
  if (code != null) return Color(code);
  return e.amount >= 0 ? Colors.green.shade600 : Colors.red.shade600;
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final EventController<IncomeExpense> _controller = EventController();
  final GlobalKey<MonthViewState<IncomeExpense>> _monthViewKey = GlobalKey();

  @override
  void initState() {
    final events = CounterBloc.instance.data
        .map(
          (e) => CalendarEventData(
            // The per-event tile only needs a short label; the day's net is
            // shown as a badge on the cell instead of repeating amounts here.
            title: e.category?.name ?? e.amount.toStringAsFixed(0),
            description: e.description,
            event: e,
            date: e.createdAt,
            color: eventColor(e),
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        )
        .toList();
    _controller.addAll(events);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final cls = Theme.of(context).colorScheme;
    final locale = context.l10n.localeName;
    final symbol = context.watch<CurrencyCubit>().state;

    return Scaffold(
      body: MonthView<IncomeExpense>(
        key: _monthViewKey,
        controller: _controller,
        borderColor: cls.outlineVariant,
        headerBuilder: (date) => MonthPageHeader(
          date: date,
          onPreviousMonth: () => _monthViewKey.currentState?.previousPage(),
          onNextMonth: () => _monthViewKey.currentState?.nextPage(),
          headerStyle: HeaderStyle(
            decoration: BoxDecoration(color: cls.primaryContainer),
            leftIconConfig: IconDataConfig(color: cls.onPrimaryContainer),
            rightIconConfig: IconDataConfig(color: cls.onPrimaryContainer),
          ),
          dateStringBuilder: (date, {secondaryDate}) {
            return '${date.year} '
                '${DateFormat('MMMM', locale).format(date)}';
          },
        ),
        onCellTap: (events, date) {
          Navigator.of(context).push(
            MaterialPageRoute<CalendarDayScreen>(
              builder: (context) => CalendarDayScreen(date: date),
            ),
          );
        },
        weekDayBuilder: (dayIndex) => WeekDayTile(
          dayIndex: dayIndex,
          backgroundColor: cls.surface,
          textStyle: TextStyle(color: cls.onSurface),
          weekDayStringBuilder: (weekDay) {
            final date = DateTime(2024, 1, weekDay);
            return DateFormat.E(locale).format(date);
          },
          // WeekDayTile doesn't have a borderColor parameter
        ),
        cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) =>
            Stack(
          children: [
            Positioned.fill(
              child: FilledCell(
                date: date,
                onTileTap: (event, date) {
                  Navigator.of(context).push(
                    MaterialPageRoute<CalendarDayScreen>(
                      builder: (context) => CalendarDayScreen(date: date),
                    ),
                  );
                },
                events: events,
                shouldHighlight: isToday,
                titleColor: isInMonth ? cls.onSurface : cls.onSurfaceVariant,
                backgroundColor:
                    isInMonth ? cls.surface : cls.surfaceContainerHighest,
              ),
            ),
            if (isInMonth)
              Positioned(
                top: 2,
                right: 2,
                child: _NetBadge(events: events, symbol: symbol),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact green/red pill showing the net (income − expense) for a single
/// calendar cell. Renders nothing when the day has no transactions.
class _NetBadge extends StatelessWidget {
  const _NetBadge({required this.events, required this.symbol});

  final List<CalendarEventData<IncomeExpense>> events;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) return const SizedBox.shrink();
    final net = events.fold<double>(
      0,
      (sum, e) => sum + (e.event?.amount ?? 0),
    );
    if (net == 0) return const SizedBox.shrink();

    final isPositive = net > 0;
    final color = isPositive ? Colors.green.shade600 : Colors.red.shade600;
    final sign = isPositive ? '+' : '−';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 56),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: FittedBox(
          child: Text(
            '$sign${net.abs().toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class CalendarDayScreen extends StatelessWidget {
  const CalendarDayScreen({required this.date, super.key});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    final symbol = context.watch<CurrencyCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${date.year} '
          '${DateFormat('MMMM', locale).format(date)} '
          '${date.day}',
        ),
      ),
      body: BlocBuilder<CounterBloc, CounterState>(
        bloc: CounterBloc.instance,
        builder: (context, state) {
          final items = CounterBloc.instance.data
              .where((e) => isSameDay(e.createdAt, date))
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          final income = items
              .where((e) => e.amount > 0)
              .fold<double>(0, (s, e) => s + e.amount);
          final expense = items
              .where((e) => e.amount < 0)
              .fold<double>(0, (s, e) => s + e.amount);

          return Column(
            children: [
              _DaySummary(
                income: income,
                expense: expense,
                symbol: symbol,
              ),
              const Divider(height: 1),
              Expanded(
                child: items.isEmpty
                    ? Center(child: Text(context.l10n.noData))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) => IncomeExpenseWidget(
                          element: items[index],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Header showing the day's total income, expense and resulting balance.
class _DaySummary extends StatelessWidget {
  const _DaySummary({
    required this.income,
    required this.expense,
    required this.symbol,
  });

  final double income;
  final double expense;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final balance = income + expense;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryCell(
            label: l10n.income,
            amount: income,
            symbol: symbol,
            color: Colors.green.shade600,
          ),
          _SummaryCell(
            label: l10n.expense,
            amount: expense.abs(),
            symbol: symbol,
            color: Colors.red.shade600,
          ),
          _SummaryCell(
            label: l10n.balance,
            amount: balance,
            symbol: symbol,
            color: balance >= 0 ? Colors.green.shade600 : Colors.red.shade600,
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.amount,
    required this.symbol,
    required this.color,
  });

  final String label;
  final double amount;
  final String symbol;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          formatAmount(amount, symbol),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
