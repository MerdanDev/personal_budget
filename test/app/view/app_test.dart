import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/app/app.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/home/home.dart';

import '../../helpers/helpers.dart';

void main() {
  setUp(initTestPreferences);

  group('App', () {
    testWidgets('renders HomeScreen with CounterPage', (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
            BlocProvider<CounterBloc>(create: (_) => CounterBloc()),
          ],
          child: const App(),
        ),
      );
      // Let the LocalizationOverride and PageView build their first frame.
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(CounterPage), findsOneWidget);
    });
  });
}
