import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Log level for filtering messages
enum LogLevel { debug, info, warning, error, fatal }

/// Structured log entry
class LogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    'error': error?.toString(),
    'stackTrace': stackTrace?.toString(),
    'metadata': metadata,
  };

  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('[${timestamp.toIso8601String()}] ');
    buffer.write('[${level.name.toUpperCase()}] ');
    buffer.write(message);

    if (error != null) {
      buffer.write('\n  Error: $error');
    }

    if (stackTrace != null) {
      buffer.write('\n  StackTrace: $stackTrace');
    }

    if (metadata != null && metadata!.isNotEmpty) {
      buffer.write('\n  Metadata: ${jsonEncode(metadata)}');
    }

    return buffer.toString();
  }
}

/// Logger service interface
///
/// Unified contract for all log levels: every method accepts the log
/// [message] followed by optional positional [error], [stackTrace] and
/// [metadata] arguments. Positional (not named) parameters are used because
/// they match the calling convention already used across the codebase.
abstract class LoggerService {
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]);
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]);
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]);
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]);
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]);

  LogLevel get level;
  set level(LogLevel level);
}

/// Console logger implementation with pretty printing for debug
class ConsoleLoggerService implements LoggerService {
  static const _maxMessageLength = 1000;

  LogLevel _level = LogLevel.debug;
  final List<LogEntry> _logs = [];
  final int _maxLogs = 1000;

  @override
  LogLevel get level => _level;

  @override
  set level(LogLevel level) => _level = level;

  @override
  void debug(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    if (_shouldLog(LogLevel.debug)) {
      _log(
        LogLevel.debug,
        message,
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );
    }
  }

  @override
  void info(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    if (_shouldLog(LogLevel.info)) {
      _log(
        LogLevel.info,
        message,
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );
    }
  }

  @override
  void warning(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    if (_shouldLog(LogLevel.warning)) {
      _log(
        LogLevel.warning,
        message,
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );
    }
  }

  @override
  void error(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    if (_shouldLog(LogLevel.error)) {
      _log(
        LogLevel.error,
        message,
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );
    }
  }

  @override
  void fatal(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  ]) {
    if (_shouldLog(LogLevel.fatal)) {
      _log(
        LogLevel.fatal,
        message,
        error: error,
        stackTrace: stackTrace,
        metadata: metadata,
      );
    }
  }

  bool _shouldLog(LogLevel level) {
    return level.index >= _level.index;
  }

  void _log(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message.length > _maxMessageLength
          ? '${message.substring(0, _maxMessageLength)}...'
          : message,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );

    _logs.add(entry);

    // Keep only last N logs
    if (_logs.length > _maxLogs) {
      _logs.removeRange(0, _logs.length - _maxLogs);
    }

    // Print to console
    _printLog(entry);
  }

  void _printLog(LogEntry entry) {
    if (Platform.isAndroid || Platform.isIOS) {
      // Release mode: JSON format
      developer.log(jsonEncode(entry.toJson()));
    } else {
      // Debug mode: Pretty format
      final color = _getColorForLevel(entry.level);
      developer.log(color(entry.toString()));
    }
  }

  String Function(String) _getColorForLevel(LogLevel level) {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // ANSI colors for desktop
      switch (level) {
        case LogLevel.debug:
          return (s) => '\x1B[37m$s\x1B[0m'; // Gray
        case LogLevel.info:
          return (s) => '\x1B[36m$s\x1B[0m'; // Cyan
        case LogLevel.warning:
          return (s) => '\x1B[33m$s\x1B[0m'; // Yellow
        case LogLevel.error:
          return (s) => '\x1B[31m$s\x1B[0m'; // Red
        case LogLevel.fatal:
          return (s) => '\x1B[35m$s\x1B[0m'; // Magenta
      }
    } else {
      // No colors for mobile/web
      return (s) => s;
    }
  }

  /// Get all logs
  List<LogEntry> get logs => List.unmodifiable(_logs);

  /// Clear all logs
  void clear() {
    _logs.clear();
  }

  /// Export logs as JSON
  String exportLogs() {
    return jsonEncode(_logs.map((e) => e.toJson()).toList());
  }
}

/// Logger provider
final loggerServiceProvider = Provider<LoggerService>((ref) {
  return ConsoleLoggerService();
});
