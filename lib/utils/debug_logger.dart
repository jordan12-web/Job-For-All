import 'package:flutter/foundation.dart';

/// Simple debug logger that only outputs in debug mode.
/// 
/// In production (kReleaseMode), all logs are silent.
/// In development (kDebugMode), logs appear in console with emojis.
abstract final class DebugLogger {
  /// Log a debug message (shown in debug builds)
  static void log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    }
  }

  /// Log an error message with optional stack trace
  static void error(String message, [StackTrace? stackTrace]) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('❌ ERROR: $message');
      if (stackTrace != null) {
        // ignore: avoid_print
        print('📋 Stack: $stackTrace');
      }
    }
  }

  /// Log a success message
  static void success(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('✅ $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('⚠️ $message');
    }
  }

  /// Log an info message with emoji prefix
  static void info(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('ℹ️ $message');
    }
  }

  /// Log a step in a process
  static void step(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('📍 $message');
    }
  }

  /// Log app lifecycle events
  static void lifecycle(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('📱 $message');
    }
  }

  /// Log routing events
  static void routing(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🛤️ $message');
    }
  }

  /// Log UI building events
  static void ui(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🎨 $message');
    }
  }

  /// Log navigation targets
  static void target(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🎯 $message');
    }
  }

  /// Log page building
  static void page(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('📄 $message');
    }
  }

  /// Log session/auth changes
  static void session(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🔄 $message');
    }
  }
}
