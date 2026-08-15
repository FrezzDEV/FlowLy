import 'package:sentry_flutter/sentry_flutter.dart';

class CrashReportingService {
  CrashReportingService._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');
  static const String _environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'production',
  );

  static Future<void> run(Future<void> Function() appRunner) async {
    if (_dsn.trim().isEmpty) {
      await appRunner();
      return;
    }

    await SentryFlutter.init(
      (options) {
        options.dsn = _dsn;
        options.environment = _environment;
        options.sendDefaultPii = false;
        options.attachScreenshot = false;
        options.tracesSampleRate = 0.0;
        options.profilesSampleRate = 0.0;
      },
      appRunner: appRunner,
    );
  }

  static Future<void> captureException(
    Object exception,
    StackTrace stackTrace, {
    String? operation,
  }) async {
    if (_dsn.trim().isEmpty) return;
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (operation != null && operation.isNotEmpty) {
          scope.setTag('operation', operation);
        }
      },
    );
  }
}
