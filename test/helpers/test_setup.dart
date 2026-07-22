import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/counter/counter.dart';

/// Initializes [SingletonSharedPreference] with an in-memory
/// [SharedPreferences] instance.
///
/// Many cubits, blocs and pages (e.g. `LocalizationCubit`, `CounterBloc`,
/// `CounterRepository`) read from `SingletonSharedPreference.instance` at
/// construction time. Without this call they throw a
/// `LateInitializationError`, so this must run before pumping any widget or
/// building any of those blocs in a test.
///
/// Pass [values] to seed the preferences with initial data.
Future<void> initTestPreferences([
  Map<String, Object> values = const <String, Object>{},
]) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(values);
  // getInstance() caches the instance it built the first time, along with its
  // in-memory copy of the store. Without this, a second call in the same
  // isolate hands back the previous test's data and setMockInitialValues above
  // is silently ignored.
  SharedPreferences.resetStatic();
  final pref = await SharedPreferences.getInstance();
  SingletonSharedPreference.init(pref);
}

/// Resets preferences *and* resyncs the singleton [CounterBloc] to them.
///
/// Prefer this over [initTestPreferences] in any test that pumps a widget or
/// touches [CounterBloc].
///
/// CI runs `very_good test --optimization`, which merges every test file into
/// one isolate, so [CounterBloc] is shared process-wide and keeps whatever an
/// earlier test left in it — while [initTestPreferences] wipes the store
/// underneath. The two then disagree, and `CounterDataView` calls
/// `CounterCubit.calculate()` because `state.data` is non-empty, which reduces
/// an empty repository list and throws `Bad state: No element`. Re-running
/// [InitEvent] re-reads the fresh preferences so the two agree again.
///
/// Ordering is also randomized, so this must run per-test (`setUp`), not once
/// per file (`setUpAll`) — tests from other files interleave.
Future<void> resetAppState([
  Map<String, Object> values = const <String, Object>{},
]) async {
  await initTestPreferences(values);
  // InitEvent does `data.addAll(...)`, appending rather than replacing, so it
  // cannot clear entries on its own — the list has to be emptied first or the
  // previous test's rows survive the re-init.
  CounterBloc()
    ..data.clear()
    ..add(InitEvent());
  // Let the event be processed so state.data reflects the store again.
  await Future<void>.delayed(const Duration(milliseconds: 50));
}
