import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/presentation/widgets/category_icon_widget.dart';
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
          // The cell renders its own net figure and category dots, so the
          // event only needs to carry the domain payload and its date.
          (e) => CalendarEventData(
            title: e.category?.name ?? e.amount.toStringAsFixed(0),
            description: e.description,
            event: e,
            date: e.createdAt,
            color: eventColor(e),
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

    // Constrain paging to the span of months that actually hold records (plus
    // the current month, so today is always reachable). This stops the user
    // scrolling endlessly into empty past/future months.
    DateTime monthOf(DateTime d) => DateTime(d.year, d.month);
    final now = monthOf(DateTime.now());
    var minMonth = now;
    var maxMonth = now;
    for (final e in CounterBloc.instance.data) {
      final m = monthOf(e.createdAt);
      if (m.isBefore(minMonth)) minMonth = m;
      if (m.isAfter(maxMonth)) maxMonth = m;
    }

    return Scaffold(
      body: MonthView<IncomeExpense>(
        key: _monthViewKey,
        controller: _controller,
        minMonth: minMonth,
        maxMonth: maxMonth,
        // Let the grid breathe over the full height and keep only a hairline
        // separator, so the month reads as an open Material grid rather than a
        // dense boxed table.
        useAvailableVerticalSpace: true,
        borderSize: 0.5,
        borderColor: cls.outlineVariant.withValues(alpha: 0.4),
        headerBuilder: (date) {
          // Hide an arrow once the edge month is reached, so there's nothing to
          // tap toward a month without records.
          final canGoBack = monthOf(date).isAfter(minMonth);
          final canGoForward = monthOf(date).isBefore(maxMonth);
          return MonthPageHeader(
            date: date,
            onPreviousMonth: () => _monthViewKey.currentState?.previousPage(),
            onNextMonth: () => _monthViewKey.currentState?.nextPage(),
            headerStyle: HeaderStyle(
              decoration: BoxDecoration(color: cls.surface),
              titleAlign: TextAlign.left,
              headerPadding: !canGoBack
                  ? const EdgeInsets.only(left: 56)
                  : EdgeInsets.zero,
              headerTextStyle: TextStyle(
                color: cls.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
              // A null config hides the arrow at the edge of the record range.
              leftIconConfig: canGoBack
                  ? IconDataConfig(color: cls.onSurfaceVariant)
                  : null,
              rightIconConfig: canGoForward
                  ? IconDataConfig(color: cls.onSurfaceVariant)
                  : null,
            ),
            dateStringBuilder: (date, {secondaryDate}) {
              return '${DateFormat('MMMM', locale).format(date)} ${date.year}';
            },
          );
        },
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
          // Drop the boxed grid on the weekday row; the labels read as a clean
          // caption over the grid, per Material's calendar guidance.
          displayBorder: false,
          textStyle: TextStyle(
            color: cls.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          weekDayStringBuilder: (weekDay) {
            // The grid starts on Monday, so column 0 is Monday. 2024-01-01 was
            // a Monday, which keeps the label aligned with the actual column.
            final date = DateTime(2024, 1, weekDay + 1);
            return DateFormat.E(locale).format(date);
          },
          // WeekDayTile doesn't have a borderColor parameter
        ),
        cellBuilder: (date, events, isToday, isInMonth, hideDaysNotInMonth) =>
            _DayCell(
          date: date,
          events: events,
          isToday: isToday,
          isInMonth: isInMonth,
          symbol: symbol,
        ),
      ),
    );
  }
}

/// One transaction category present on a day, with the colour and glyph used
/// to render its pill. Amounts are aggregated so a category that appears in
/// several transactions shows once.
class _DayCategory {
  _DayCategory({
    required this.name,
    required this.color,
    required this.iconCode,
    required this.amount,
  });

  final String name;
  final Color color;
  final int iconCode;
  double amount;
}

