import 'package:wallet/app/app.dart';
import 'package:wallet/bootstrap.dart';

/// Default entrypoint used when no flavored target is specified — e.g. a plain
/// `flutter run`, `flutter build web` (web has no flavors), or tools that
/// default to `lib/main.dart`. The flavor-specific entrypoints
/// (`main_development`/`main_staging`/`main_production`) are identical; the
/// flavor is selected by the `--flavor` build argument, not by Dart code.
void main() {
  bootstrap(() => const App());
}
