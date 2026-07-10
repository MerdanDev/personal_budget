import 'package:wallet/app/app.dart';
import 'package:wallet/bootstrap.dart';
import 'package:wallet/core/dev_seed.dart';

void main() {
  // Dev flavor only: prime the store with demo data for screenshots.
  bootstrap(() => const App(), onPrefsReady: DevSeed.seed);
}
