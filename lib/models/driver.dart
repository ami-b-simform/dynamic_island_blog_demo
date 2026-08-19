/// A ride offered on the home screen.
///
/// Replaces the stringly-typed maps this demo started with, so a typo like
/// `driver['nmae']` becomes a compile error instead of a runtime null.
class Driver {
  const Driver({
    required this.name,
    required this.car,
    required this.plate,
    required this.distanceKm,
    required this.etaMinutes,
    required this.assetPath,
  });

  final String name;
  final String car;
  final String plate;
  final double distanceKm;
  final int etaMinutes;

  /// Flutter asset path, e.g. `assets/images/driver1.jpeg`.
  final String assetPath;

  /// File name used inside the App Group container, derived from [assetPath]
  /// so the two can never drift apart.
  String get fileName => assetPath.split('/').last;
}
