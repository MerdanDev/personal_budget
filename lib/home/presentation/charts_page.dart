import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:wallet/core/utils.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/cubit/category_cubit.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/income_expense.dart';
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
                text: context.l10n.candleChart,
                icon: const Icon(Icons.candlestick_chart_outlined),
              ),
              Tab(
                text: context.l10n.radialChart,
                icon: const Icon(Icons.radar_outlined),
              ),
            ],
          ),
        ),
        body: BlocBuilder<CounterBloc, CounterState>(
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
              pageDataList.insert(
                0,
                ChartPageDate(
                  startingAmount: amount,
                  data: pageData,
                  date: pageDate,
                ),
              );
            }

            return SafeArea(
              child: PageView.builder(
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
                        height: 350,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 16, left: 6),
                          child: current == 0
                              ? CandleChartWidget(
                                  data: pageData.data,
                                  date: pageData.date,
                                  amount: pageData.startingAmount,
                                )
                              : PieChartWidget(
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
              ),
            );
          },
        ),
      ),
    );
  }
}

class PieChartWidget extends StatefulWidget {
  const PieChartWidget({required this.data, super.key});

  final List<IncomeExpense> data;

  @override
  State<PieChartWidget> createState() => _PieChartWidgetState();
}

class _PieChartWidgetState extends State<PieChartWidget> {
  @override
  Widget build(BuildContext context) {
    final chartData = <_PieChartData>[];
    final categories = CounterCategoryCubit.instance.state;
    var income = .0;

    for (final category in categories.where(
      (e) => e.type == CategoryType.expense,
    )) {
      final mapped = widget.data
          .where((e) => e.category == category)
          .map((e) => e.amount)
          .toList();
      if (mapped.isNotEmpty) {
        final amount = mapped.reduce((a, b) => a + b);
        chartData.add(
          _PieChartData(
            category.name,
            amount > 0 ? amount : amount * -1,
            mapped.length,
            category.colorCode != null ? Color(category.colorCode!) : null,
          ),
        );
      }
    }
    for (final category in categories.where(
      (e) => e.type == CategoryType.income,
    )) {
      final mapped = widget.data
          .where((e) => e.category == category)
          .map((e) => e.amount)
          .toList();
      if (mapped.isNotEmpty) {
        income += mapped.reduce((a, b) => a + b);
      }
    }
    chartData.add(
      _PieChartData(context.l10n.income, income, 1, Colors.green),
    );
    // final maxCount =
    //     chartData.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    final maxAmount = chartData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    return SfCircularChart(
      tooltipBehavior: TooltipBehavior(
        enable: true,
      ),
      series: <CircularSeries<_PieChartData, String>>[
        RadialBarSeries<_PieChartData, String>(
          dataSource: chartData,
          useSeriesColor: true,
          trackOpacity: 0.3,
          cornerStyle: CornerStyle.bothCurve,
          pointColorMapper: (data, _) => data.color,
          xValueMapper: (data, _) => data.x,
          yValueMapper: (data, _) => data.y,
          dataLabelMapper: (data, _) => data.x,
          maximumValue: maxAmount,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            textStyle: Theme.of(context).textTheme.labelSmall,
            // connectorLineSettings: ConnectorLineSettings(
            //   type: ConnectorType.curve,
            //   length: '25%',
            // ),
          ),
          // pointRadiusMapper: (data, _) => '${(100 / maxCount) * data.count}%',
        ),
      ],
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
  final dataSource = <_CandleChartData>[];
  late final TooltipBehavior _tooltip;
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
      dataSource.add(_CandleChartData(day.toString(), high, low, open, close));
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
      series: <CartesianSeries<_CandleChartData, String>>[
        CandleSeries<_CandleChartData, String>(
          dataSource: dataSource,
          xValueMapper: (_CandleChartData data, _) => data.x,
          highValueMapper: (_CandleChartData data, _) => data.high,
          lowValueMapper: (_CandleChartData data, _) => data.low,
          openValueMapper: (_CandleChartData data, _) => data.open,
          closeValueMapper: (_CandleChartData data, _) => data.close,
          pointColorMapper: (_CandleChartData data, _) {
            if (data.open > data.close) {
              return Colors.red;
            } else if (data.open < data.close) {
              return Colors.green;
            } else {
              return Colors.grey;
            }
          },
          name: context.l10n.counter,
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

class _CandleChartData {
  _CandleChartData(this.x, this.high, this.low, this.open, this.close);

  final String x;
  final double high;
  final double low;
  final double open;
  final double close;
}

class _PieChartData {
  _PieChartData(this.x, this.y, this.count, [this.color]);
  final String x;
  final double y;
  final int count;
  final Color? color;
}