/// A single month-view day, styled after a clean Material calendar: a bold day
/// number up top (today sits in a filled accent circle), the day's net below
/// it as the prominent figure, and the day's categories as icon chips.
/// Tapping is handled by [MonthView.onCellTap], so this widget stays purely
/// presentational.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.events,
    required this.isToday,
    required this.isInMonth,
    required this.symbol,
  });

  final DateTime date;
  final List<CalendarEventData<IncomeExpense>> events;
  final bool isToday;
  final bool isInMonth;
  final String symbol;

  /// Icon chips wrap onto two rows before the rest collapse into a "+N" marker.
  static const _maxIcons = 6;

  @override
  Widget build(BuildContext context) {
    final cls = Theme.of(context).colorScheme;

    // Group the day's transactions by category, preserving first-seen order,
    // so each category shows as a single chip rather than one per transaction.
    final categories = <String, _DayCategory>{};
    for (final e in events) {
      final event = e.event;
      if (event == null) continue;
      final key = event.category?.uuid ?? (event.amount >= 0 ? '+' : '-');
      final existing = categories[key];
      if (existing != null) {
        existing.amount += event.amount;
      } else {
        categories[key] = _DayCategory(
          name: event.category?.name ?? event.amount.toStringAsFixed(0),
          color: eventColor(event),
          iconCode: event.category?.iconCode ?? 0,
          amount: event.amount,
        );
      }
    }
    final chips = categories.values.toList();
    final overflow = chips.length - _maxIcons;

    final net = events.fold<double>(
      0,
      (sum, e) => sum + (e.event?.amount ?? 0),
    );

    final dayColor =
        isInMonth ? cls.onSurface : cls.onSurfaceVariant.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day number, centred like the reference calendar. Today is wrapped
          // in a filled accent chip.
          SizedBox(
            height: 24,
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: isToday
                    ? BoxDecoration(
                        color: cls.primary,
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: isToday ? cls.onPrimary : dayColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (net != 0)
            Padding(
              padding: const EdgeInsets.only(top: 1, bottom: 3),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${net > 0 ? '+' : '−'}${formatAmount(net.abs(), symbol)}',
                  style: TextStyle(
                    color:
                        net > 0 ? Colors.green.shade600 : Colors.red.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          if (chips.isNotEmpty)
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 3,
              runSpacing: 3,
              children: [
                for (final c in chips.take(_maxIcons))
                  _CategoryChip(category: c),
                if (overflow > 0)
                  SizedBox(
                    height: 20,
                    child: Center(
                      child: Text(
                        '+$overflow',
                        style: TextStyle(
                          fontSize: 10,
                          color: cls.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A compact square chip showing a single category's icon in its colour over a
/// tint of that colour — the day's category key, without labels.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final _DayCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: CategoryIcon(
        iconCode: category.iconCode,
        colorCode: category.color.toARGB32(),
        size: 13,
      ),
    );
  }
}

/// A swipeable day view: each page is one day's transactions. Paging is
/// bounded to the span of days that hold records (plus the day the user tapped,
/// so it's always reachable), preventing swipes into empty past/future days.
class CalendarDayScreen extends StatefulWidget {
  const CalendarDayScreen({required this.date, super.key});

  final DateTime date;

  @override
  State<CalendarDayScreen> createState() => _CalendarDayScreenState();
}

class _CalendarDayScreenState extends State<CalendarDayScreen> {
  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Whole calendar days between two dates, DST-safe (hours rounded to days).
  static int _daysBetween(DateTime from, DateTime to) =>
      (_dayOf(to).difference(_dayOf(from)).inHours / 24).round();

  late final DateTime _minDay;
  late final DateTime _maxDay;
  late final PageController _controller;
  late DateTime _current;

  @override
  void initState() {
    super.initState();
    final tapped = _dayOf(widget.date);
    var min = tapped;
    var max = tapped;
    for (final e in CounterBloc.instance.data) {
      final d = _dayOf(e.createdAt);
      if (d.isBefore(min)) min = d;
      if (d.isAfter(max)) max = d;
    }
    _minDay = min;
    _maxDay = max;
    _current = tapped;
    _controller = PageController(initialPage: _daysBetween(min, tapped));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime _dayAt(int index) =>
      DateTime(_minDay.year, _minDay.month, _minDay.day + index);

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    final symbol = context.watch<CurrencyCubit>().state;
    final count = _daysBetween(_minDay, _maxDay) + 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${_current.year} '
          '${DateFormat('MMMM', locale).format(_current)} '
          '${_current.day}',
        ),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: count,
        onPageChanged: (index) => setState(() => _current = _dayAt(index)),
        itemBuilder: (context, index) =>
            _DayView(date: _dayAt(index), symbol: symbol),
      ),
    );
  }
}

/// The totals and transaction list for a single day — one page of
/// [CalendarDayScreen]'s day pager.
class _DayView extends StatelessWidget {
  const _DayView({required this.date, required this.symbol});

  final DateTime date;
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
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
