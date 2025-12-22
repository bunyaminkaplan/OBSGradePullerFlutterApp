import 'dart:developer' as developer;

class LoggerService {
  void debug(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'DEBUG', error: error, stackTrace: stackTrace);
  }

  void info(String message) {
    developer.log(message, name: 'INFO');
  }

  void warning(String message, {Object? error}) {
    developer.log(message, name: 'WARNING', error: error);
  }

  void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, name: 'ERROR', error: error, stackTrace: stackTrace);
  }
}
