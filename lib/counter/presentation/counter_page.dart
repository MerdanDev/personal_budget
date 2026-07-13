import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/presentation/widgets/add_income_expense_dialog.dart';
import 'package:wallet/counter/presentation/widgets/income_expense_summary.dart';
import 'package:wallet/counter/presentation/widgets/income_expense_widget.dart';
import 'package:wallet/home/presentation/notification_screen.dart';
import 'package:wallet/l10n/l10n.dart';

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  bool _searchVisible = false;

  void _toggleSearch() {
    setState(() => _searchVisible = !_searchVisible);
    // Reset the query when the field is dismissed so the hidden search does not
    // keep filtering the list.
    if (!_searchVisible) {
      context.read<CounterBloc>().add(ChangeSearchQuery(''));
    }
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: IconButton(
              tooltip: context.l10n.search,
              onPressed: _toggleSearch,
              icon: Icon(_searchVisible ? Icons.close : Icons.search),
            ),
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
              preferredSize: Size.fromHeight(_searchVisible ? 200 : 140),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const IncomeExpenseSummary(),
                    const SizedBox(height: 12),
                    if (_searchVisible) ...[
                      const TransactionSearchField(autofocus: true),
                      const SizedBox(height: 12),
                    ],
                    BlocBuilder<CounterBloc, CounterState>(
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
                  ],
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
    final symbol = context.watch<CurrencyCubit>().state;
    return FittedBox(
      child: Text(
        formatAmount(count, symbol),
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
          if (state.data.isEmpty && state.searchQuery.trim().isNotEmpty) {
            return SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noSearchResults,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
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

/// Search box on the transaction list. Owns its own [TextEditingController]
/// and pushes every change to [CounterBloc] as a [ChangeSearchQuery]; the bloc
/// filters by description, category name, amount and date. Shows a clear
/// button while there is text.
class TransactionSearchField extends StatefulWidget {
  const TransactionSearchField({this.autofocus = false, super.key});

  final bool autofocus;

  @override
  State<TransactionSearchField> createState() => _TransactionSearchFieldState();
}

class _TransactionSearchFieldState extends State<TransactionSearchField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    context.read<CounterBloc>().add(ChangeSearchQuery(value));
    // Rebuild so the clear button appears/disappears with the text.
    setState(() {});
  }

  void _clear() {
    _controller.clear();
    _onChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      onChanged: _onChanged,
      decoration: InputDecoration(
        isDense: true,
        hintText: context.l10n.search,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clear,
              )
            : null,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
