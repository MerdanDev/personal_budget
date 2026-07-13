import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/counter/cubit/budget_cubit.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/l10n/l10n.dart';

/// Prompts the user for [category]'s monthly limit and persists it via
/// [BudgetCubit]. Pre-fills the field from [existing] when editing. A blank or
/// zero value clears the budget (the cubit treats `<= 0` as "remove").
///
/// Shared by the Budgets page and the charts page so both edit budgets the
/// same way.
Future<void> showBudgetEditor(
  BuildContext context,
  CounterCategory category,
  CategoryBudget? existing,
) async {
  final controller = TextEditingController(
    text: existing != null ? _trimZeros(existing.limit) : '',
  );
  final result = await showDialog<double>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(category.name),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: context.l10n.monthlyLimit,
            border: const OutlineInputBorder(),
            suffixText: CurrencyCubit.instance.state,
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              // 0 (promoted to 0.0 in this double context) clears the budget.
              onPressed: () => Navigator.pop<double>(context, 0),
              child: Text(
                context.l10n.removeBudget,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              Navigator.pop<double>(context, value ?? 0);
            },
            child: Text(context.l10n.save),
          ),
        ],
      );
    },
  );
  if (result == null) return;
  // A zero/blank limit clears the budget; the cubit treats <= 0 as "remove".
  BudgetCubit.instance.setBudget(categoryUuid: category.uuid, limit: result);
}

/// Renders a limit without a trailing `.0`, so editing shows `50` not `50.0`.
String _trimZeros(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toString();
}
