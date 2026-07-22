import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/date_filter.dart';

import '../../helpers/helpers.dart';

void main() {
  // CounterBloc is a singleton that reads from SingletonSharedPreference when
  // its InitEvent is processed. resetAppState clears the store and re-runs
  // InitEvent, which must happen per-test: CI merges every file into one
  // isolate and randomizes ordering, so sibling and cross-file tests would
  // otherwise leave their entries in the shared instance.
  setUp(resetAppState);

  group('CounterBloc', () {
    test('settles into a non-loading state over an empty store', () async {
      final bloc = CounterBloc();

      // The initial `loading: true` state is deliberately not asserted here.
      // It exists only between the constructor adding InitEvent and that event
      // being processed, and a singleton is constructed once per process — so
      // after any other test has touched it, that window is unobservable.
      expect(bloc.state.loading, isFalse);
      expect(bloc.state.data, isEmpty);
      expect(bloc.state.dateFilter, equals(DateFilter.all));
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
