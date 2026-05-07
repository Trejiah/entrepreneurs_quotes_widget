import 'package:flutter_test/flutter_test.dart';

/// Les overrides Riverpod ([sharedPrefsProvider], etc.) sont fournis dans
/// [AppBootstrapper]. Tester la vraie app nécessite un harness dédié.
void main() {
  test('sanité projet', () {
    expect(1 + 1, 2);
  });
}
