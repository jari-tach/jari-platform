import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../services/logger/logger_service.dart';

/// Network connectivity status
enum ConnectivityStatus { online, offline, unknown }

/// Network monitor service for offline-first architecture
///
/// Monitors network connectivity and provides:
/// - Real-time connectivity status
/// - Connection type detection (wifi, mobile, ethernet, none)
/// - Connectivity change stream
/// - Network quality assessment
class NetworkMonitor {
  final LoggerService _logger;
  final Connectivity _connectivity;

  ConnectivityStatus _status = ConnectivityStatus.unknown;
  List<ConnectivityResult> _connectionType = const [ConnectivityResult.none];
  final StreamController<ConnectivityStatus> _statusController =
      StreamController<ConnectivityStatus>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkMonitor({required this._logger, required this._connectivity});

  /// Initialize network monitoring
  Future<void> init() async {
    _logger.info('NetworkMonitor: Initializing');

    // Check initial connectivity
    await checkConnectivity();

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (result) => _handleConnectivityChange(result),
      onError: (error) => _logger.error(
        'NetworkMonitor: Stream error',
        error,
        StackTrace.current,
      ),
    );

    _logger.info('NetworkMonitor: Initialized');
  }

  /// Check current connectivity status
  Future<ConnectivityStatus> checkConnectivity() async {
    try {
      _connectionType = await _connectivity.checkConnectivity();
      _status = _hasConnection(_connectionType)
          ? ConnectivityStatus.online
          : ConnectivityStatus.offline;

      _logger.debug('NetworkMonitor: Status=$_status, Type=$_connectionType');
      return _status;
    } catch (e, stackTrace) {
      _logger.error(
        'NetworkMonitor: Failed to check connectivity',
        e,
        stackTrace,
      );
      _status = ConnectivityStatus.unknown;
      return _status;
    }
  }

  /// Handle connectivity change
  void _handleConnectivityChange(List<ConnectivityResult> result) {
    _connectionType = result;
    final previousStatus = _status;
    _status = _hasConnection(result)
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;

    _logger.info(
      'NetworkMonitor: Connectivity changed: $previousStatus -> $_status',
    );
    _statusController.add(_status);
  }

  /// True if at least one reported connection type is not [ConnectivityResult.none].
  /// This reflects OS-level connectivity only, not actual internet reachability.
  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  /// Get current connectivity status
  ConnectivityStatus get status => _status;

  /// Get current connection type(s)
  List<ConnectivityResult> get connectionType => _connectionType;

  /// Check if device is online
  bool get isOnline => _status == ConnectivityStatus.online;

  /// Check if device is offline
  bool get isOffline => _status == ConnectivityStatus.offline;

  /// Stream of connectivity status changes
  Stream<ConnectivityStatus> get statusStream => _statusController.stream;

  /// Dispose resources
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _statusController.close();
    _logger.info('NetworkMonitor: Disposed');
  }
}
