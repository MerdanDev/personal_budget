import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/domain/income_expense.dart';

void main() {
  group('CounterCubit', () {
    test('initial state is Empty', () {
      expect(
        CounterBloc().state,
        equals(
          const CounterState(
            data: [],
            dateFilter: DateFilter.all,
            loading: true,
          ),
        ),
      );
    });

    late final List<IncomeExpense> data;
    late final CounterState first;
    final bloc = CounterBloc();

    test('After adding one', () async {
      bloc.add(
        IncomeExpenseEvent(amount: 0.1),
      );
      await Future.delayed(const Duration(milliseconds: 50), () {
        data = [...bloc.data];
        first = CounterState(
          data: data,
          dateFilter: DateFilter.all,
          loading: false,
        );
      });
      expect(bloc.state, equals(first));
    });

    test('After adding one more', () async {
      bloc.add(
        IncomeExpenseEvent(amount: 1),
      );
      await Future.delayed(const Duration(milliseconds: 50), () {});
      expect(bloc.state, isNot(equals(first)));
    });

    test('Checking data', () => expect(bloc.state.data, isNot(data)));
  });
}
