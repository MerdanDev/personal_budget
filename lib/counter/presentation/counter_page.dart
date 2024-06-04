import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/presentation/widgets/add_income_expense_dialog.dart';
import 'package:wallet/counter/presentation/widgets/income_expense_widget.dart';
import 'package:wallet/home/presentation/notification_screen.dart';
import 'package:wallet/l10n/l10n.dart';

class CounterPage extends StatelessWidget {
  const CounterPage({super.key});

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const CounterText(),
            actions: [
              IconButton(
                onPressed: () {
                  // NotificationService().showNotification(
                  //   body: 'Test notification',
                  //   title: 'Test',
                  // );
                  // NotificationService().getPendingList();
                  Navigator.push(
                    context,
                    MaterialPageRoute<NotificationScreen>(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: BlocBuilder<CounterBloc, CounterState>(
                  builder: (context, state) {
                    return SegmentedButton<DateFilter>(
                      segments: DateFilter.values
                          .map(
                            (e) => ButtonSegment<DateFilter>(
                              value: e,
                              icon: Icon(e.iconData),
                              // label: Text(e.name),
                            ),
                          )
                          .toList(),
                      selected: {state.dateFilter},
                      onSelectionChanged: (value) {
                        context.read<CounterBloc>().add(
                              ChangeDateFilter(value.first),
                            );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const CounterDataView(),
          const SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'income',
            onPressed: () {
              // context.read<CounterCubit>().increment();
              showDialog<void>(
                context: context,
                builder: (context) {
                  return const IncomeExpenseDialog(
                    isMinus: false,
                  );
                },
              );
            },
            icon: const Icon(Icons.add),
            label: Text(context.l10n.income),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.large(
            heroTag: 'expense',
            onPressed: () {
              // context.read<CounterCubit>().decrement();
              showDialog<void>(
                context: context,
                builder: (context) {
                  return const IncomeExpenseDialog(
                    isMinus: true,
                  );
                },
              );
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}

class CounterText extends StatelessWidget {
  const CounterText({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = context.select((CounterCubit cubit) => cubit.state);
    return FittedBox(
      child: Text(
        '${count.toStringAsFixed(2)} TMT',
        style: theme.textTheme.displayLarge,
      ),
    );
  }
}

class CounterDataView extends StatefulWidget {
  const CounterDataView({super.key});

  @override
  State<CounterDataView> createState() => _CounterDataViewState();
}

class _CounterDataViewState extends State<CounterDataView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CounterBloc, CounterState>(
      buildWhen: (previous, current) {
        return true;
      },
      builder: (context, state) {
        if (state.loading) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          if (state.data.isNotEmpty) {
            context.read<CounterCubit>().calculate();
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final element = state.data[index];
                return IncomeExpenseWidget(element: element);
              },
              childCount: state.data.length,
            ),
          );
        }
      },
    );
  }
}

class DeleteDialog extends StatelessWidget {
  const DeleteDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      icon: const Icon(Icons.info_outline),
      title: Text(context.l10n.deleteTitle),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: Text(context.l10n.yes),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: Text(context.l10n.no),
        ),
      ],
    );
  }
}
