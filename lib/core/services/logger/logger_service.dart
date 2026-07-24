/// Log levels for the application.
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  fatal(4);

  const LogLevel(this.priority);
  final int priority;
}

/// Structured log entry.
final class LogEntry {
  const LogEntry({
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
    this.data,
    required this.timestamp,
  });

  final LogLevel level;
  final String message;
  final String? tag;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'level': level.name,
    'message': message,
    if (tag != null) 'tag': tag,
    if (error != null) 'error': error.toString(),
    if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    if (data != null) 'data': data,
  };
}

/// Abstract logger service interface.
abstract class LoggerService {
  /// Log a debug message (verbose, development only).
  void debug(String message, {String? tag, Map<String, dynamic>? data});

  /// Log an info message (general flow).
  void info(String message, {String? tag, Map<String, dynamic>? data});

  /// Log a warning message (non-critical issue).
  void warning(String message, {String? tag, Object? error, Map<String, dynamic>? data});

  /// Log an error message (critical issue, may include exception).
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data});

  /// Log a fatal message (app-crashing issue).
  void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data});
}

/// Default implementation of [LoggerService] that writes to the console.
final class ConsoleLoggerService implements LoggerService {
  const ConsoleLoggerService({this.minLevel = LogLevel.debug});

  final LogLevel minLevel;

  @override
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  @override
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  @override
  void warning(String message, {String? tag, Object? error, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, error: error, data: data);
  }

  @override
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }

  @override
  void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace, Map<String, dynamic>? data}) {
    _log(LogLevel.fatal, message, tag: tag, error: error, stackTrace: stackTrace, data: data);
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (level.priority < minLevel.priority) return;

    // In production this would send to a remote logging service.
    // For now, we write to the console with structured formatting.
    // ignore: avoid_print
    print('[${DateTime.now().toIso8601String()}] [${level.name.toUpperCase()}]${tag != null ? ' [$tag]' : ''} $message${error != null ? '\n  └─ Error: $error' : ''}${data != null ? '\n  └─ Data: $data' : ''}');
  }
}