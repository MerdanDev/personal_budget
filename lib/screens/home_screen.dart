import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/bloc/balance_bloc.dart';
import 'package:personal_budget/bloc/data_bloc.dart' as d;
import 'package:personal_budget/models/tbl_mv_category.dart';
import 'package:personal_budget/screens/category_screen.dart';
import 'package:personal_budget/screens/new_value_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late TooltipBehavior _tooltipBehavior;
  int index = 0;
  @override
  void initState() {
    _tooltipBehavior = TooltipBehavior(enable: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: BlocBuilder<BalanceBloc, BalanceState>(builder: (context, state) {
        if (state is LoadedState) {
          List<ChartData> incomeChartData = state.incomeCats
              .where((element) => element.value > 0)
              .map((e) => ChartData(e.name, e.value))
              .toList();
          List<ChartData> expenseChartData = state.expenseCats
              .where((element) => element.value > 0)
              .map((e) => ChartData(e.name, e.value))
              .toList();
          List<TblMvCategory> currentType = index == 0
              ? state.categories.where((element) => element.type == -1).toList()
              : state.categories.where((element) => element.type == 1).toList();
          double sum = state.incomeCats
                  .map((e) => e.value)
                  .toList()
                  .reduce((value, element) => value + element) -
              state.expenseCats
                  .map((e) => e.value)
                  .toList()
                  .reduce((value, element) => value + element);

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  BlocProvider.of<BalanceBloc>(context).add(LoadEvent());
                },
                child: CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      title: Text(widget.title),
                      pinned: true,
                    ),
                    SliverToBoxAdapter(
                      child: Container(
                        height: 450,
                        width: width,
                        child: PageView(
                          onPageChanged: (int page) {
                            setState(() {
                              index = page;
                            });
                          },
                          children: [
                            expenseChartData.isNotEmpty
                                ? SfCircularChart(
                                    tooltipBehavior: _tooltipBehavior,
                                    legend: Legend(
                                      isVisible: true,
                                    ),
                                    series: <CircularSeries>[
                                      // Render pie chart
                                      PieSeries<ChartData, String>(
                                        dataSource: expenseChartData,
                                        radius: '75%',
                                        enableTooltip: true,
                                        pointColorMapper: (ChartData data, _) =>
                                            data.color,
                                        xValueMapper: (ChartData data, _) =>
                                            data.x,
                                        yValueMapper: (ChartData data, _) =>
                                            data.y,
                                        dataLabelMapper: (ChartData data, _) =>
                                            data.x,
                                        explode: true,
                                        dataLabelSettings: DataLabelSettings(
                                          isVisible: true,
                                          labelIntersectAction:
                                              LabelIntersectAction.shift,
                                          labelPosition:
                                              ChartDataLabelPosition.inside,
                                          useSeriesColor: true,
                                        ),
                                      )
                                    ],
                                  )
                                : Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Maglumatlar ýazylmadyk! Maglumat girizmegiňizi sizden haýyş edýäris.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                            incomeChartData.isNotEmpty
                                ? SfCircularChart(
                                    tooltipBehavior: _tooltipBehavior,
                                    legend: Legend(
                                      isVisible: true,
                                    ),
                                    series: <CircularSeries>[
                                      // Render pie chart
                                      PieSeries<ChartData, String>(
                                        dataSource: incomeChartData,
                                        radius: '75%',
                                        enableTooltip: true,
                                        pointColorMapper: (ChartData data, _) =>
                                            data.color,
                                        xValueMapper: (ChartData data, _) =>
                                            data.x,
                                        yValueMapper: (ChartData data, _) =>
                                            data.y,
                                        dataLabelMapper: (ChartData data, _) =>
                                            data.x,
                                        explode: true,
                                        dataLabelSettings: DataLabelSettings(
                                          isVisible: true,
                                          labelIntersectAction:
                                              LabelIntersectAction.shift,
                                          labelPosition:
                                              ChartDataLabelPosition.inside,
                                          useSeriesColor: true,
                                        ),
                                      )
                                    ],
                                  )
                                : Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: Text(
                                        'Maglumatlar ýazylmadyk! Maglumat girizmegiňizi sizden haýyş edýäris.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.green,
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Container(
                              padding: EdgeInsets.all(8.0),
                              width: 80,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.all(0.0),
                                ),
                                onPressed: () {
                                  BlocProvider.of<d.DataBloc>(context).add(
                                    d.LoadEvent(
                                      account: state.account,
                                      category: currentType[index],
                                    ),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CategoryScreen(
                                        category: currentType[index],
                                      ),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                      ),
                                      child: Image.memory(
                                          currentType[index].image),
                                    ),
                                    Container(
                                      child: Text(
                                        currentType[index].name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black,
                                          // fontSize: 10,
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                          itemCount: currentType.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 75,
                      width: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: TextButton(
                        key: null,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewValueScreen(
                                key: Key('expense'),
                                type: -1,
                                categories: state.categories
                                    .where((element) => element.type == -1)
                                    .toList(),
                                accounts: state.accounts,
                              ),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.remove,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(35),
                      ),
                      alignment: Alignment.center,
                      height: 75,
                      width: 180,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'BALANCE: $sum',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      height: 75,
                      width: 75,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.all(8.0),
                        ),
                        key: null,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NewValueScreen(
                                key: Key('income'),
                                type: 1,
                                categories: state.categories
                                    .where((element) => element.type == 1)
                                    .toList(),
                                accounts: state.accounts,
                              ),
                            ),
                          );
                        },
                        child: Icon(
                          Icons.add,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        } else if (state is LoadingState) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        return Text('data');
      }), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ChartData {
  ChartData(this.x, this.y, [this.color]);
  final String x;
  final double y;
  final Color? color;
}
