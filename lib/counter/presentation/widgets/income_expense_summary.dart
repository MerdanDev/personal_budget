import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/l10n/l10n.dart';

/// Shows the income and expense totals for the currently selected
/// date-filter period. Unlike the all-time balance shown above it, these
/// figures are scoped to `state.data`, which the bloc has already filtered by
/// the active period.
class IncomeExpenseSummary extends StatelessWidget {
  const IncomeExpenseSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
      builder: (context, state) {
        var income = 0.0;
        var expense = 0.0;
        for (final e in state.data) {
          if (e.amount > 0) {
            income += e.amount;
          } else {
            expense += e.amount;
          }
        }
        return Row(
          children: [
            Expanded(
              child: _SummaryTile(
                label: context.l10n.income,
                amount: income,
                icon: Icons.arrow_upward_rounded,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryTile(
                label: context.l10n.expense,
                // expense is stored as a negative sum; show its magnitude.
                amount: expense.abs(),
                icon: Icons.arrow_downward_rounded,
                color: Colors.redAccent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatAmount(amount, context.watch<CurrencyCubit>().state),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
