import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/date_filter.dart';

import '../../helpers/helpers.dart';

void main() {
  // CounterBloc is a singleton that reads from SingletonSharedPreference when
  // its InitEvent is processed, so preferences must be initialized before the
  // instance is ever created.
  setUpAll(initTestPreferences);

  group('CounterBloc', () {
    test('starts loading and settles into a non-loading state', () async {
      final bloc = CounterBloc();

      // The constructor adds InitEvent; before it is processed the bloc is in
      // its initial loading state.
      expect(
        bloc.state,
        equals(
          const CounterState(
            data: [],
            dateFilter: DateFilter.all,
            loading: true,
          ),
        ),
      );

      // Once InitEvent is handled, loading completes.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.loading, isFalse);
    });

    test('adding an IncomeExpenseEvent stores the entry', () async {
      final bloc = CounterBloc();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final countBefore = bloc.data.length;
      bloc.add(IncomeExpenseEvent(amount: 0.1));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.data.length, equals(countBefore + 1));
      expect(bloc.data.last.amount, equals(0.1));
      expect(bloc.state.loading, isFalse);
    });

    test('changing the date filter is reflected in the state', () async {
      final bloc = CounterBloc()..add(ChangeDateFilter(DateFilter.month));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.dateFilter, equals(DateFilter.month));
    });
  });
}
