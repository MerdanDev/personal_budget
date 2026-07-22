import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:wallet/counter/counter.dart';

import '../../helpers/helpers.dart';

class MockCounterCubit extends MockCubit<double> implements CounterCubit {}

void main() {
  setUp(resetAppState);

  group('CounterPage', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpApp(const CounterPage(), withAppBlocs: true);
      await tester.pump();
      expect(find.byType(CounterPage), findsOneWidget);
    });
  });

  group('CounterText', () {
    late CounterCubit counterCubit;

    setUp(() {
      counterCubit = MockCounterCubit();
    });

    testWidgets('renders the formatted current count', (tester) async {
      when(() => counterCubit.state).thenReturn(42);
      await tester.pumpApp(
        BlocProvider<CounterCubit>.value(
          value: counterCubit,
          child: const CounterText(),
        ),
      );
      expect(find.text('42.00 TMT'), findsOneWidget);
    });
  });
}
