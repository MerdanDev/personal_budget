import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/counter/cubit/category_cubit.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/presentation/income_expense_screen.dart';
import 'package:wallet/counter/presentation/widgets/add_category_dialog.dart';
import 'package:wallet/counter/presentation/widgets/category_icon_widget.dart';
import 'package:wallet/counter/presentation/widgets/delete_dialog.dart';
import 'package:wallet/l10n/l10n.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.categories),
        actions: [
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return const AddCounterCategoryDialog(
                    isMinus: true,
                  );
                },
              );
            },
            icon: const Icon(
              Icons.remove,
              color: Colors.red,
            ),
          ),
          IconButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (context) {
                  return const AddCounterCategoryDialog(
                    isMinus: false,
                  );
                },
              );
            },
            icon: const Icon(
              Icons.add,
              color: Colors.green,
            ),
          ),
        ],
      ),
      body: BlocBuilder<CounterCategoryCubit, List<CounterCategory>>(
        bloc: CounterCategoryCubit.instance,
        builder: (context, state) {
          return ListView.builder(
            itemCount: state.length,
            itemBuilder: (context, index) {
              final category = state[index];
              return Dismissible(
                key: Key(category.uuid),
                background: ColoredBox(
                  color: Colors.red.withOpacity(0.4),
                ),
                confirmDismiss: (direction) async {
                  final result = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return const DeleteDialog();
                    },
                  );
                  return result;
                },
                onDismissed: (direction) {
                  CounterCategoryCubit.instance.deleteCategory(
                    uuid: category.uuid,
                  );
                },
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<IncomeExpenseScreen>(
                        builder: (context) {
                          return IncomeExpenseScreen(category: category);
                        },
                      ),
                    );
                  },
                  leading: category.iconCode != null
                      ? CategoryIcon(
                          iconCode: category.iconCode!,
                          colorCode: category.colorCode,
                        )
                      : null,
                  title: Text(category.name),
                  subtitle: Text(
                    category.type.name,
                    style: TextStyle(
                      color: category.type == CategoryType.income
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  trailing: IconButton(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) {
                          return AddCounterCategoryDialog(
                            isMinus: category.type == CategoryType.expense,
                            value: category,
                          );
                        },
                      );
                    },
                    icon: const Icon(Icons.edit),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
