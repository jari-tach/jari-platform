import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/driver/data/datasources/local/driver_database.dart';
import '../services/logger/logger_service.dart';

/// Operation types for offline queue
enum OperationType { create, update, delete }

/// Status of offline queue items
enum QueueItemStatus { pending, syncing, completed, failed }

/// Offline queue item
class OfflineQueueItem {
  final int? id;
  final OperationType operationType;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> payload;
  final QueueItemStatus status;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime? processedAt;

  OfflineQueueItem({
    this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    required this.payload,
    this.status = QueueItemStatus.pending,
    this.retryCount = 0,
    this.errorMessage,
    required this.createdAt,
    this.processedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'operationType': operationType.name,
        'entityType': entityType,
        'entityId': entityId,
        'payload': payload,
        'status': status.name,
        'retryCount': retryCount,
        'errorMessage': errorMessage,
        'createdAt': createdAt.toIso8601String(),
        'processedAt': processedAt?.toIso8601String(),
      };

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) => OfflineQueueItem(
        id: json['id'] as int?,
        operationType: OperationType.values.firstWhere(
          (e) => e.name == json['operationType'],
          orElse: () => OperationType.create,
        ),
        entityType: json['entityType'] as String,
        entityId: json['entityId'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        status: QueueItemStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => QueueItemStatus.pending,
        ),
        retryCount: json['retryCount'] as int? ?? 0,
        errorMessage: json['errorMessage'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        processedAt: json['processedAt'] != null
            ? DateTime.parse(json['processedAt'] as String)
            : null,
      );
}

/// Offline queue service for managing operations when offline
///
/// This service:
/// - Queues operations when offline
/// - Processes queue when back online
/// - Handles retries with exponential backoff
/// - Manages failed operations
class OfflineQueue {
  final LoggerService _logger;
  final DriverDatabase _database;
  final int _maxRetries;
  final Duration _baseRetryDelay;

  OfflineQueue({
    required LoggerService logger,
    required DriverDatabase database,
    int maxRetries = 3,
    Duration baseRetryDelay = const Duration(seconds: 1),
  }) : _logger = logger,
       _database = database,
       _maxRetries = maxRetries,
       _baseRetryDelay = baseRetryDelay;

  /// Enqueue an operation for later processing
  Future<int> enqueue({
    required OperationType operationType,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final item = OfflineQueueItem(
        operationType: operationType,
        entityType: entityType,
        entityId: entityId,
        payload: payload,
        createdAt: DateTime.now(),
      );

      final id = await _database.enqueueOperation(
        OfflineQueueCompanion.insert(
          operationType: operationType.name,
          entityType: entityType,
          entityId: entityId,
          payload: jsonEncode(payload),
          status: Value(QueueItemStatus.pending.name),
          retryCount: const Value(0),
          createdAt: Value(DateTime.now()),
        ),
      );

      _logger.info(
        'OfflineQueue: Enqueued $operationType operation for $entityType:$entityId (id=$id)',
      );

      return id;
    } catch (e, stackTrace) {
      _logger.error('OfflineQueue: Failed to enqueue operation', e, stackTrace);
      rethrow;
    }
  }

  /// Get all pending operations
  Future<List<OfflineQueueItem>> getPendingOperations() async {
    try {
      final items = await _database.getPendingOperations();
      return items
          .map((item) => OfflineQueueItem(
                id: item.id,
                operationType: OperationType.values.firstWhere(
                  (e) => e.name == item.operationType,
                  orElse: () => OperationType.create,
                ),
                entityType: item.entityType,
                entityId: item.entityId,
                payload: jsonDecode(item.payload) as Map<String, dynamic>,
                status: QueueItemStatus.values.firstWhere(
                  (e) => e.name == item.status,
                  orElse: () => QueueItemStatus.pending,
                ),
                retryCount: item.retryCount,
                errorMessage: item.errorMessage,
                createdAt: item.createdAt,
                processedAt: item.processedAt,
              ))
          .toList();
    } catch (e, stackTrace) {
      _logger.error('OfflineQueue: Failed to get pending operations', e, stackTrace);
      return [];
    }
  }

  /// Mark operation as completed
  Future<void> markAsCompleted(int id) async {
    try {
      await _database.deleteOfflineOperation(id);
      _logger.debug('OfflineQueue: Marked operation $id as completed');
    } catch (e, stackTrace) {
      _logger.error('OfflineQueue: Failed to mark operation $id as completed', e, stackTrace);
    }
  }

  /// Mark operation as failed
  Future<void> markAsFailed(int id, String errorMessage) async {
    try {
      final item = await (_database.select(_database.offlineQueue)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      final newRetryCount = item.retryCount + 1;

      if (newRetryCount >= _maxRetries) {
        // Max retries reached, delete the operation
        await _database.deleteOfflineOperation(id);
        _logger.warning(
          'OfflineQueue: Operation $id failed after $_maxRetries retries, removed from queue',
        );
      } else {
        // Update retry count and error message
        await _database.update(_database.offlineQueue).replace(
          OfflineQueueCompanion(
            id: Value(id),
            retryCount: Value(newRetryCount),
            errorMessage: Value(errorMessage),
          ),
        );
        _logger.warning(
          'OfflineQueue: Operation $id failed (retry $newRetryCount/$_maxRetries): $errorMessage',
        );
      }
    } catch (e, stackTrace) {
      _logger.error('OfflineQueue: Failed to mark operation $id as failed', e, stackTrace);
    }
  }

  /// Clear all operations
  Future<void> clear() async {
    try {
      await _database.clearOfflineQueue();
      _logger.info('OfflineQueue: Cleared all operations');
    } catch (e, stackTrace) {
      _logger.error('OfflineQueue: Failed to clear operations', e, stackTrace);
    }
  }

  /// Get retry delay for exponential backoff
  Duration getRetryDelay(int retryCount) {
    return _baseRetryDelay * (1 << retryCount); // Exponential backoff
  }
}