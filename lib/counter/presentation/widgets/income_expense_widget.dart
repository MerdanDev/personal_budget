import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/core/currency_cubit.dart';
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
    final symbol = context.watch<CurrencyCubit>().state;
    return Dismissible(
      key: Key(element.uuid),
      background: ColoredBox(
        color: Colors.red.withValues(alpha: 0.4),
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
        title: Row(
          children: [
            if (element.category?.iconCode != null) ...[
              CategoryIcon(
                iconCode: element.category!.iconCode!,
                colorCode: element.category!.colorCode,
                size: 18,
              ),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(
                '${formatAmount(element.amount, symbol)}'
                ' : ${element.category?.name ?? ''}',
              ),
            ),
          ],
        ),
        subtitle: element.description != null
            ? Text(
                element.description!,
                maxLines: 3,
              )
            : null,
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
      ),
    );
  }
}
