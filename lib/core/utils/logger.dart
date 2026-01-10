/// Core Logger - SAF DART (Flutter bağımsız)
/// Domain katmanında güvenle kullanılabilir
library;

import 'dart:developer' as developer;

/// Log seviyeleri
enum LogLevel { debug, info, warning, error }

/// Minimal, saf Dart logger
/// Flutter'a bağımlı değildir, her katmanda kullanılabilir
class Logger {
  final String tag;
  final bool enabled;

  const Logger({this.tag = 'APP', this.enabled = true});

  void debug(String message) {
    _log(LogLevel.debug, message);
  }

  void info(String message) {
    _log(LogLevel.info, message);
  }

  void warning(String message) {
    _log(LogLevel.warning, message);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!enabled) return;

    final emoji = switch (level) {
      LogLevel.debug => '🔍',
      LogLevel.info => 'ℹ️',
      LogLevel.warning => '⚠️',
      LogLevel.error => '❌',
    };

    final formattedMessage = '$emoji [$tag] $message';

    developer.log(
      formattedMessage,
      name: tag,
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _levelToInt(LogLevel level) {
    return switch (level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
    };
  }
}

/// Global default logger instance
const logger = Logger();
