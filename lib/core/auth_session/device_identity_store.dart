import '../network/uuid_v4.dart';
import '../services/storage/secure_storage_service.dart';

/// Provides the stable per-install device identifier sent as
/// `device.deviceId` during OTP verification (the backend requires a UUID).
///
/// Contract:
/// - A valid UUID v4 is generated at most once per install.
/// - The value is persisted and reused across app restarts and logins.
/// - The value is never derived from Android ID / IMEI / other hardware
///   identifiers requiring sensitive permissions, and is never a constant
///   shared between devices.
abstract interface class DeviceIdentityStore {
  Future<String> obtainDeviceId();
}

/// [DeviceIdentityStore] backed by [SecureStorageService].
///
/// The storage key is intentionally outside the auth-session keys so the
/// device identity survives logout and session clears.
final class SecureDeviceIdentityStore implements DeviceIdentityStore {
  SecureDeviceIdentityStore({required this._storage, UuidV4? uuid})
    : _uuid = uuid ?? UuidV4();

  static const storageKey = 'saeq_device_id_v1';

  static final RegExp _uuidV4Pattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  final SecureStorageService _storage;
  final UuidV4 _uuid;

  String? _cached;
  Future<String>? _inFlight;

  @override
  Future<String> obtainDeviceId() {
    final cached = _cached;
    if (cached != null) return Future.value(cached);
    // Single-flight so concurrent callers never generate two UUIDs.
    return _inFlight ??= _readOrCreate().whenComplete(() => _inFlight = null);
  }

  Future<String> _readOrCreate() async {
    final stored = await _storage.read(storageKey);
    if (stored != null && _uuidV4Pattern.hasMatch(stored)) {
      return _cached = stored;
    }
    final generated = _uuid.next();
    await _storage.write(storageKey, generated);
    return _cached = generated;
  }
}

/// In-memory [DeviceIdentityStore] for unit tests: stable for the lifetime
/// of the instance, regenerated per instance.
final class InMemoryDeviceIdentityStore implements DeviceIdentityStore {
  InMemoryDeviceIdentityStore({UuidV4? uuid}) : _uuid = uuid ?? UuidV4();

  final UuidV4 _uuid;
  String? _id;

  @override
  Future<String> obtainDeviceId() async => _id ??= _uuid.next();
}
