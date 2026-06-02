import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/core/shared_preference.dart';

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
  final pref = await SharedPreferences.getInstance();
  SingletonSharedPreference.init(pref);
}
