import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/app/app.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/core/key_data.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/home/home.dart';

import '../../helpers/helpers.dart';

void main() {
  setUpAll(() {
    // Must precede setupFirebaseCoreMocks: it installs a mock host API on the
    // test binary messenger, which needs the binding to exist. setUpAll runs
    // before the setUp below that would otherwise initialize it.
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
  });

  setUp(() async {
    // App shows OnboardingScreen until this flag is set, so seed it to reach
    // HomeScreen.
    await resetAppState({KeyData.onboardingCompleted: true});
    // App.build reads AnalyticsService.observer, which resolves
    // FirebaseAnalytics.instance and throws [core/no-app] without this.
    await Firebase.initializeApp();
  });

  group('App', () {
    testWidgets('renders HomeScreen with CounterPage', (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
            // Singletons: `.value` so disposing the tree does not close the
            // process-wide instances.
            BlocProvider<CounterBloc>.value(value: CounterBloc()),
            BlocProvider<CurrencyCubit>.value(value: CurrencyCubit()),
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
