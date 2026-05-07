/// Calculs purs pour l’écran radar des pourcentages de plan (onboarding 32).
Map<String, double> proportionalPercentagesFromAxisValues(
  Map<String, double> axisValues,
  List<String> keysInOrder,
) {
  var total = 0.0;
  for (final k in keysInOrder) {
    total += axisValues[k] ?? 0.0;
  }
  if (total == 0) {
    final out = <String, double>{};
    final even = keysInOrder.isEmpty ? 0.0 : 100.0 / keysInOrder.length;
    for (final k in keysInOrder) {
      out[k] = even;
    }
    return out;
  }
  final out = <String, double>{};
  for (final k in keysInOrder) {
    final axisValue = axisValues[k] ?? 0.0;
    out[k] = (axisValue / total) * 100.0;
  }
  return out;
}
