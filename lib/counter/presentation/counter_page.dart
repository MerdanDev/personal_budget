import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/presentation/widgets/add_income_expense_dialog.dart';

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
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
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
            label: const Text('Income'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.large(
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
                    subtitle: element.description != null
                        ? Text(element.description!)
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
                    // trailing: element.category != null
                    //     ? Icon(IconData(element.category!.iconCode!), )
                    //     : null,
                  ),
                );
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
      title: const Text(
        'Do you want to delete',
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, true);
          },
          child: const Text('Yes'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text('No'),
        ),
      ],
    );
  }
}
