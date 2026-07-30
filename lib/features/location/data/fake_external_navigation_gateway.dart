import '../domain/geo_point.dart';
import 'external_navigation_gateway.dart';

/// Fake external navigation — records calls; never opens a real app.
class FakeExternalNavigationGateway implements ExternalNavigationGateway {
  FakeExternalNavigationGateway({this.available = true});

  bool available;
  int launchCount = 0;
  GeoPoint? lastDestination;
  String? lastLabel;

  @override
  Future<bool> canLaunch() async => available;

  @override
  Future<bool> openNavigation({
    required GeoPoint destination,
    String? label,
  }) async {
    if (!available) return false;
    launchCount++;
    lastDestination = destination;
    lastLabel = label;
    return true;
  }
}
