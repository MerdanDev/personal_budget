import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/counter_category.dart';

class CategorySelectScreen extends StatefulWidget {
  const CategorySelectScreen({required this.category, super.key});

  final CounterCategory category;
  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> {
  final Set<String> selectedItems = {};
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
      ),
      body: BlocBuilder<CounterBloc, CounterState>(
        bloc: CounterBloc.instance,
        builder: (context, state) {
          final data = CounterBloc.instance.data
              .where((e) => e.category == null)
              .toList();
          return ListView.builder(
            itemBuilder: (context, index) {
              final element = data[index];
              final selected = selectedItems.any((e) => e == element.uuid);
              return ListTile(
                leading: IconButton(
                  onPressed: () {
                    if (selected) {
                      selectedItems.remove(element.uuid);
                    } else {
                      selectedItems.add(element.uuid);
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    selected
                        ? Icons.check_box_outlined
                        : Icons.check_box_outline_blank_outlined,
                  ),
                ),
                selected: selected,
                title: Text(
                  '${element.amount.toStringAsFixed(2)}'
                  ' : ${element.title ?? ''}',
                ),
                subtitle: element.description != null
                    ? Text(element.description!)
                    : null,
              );
            },
            itemCount: data.length,
          );
        },
      ),
      floatingActionButton: selectedItems.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                CounterBloc.instance.add(
                  SelectUpdateCategory(
                    uuids: selectedItems.toList(),
                    category: widget.category,
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
