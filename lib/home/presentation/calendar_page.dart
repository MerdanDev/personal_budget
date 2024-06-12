import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/l10n/l10n.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final EventController<IncomeExpense> _controller = EventController();

  @override
  void initState() {
    final events = CounterBloc.instance.data
        .map(
          (e) => CalendarEventData(
            title: '${e.amount} - ${e.title}',
            description: e.description,
            event: e,
            date: e.createdAt,
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

    return Scaffold(
      body: MonthView<IncomeExpense>(
        controller: _controller,
        borderColor: cls.outlineVariant,
        headerBuilder: (date) => MonthPageHeader(
          date: date,
          backgroundColor: cls.primaryContainer,
          iconColor: cls.onPrimaryContainer,
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
        cellBuilder: (date, events, isToday, isInMonth) => FilledCell(
          date: date,
          onTileTap: (event, date) {
            showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          events: events,
          shouldHighlight: isToday,
          titleColor: isInMonth ? cls.onSurface : cls.onSurfaceVariant,
          backgroundColor: isInMonth ? cls.surface : cls.surfaceVariant,
        ),
      ),
    );
  }
}

class CalendarDayScreen extends StatefulWidget {
  const CalendarDayScreen({required this.date, super.key});

  final DateTime date;

  @override
  State<CalendarDayScreen> createState() => _CalendarDayScreenState();
}

class _CalendarDayScreenState extends State<CalendarDayScreen> {
  final EventController<IncomeExpense> _controller = EventController();

  @override
  void initState() {
    final events = CounterBloc.instance.data
        .map(
          (e) => CalendarEventData(
            title: '${e.amount} - ${e.title}',
            description: e.description,
            event: e,
            date: e.createdAt,
            startTime: e.createdAt,
            titleStyle: const TextStyle(
              fontSize: 12,
            ),
            endTime: e.createdAt.add(const Duration(hours: 1)),
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
    return Scaffold(
      body: DayView<IncomeExpense>(
        initialDay: widget.date,
        controller: _controller,
        backgroundColor: cls.surface,
        dayTitleBuilder: (date) => DayPageHeader(
          date: date,
          backgroundColor: cls.surface,
          iconColor: cls.onSurface,
          dateStringBuilder: (date, {secondaryDate}) {
            return '${date.year} '
                '${DateFormat('MMMM', locale).format(date)} '
                '${date.day}';
          },
        ),
        timeLineBuilder: (date) {
          return DefaultTimeLineMark(
            date: date,
            timeStringBuilder: (date, {secondaryDate}) {
              return DateFormat('HH:mm', locale).format(date);
            },
          );
        },
        eventTileBuilder: (date, events, boundary, startDuration, endDuration) {
          return Card(
            color: Theme.of(context).colorScheme.primary,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                events.first.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          );
        },
        onEventTap: (events, date) {
          showDialog<void>(
            context: context,
            builder: (context) => Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      events.first.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
