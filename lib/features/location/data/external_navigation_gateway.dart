import '../domain/geo_point.dart';

/// Port for opening an external maps / navigation app.
abstract interface class ExternalNavigationGateway {
  Future<bool> canLaunch();

  /// Opens turn-by-turn (or pin) navigation toward [destination].
  Future<bool> openNavigation({required GeoPoint destination, String? label});
}
