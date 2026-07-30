import 'package:url_launcher/url_launcher.dart';

import '../domain/geo_point.dart';
import 'external_navigation_gateway.dart';

/// Opens the platform maps app via `url_launcher` (no Map SDK / API keys).
class UrlLauncherExternalNavigationGateway
    implements ExternalNavigationGateway {
  @override
  Future<bool> canLaunch() async {
    final geoUri = Uri(scheme: 'geo', host: '0,0');
    final httpsUri = Uri.https('www.google.com', '/maps');
    return await canLaunchUrl(geoUri) || await canLaunchUrl(httpsUri);
  }

  @override
  Future<bool> openNavigation({
    required GeoPoint destination,
    String? label,
  }) async {
    if (!destination.isValid) return false;
    final lat = destination.latitude;
    final lon = destination.longitude;
    final encodedLabel = Uri.encodeComponent(
      label?.trim().isNotEmpty == true ? label!.trim() : 'Destination',
    );

    // Prefer geo: (Android) then Google Maps HTTPS (cross-platform fallback).
    final candidates = <Uri>[
      Uri.parse('geo:$lat,$lon?q=$lat,$lon($encodedLabel)'),
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$lat,$lon'
        '&travelmode=driving',
      ),
      Uri.parse('https://maps.apple.com/?daddr=$lat,$lon&dirflg=d'),
    ];

    for (final uri in candidates) {
      if (await canLaunchUrl(uri)) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok) return true;
      }
    }
    return false;
  }
}
