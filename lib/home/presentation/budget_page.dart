import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/counter/cubit/budget_cubit.dart';
import 'package:wallet/counter/cubit/category_cubit.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/presentation/widgets/category_icon_widget.dart';
import 'package:wallet/l10n/l10n.dart';

/// Lists expense categories with their monthly budget progress and lets the
/// user set, edit or clear a per-category limit.
class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.budgets),
      ),
      // Rebuild when categories change (add/remove/rename) and when any budget
      // changes; spent amounts are read live from the CounterBloc on build.
      body: BlocBuilder<CounterCategoryCubit, List<CounterCategory>>(
        bloc: CounterCategoryCubit.instance,
        builder: (context, categories) {
          final expenses =
              categories.where((c) => c.type == CategoryType.expense).toList();
          if (expenses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.l10n.budgetsEmpty,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return BlocBuilder<BudgetCubit, List<CategoryBudget>>(
            bloc: BudgetCubit.instance,
            builder: (context, _) {
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: expenses.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  return _BudgetTile(category: expenses[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _BudgetTile extends StatelessWidget {
  const _BudgetTile({required this.category});

  final CounterCategory category;

  @override
  Widget build(BuildContext context) {
    final cls = Theme.of(context).colorScheme;
    final symbol = CurrencyCubit.instance.state;
    final budget = BudgetCubit.instance.budgetFor(category.uuid);
    final spent = BudgetCubit.spentThisMonth(category.uuid);

    final leading = CircleAvatar(
      backgroundColor: category.colorCode != null
          ? Color(category.colorCode!).withValues(alpha: 0.15)
          : cls.surfaceContainerHighest,
      child: CategoryIcon(
        iconCode: category.iconCode ?? 0,
        colorCode: category.colorCode,
      ),
    );

    if (budget == null) {
      return ListTile(
        leading: leading,
        title: Text(category.name),
        subtitle: Text(context.l10n.noLimitSet),
        trailing: const Icon(Icons.add),
        onTap: () => _editBudget(context, category, null),
      );
    }

    final limit = budget.limit;
    final ratio = limit <= 0 ? 0.0 : spent / limit;
    final over = spent > limit;
    final Color barColor;
    if (over) {
      barColor = cls.error;
    } else if (ratio >= 0.8) {
      barColor = Colors.orange;
    } else {
      barColor = cls.primary;
    }

    final remainingLabel = over
        ? context.l10n.budgetOverAmount(formatAmount(spent - limit, symbol))
        : context.l10n
            .budgetRemainingAmount(formatAmount(limit - spent, symbol));

    return ListTile(
      leading: leading,
      title: Row(
        children: [
          Expanded(child: Text(category.name)),
          Text(
            '${(ratio * 100).round()}%',
            style: TextStyle(
              color: over ? cls.error : cls.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: cls.surfaceContainerHighest,
              color: barColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.budgetSpentOfLimit(
              formatAmount(spent, symbol),
              formatAmount(limit, symbol),
            ),
            softWrap: true,
          ),
          Text(
            remainingLabel,
            softWrap: true,
            style: TextStyle(color: over ? cls.error : null),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: () => _editBudget(context, category, budget),
    );
  }

  Future<void> _editBudget(
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
  static String _trimZeros(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toString();
  }
}
