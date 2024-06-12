import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/presentation/widgets/add_income_expense_dialog.dart';
import 'package:wallet/counter/presentation/widgets/category_icon_widget.dart';
import 'package:wallet/counter/presentation/widgets/delete_dialog.dart';

class IncomeExpenseWidget extends StatelessWidget {
  const IncomeExpenseWidget({required this.element, super.key});

  final IncomeExpense element;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(element.uuid),
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
        context.read<CounterBloc>().add(
              RemoveEvent(element.uuid),
            );
      },
      child: ListTile(
        leading: element.amount > 0
            ? const Icon(
                Icons.arrow_upward_rounded,
                color: Colors.greenAccent,
              )
            : const Icon(
                Icons.arrow_downward_rounded,
                color: Colors.redAccent,
              ),
        title: Text(
          '${element.amount.toStringAsFixed(2)}'
          ' : ${element.title ?? ''}',
        ),
        subtitle: RichText(
          text: TextSpan(
            children: [
              if (element.category != null)
                WidgetSpan(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (element.category!.iconCode != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: CategoryIcon(
                                iconCode: element.category!.iconCode!,
                                colorCode: element.category!.colorCode,
                              ),
                            ),
                          Text(element.category!.name),
                        ],
                      ),
                    ),
                  ),
                ),
              if (element.description != null)
                TextSpan(text: element.description),
            ],
          ),
        ),
        trailing: IconButton(
          onPressed: () {
            showDialog<void>(
              context: context,
              builder: (context) {
                return IncomeExpenseDialog(
                  isMinus: element.amount < 0,
                  value: element,
                );
              },
            );
          },
          icon: const Icon(Icons.edit),
        ),
        // trailing: element.category != null
        //     ? Icon(IconData(element.category!.iconCode!), )
        //     : null,
      ),
    );
  }
}
