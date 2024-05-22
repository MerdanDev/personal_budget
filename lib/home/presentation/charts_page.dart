import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/income_expense.dart';

class CandleChartPage extends StatefulWidget {
  const CandleChartPage({super.key});

  @override
  State<StatefulWidget> createState() => CandleChartPageState();
}

class CandleChartPageState extends State<CandleChartPage> {
  late bool isShowingMainData;

  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
      bloc: CounterBloc.instance,
      builder: (context, state) {
        final data = CounterBloc.instance.data
          ..sort(
            (a, b) => a.createdAt.compareTo(b.createdAt),
          );
        final date = data.first.createdAt;
        final now = DateTime.now();
        final itemCount =
            (now.year * 12 + now.month) - (date.year * 12 + date.month) + 1;
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
          final amount =
              filtered.isNotEmpty ? filtered.reduce((a, b) => a + b) : null;
          pageDataList.add(
            ChartPageDate(
              startingAmount: amount,
              data: pageData,
              date: pageDate,
            ),
          );
        }

        return SafeArea(
          child: PageView.builder(
            itemBuilder: (context, index) {
              final pageData = pageDataList[index];
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    '${pageData.date.year} '
                    '${DateFormat('MMMM').format(pageData.date)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 37,
                  ),
                  SizedBox(
                    height: 350,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16, left: 6),
                      child: CandleChartWidget(
                        data: pageData.data,
                        date: pageData.date,
                        amount: pageData.startingAmount,
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
          ),
        );
      },
    );
  }
}

class CandleChartWidget extends StatefulWidget {
  const CandleChartWidget({
    required this.data,
    required this.date,
    required this.amount,
    super.key,
  });

  final List<IncomeExpense> data;
  final DateTime date;
  final double? amount;

  @override
  State<CandleChartWidget> createState() => _CandleChartWidgetState();
}

class _CandleChartWidgetState extends State<CandleChartWidget> {
  final dataSource = <_ChartData>[];
  late final TooltipBehavior _tooltip;
  late double current;
  @override
  void initState() {
    current = widget.amount ?? 0;
    final today = DateTime.now();
    final lastDay = isSameMonth(widget.date, today)
        ? today.day
        : DateTime(widget.date.year, widget.date.month + 1, 0).day;
    var day = widget.amount != null ? 1 : widget.data.first.createdAt.day;
    for (; day <= lastDay; day++) {
      final numbers = <double>[];
      for (var i = 0; i < widget.data.length; i++) {
        if (isSameDay(
          widget.data[i].createdAt,
          DateTime(widget.date.year, widget.date.month, day),
        )) {
          current += widget.data[i].amount;
          numbers.add(current);
        }
      }
      double open;
      double close;
      double high;
      double low;
      if (numbers.isNotEmpty && numbers.length >= 2) {
        if (dataSource.isNotEmpty) {
          open = dataSource.last.close;
        } else {
          open = numbers.first;
        }
        close = numbers.last;
        high = numbers.reduce((a, b) => a < b ? b : a);
        low = numbers.reduce((a, b) => a > b ? b : a);
      } else if (numbers.isNotEmpty) {
        if (dataSource.isNotEmpty) {
          open = dataSource.last.close;
        } else {
          open = widget.amount == null ? 0 : numbers.first;
        }
        close = high = low = numbers.first;
      } else {
        if (dataSource.isEmpty) {
          open = close = high = low = widget.amount ?? 0;
        } else {
          open = close = high = low = dataSource.last.close;
        }
      }
      dataSource.add(_ChartData(day.toString(), high, low, open, close));
    }

    _tooltip = TooltipBehavior(enable: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      primaryXAxis: const CategoryAxis(),
      primaryYAxis: NumericAxis(
        minimum: 0,
        maximum: dataSource.map((e) => e.high).reduce((a, b) => a < b ? b : a),
        interval: 10,
      ),
      tooltipBehavior: _tooltip,
      series: <CartesianSeries<_ChartData, String>>[
        CandleSeries<_ChartData, String>(
          dataSource: dataSource,
          xValueMapper: (_ChartData data, _) => data.x,
          highValueMapper: (_ChartData data, _) => data.high,
          lowValueMapper: (_ChartData data, _) => data.low,
          openValueMapper: (_ChartData data, _) => data.open,
          closeValueMapper: (_ChartData data, _) => data.close,
          pointColorMapper: (_ChartData data, _) {
            if(data.open > data.close){
              return Colors.red;
            } else if(data.open < data.close) {
              return Colors.green;
            } else {
              return Colors.grey;
            }
          },
          name: 'Changes',
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

class _ChartData {
  _ChartData(this.x, this.high, this.low, this.open, this.close);

  final String x;
  final double high;
  final double low;
  final double open;
  final double close;
}
