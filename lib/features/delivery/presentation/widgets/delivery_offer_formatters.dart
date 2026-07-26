import '../../../../core/localization/app_localizations.dart';
import '../../domain/entities/delivery_order.dart';

/// Presentation-only formatters for delivery offer display fields.
class DeliveryOfferFormatters {
  const DeliveryOfferFormatters._();

  /// Store / merchant label with a safe localized fallback.
  static String storeName(DeliveryOrder order, AppLocalizations l10n) {
    final name = order.merchantDisplayName?.trim();
    if (name == null || name.isEmpty) {
      return l10n.deliveryOfferUnknownStore;
    }
    return name;
  }

  /// Human-readable distance from meters, or unavailable.
  static String distance(DeliveryOrder order, AppLocalizations l10n) {
    final meters = order.distanceMeters;
    if (meters == null) return l10n.deliveryOfferDistanceUnavailable;
    if (meters >= 1000) {
      final km = (meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1);
      return l10n.deliveryOfferDistanceKilometers(km);
    }
    return l10n.deliveryOfferDistanceMeters(meters.round());
  }

  /// Earnings are not yet on the domain order payload — show unavailable.
  static String earnings(AppLocalizations l10n) =>
      l10n.deliveryOfferEarningsUnavailable;
}
