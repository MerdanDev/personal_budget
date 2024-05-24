import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/presentation/category_select_screen.dart';
import 'package:wallet/counter/presentation/widgets/income_expense_widget.dart';

class IncomeExpenseScreen extends StatefulWidget {
  const IncomeExpenseScreen({required this.category, super.key});

  final CounterCategory category;

  @override
  State<IncomeExpenseScreen> createState() => _IncomeExpenseScreenState();
}

class _IncomeExpenseScreenState extends State<IncomeExpenseScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<CategorySelectScreen>(
                  builder: (context) {
                    return CategorySelectScreen(category: widget.category);
                  },
                ),
              );
            },
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: BlocBuilder<CounterBloc, CounterState>(
        bloc: CounterBloc.instance,
        builder: (context, state) {
          final data = CounterBloc.instance.data
              .where(
                (e) => e.category == widget.category,
              )
              .toList();
          return ListView.builder(
            itemBuilder: (context, index) {
              return IncomeExpenseWidget(element: data[index]);
            },
            itemCount: data.length,
          );
        },
      ),
    );
  }
}
