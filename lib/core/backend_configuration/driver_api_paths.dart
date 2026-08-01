/// Driver API path constants from contracts-v0.2.0.
///
/// GENERATED — DO NOT EDIT
/// Source: contracts-v0.2.0
/// Source SHA: 50ca40deb27aa09876b73f474ad7c317253f46ae
abstract final class DriverApiPaths {
  static const otpRequest = '/v1/auth/otp/request';
  static const otpVerify = '/v1/auth/otp/verify';
  static const tokenRefresh = '/v1/auth/token/refresh';
  static const logout = '/v1/auth/logout';

  static const driverMe = '/v1/drivers/me';
  static const driverCompliance = '/v1/drivers/me/compliance';
  static const driverAvailability = '/v1/drivers/me/availability';

  static const offers = '/v1/offers';
  static String offerById(String offerId) => '/v1/offers/$offerId';
  static String offerAccept(String offerId) => '/v1/offers/$offerId/accept';
  static String offerReject(String offerId) => '/v1/offers/$offerId/reject';

  static const deliveriesActive = '/v1/deliveries/active';
  static String deliveryById(String deliveryId) => '/v1/deliveries/$deliveryId';
  static String deliveryPickupConfirmation(String deliveryId) =>
      '/v1/deliveries/$deliveryId/pickup-confirmation';
  static String deliveryArrival(String deliveryId) =>
      '/v1/deliveries/$deliveryId/arrival';
  static String deliveryConfirmation(String deliveryId) =>
      '/v1/deliveries/$deliveryId/delivery-confirmation';
  static String deliveryCancel(String deliveryId) =>
      '/v1/deliveries/$deliveryId/cancel';
  static String deliveryIssues(String deliveryId) =>
      '/v1/deliveries/$deliveryId/issues';
  static String deliveryCustomerContact(String deliveryId) =>
      '/v1/deliveries/$deliveryId/customer-contact';

  static const batchesActive = '/v1/batches/active';
  static String batchById(String batchId) => '/v1/batches/$batchId';

  /// Realtime event channel (contracts-v0.2.0 / STEP 6-A) — additive.
  static const events = '/v1/events';
  static const eventsStream = '/v1/events/stream';
}
