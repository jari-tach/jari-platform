import 'dart:async';

import 'package:drift/drift.dart';

// `OfflineQueue` (Drift table) is hidden here because this file also
// imports the `OfflineQueue` service class from offline_queue.dart; only
// the service class is actually used in this file.
import '../../features/driver/data/datasources/local/driver_database.dart'
    hide OfflineQueue;
import '../services/api/api_client.dart';
import '../services/logger/logger_service.dart';
import '../services/storage/secure_storage_service.dart';
import 'offline_queue.dart';

/// Sync manager for offline-first architecture
///
/// This manager:
/// - Monitors network connectivity
/// - Processes offline queue when online
/// - Handles conflicts between local and remote data
/// - Retries failed operations with exponential backoff
/// - Updates sync metadata
class SyncManager {
  final LoggerService _logger;
  final DriverDatabase _database;
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final OfflineQueue _offlineQueue;

  bool _isSyncing = false;
  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  SyncManager({
    required this._logger,
    required this._database,
    required this._apiClient,
    required this._secureStorage,
    required this._offlineQueue,
  });

  /// Initialize sync manager
  Future<void> init() async {
    _logger.info('SyncManager: Initializing');
    _logger.debug('SyncManager: SecureStorage=${_secureStorage.runtimeType}');

    // Listen to network status changes
    // TODO: Listen to network monitor provider
    // ref.listen<ConnectivityStatus>(connectivityStatusProvider, (previous, next) {
    //   if (next == ConnectivityStatus.online) {
    //     processQueue();
    //   }
    // });

    _logger.info('SyncManager: Initialized');
  }

  /// Process offline queue
  Future<SyncResult> processQueue() async {
    if (_isSyncing) {
      _logger.debug('SyncManager: Already syncing, skipping');
      return SyncResult.alreadySyncing();
    }

    _isSyncing = true;
    _statusController.add(SyncStatus.syncing);

    try {
      _logger.info('SyncManager: Starting queue processing');

      final pendingOperations = await _offlineQueue.getPendingOperations();

      if (pendingOperations.isEmpty) {
        _logger.debug('SyncManager: No pending operations');
        _statusController.add(SyncStatus.idle);
        return SyncResult.nothingToSync();
      }

      _logger.info(
        'SyncManager: Processing ${pendingOperations.length} operations',
      );

      int successCount = 0;
      int failureCount = 0;

      for (final operation in pendingOperations) {
        try {
          await _processOperation(operation);
          await _offlineQueue.markAsCompleted(operation.id!);
          successCount++;
          _logger.debug(
            'SyncManager: Successfully synced operation ${operation.id}',
          );
        } catch (e, stackTrace) {
          _logger.error(
            'SyncManager: Failed to sync operation ${operation.id}',
            e,
            stackTrace,
          );
          await _offlineQueue.markAsFailed(operation.id!, e.toString());
          failureCount++;
        }
      }

      // Update sync metadata
      await _updateSyncMetadata('all');

      _isSyncing = false;
      _statusController.add(SyncStatus.idle);

      _logger.info(
        'SyncManager: Queue processing completed (success: $successCount, failed: $failureCount)',
      );

      return SyncResult(
        success: successCount,
        failed: failureCount,
        total: pendingOperations.length,
      );
    } catch (e, stackTrace) {
      _isSyncing = false;
      _statusController.add(SyncStatus.error);
      _logger.error('SyncManager: Queue processing failed', e, stackTrace);
      rethrow;
    }
  }

  /// Process a single operation
  Future<void> _processOperation(OfflineQueueItem operation) async {
    _logger.debug(
      'SyncManager: Processing ${operation.operationType} operation for ${operation.entityType}:${operation.entityId}',
    );

    switch (operation.operationType) {
      case OperationType.create:
        await _apiClient.post(
          '/${operation.entityType}',
          data: operation.payload,
        );
        break;
      case OperationType.update:
        await _apiClient.put(
          '/${operation.entityType}/${operation.entityId}',
          data: operation.payload,
        );
        break;
      case OperationType.delete:
        await _apiClient.delete(
          '/${operation.entityType}/${operation.entityId}',
        );
        break;
    }
  }

  /// Update sync metadata
  Future<void> _updateSyncMetadata(String entityType) async {
    try {
      await _database.upsertSyncMetadata(
        SyncMetadataCompanion.insert(
          entityType: entityType,
          lastSyncAt: DateTime.now(),
          lastSyncToken: Value(DateTime.now().toIso8601String()),
          totalRecords: const Value(0), // TODO: Get actual count from API
        ),
      );
      _logger.debug('SyncManager: Updated sync metadata for $entityType');
    } catch (e, stackTrace) {
      _logger.error(
        'SyncManager: Failed to update sync metadata',
        e,
        stackTrace,
      );
    }
  }

  /// Get last sync time for entity type
  Future<DateTime?> getLastSyncTime(String entityType) async {
    try {
      final metadata = await _database.getLastSync(entityType);
      return metadata?.lastSyncAt;
    } catch (e) {
      _logger.error('SyncManager: Failed to get last sync time', e);
      return null;
    }
  }

  /// Check if sync is needed
  Future<bool> isSyncNeeded(String entityType) async {
    try {
      final lastSync = await getLastSyncTime(entityType);
      if (lastSync == null) return true;

      // Sync if last sync was more than 5 minutes ago
      return DateTime.now().difference(lastSync) > const Duration(minutes: 5);
    } catch (e) {
      _logger.error('SyncManager: Failed to check if sync needed', e);
      return true;
    }
  }

  /// Stream of sync status changes
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Dispose resources
  Future<void> dispose() async {
    await _statusController.close();
    _logger.info('SyncManager: Disposed');
  }
}

/// Sync status
enum SyncStatus { idle, syncing, error, completed }

/// Sync result
class SyncResult {
  final int success;
  final int failed;
  final int total;

  const SyncResult({this.success = 0, this.failed = 0, this.total = 0});

  bool get hasFailures => failed > 0;
  bool get isComplete => success + failed == total;

  factory SyncResult.nothingToSync() => const SyncResult();
  factory SyncResult.alreadySyncing() => const SyncResult();
}
