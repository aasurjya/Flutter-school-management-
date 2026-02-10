import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application environment types
enum Environment { development, staging, production }

/// Centralized environment configuration
/// Reads from .env file and provides type-safe access to config values
class AppEnvironment {
  AppEnvironment._();

  static bool _initialized = false;

  /// Initialize environment - call before runApp()
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _initialized = true;
    } catch (e) {
      // If .env file doesn't exist, use defaults
      _initialized = true;
    }
  }

  /// Current environment
  static Environment get environment {
    final env = dotenv.env['APP_ENV'] ?? 'production';
    switch (env.toLowerCase()) {
      case 'development':
      case 'dev':
        return Environment.development;
      case 'staging':
      case 'stage':
        return Environment.staging;
      default:
        return Environment.production;
    }
  }

  /// Check if running in development
  static bool get isDevelopment => environment == Environment.development;

  /// Check if running in staging
  static bool get isStaging => environment == Environment.staging;

  /// Check if running in production
  static bool get isProduction => environment == Environment.production;

  /// Supabase URL
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw EnvironmentConfigException('SUPABASE_URL is not configured');
    }
    return url;
  }

  /// Supabase Anonymous Key
  static String get supabaseAnonKey {
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (key == null || key.isEmpty) {
      throw EnvironmentConfigException('SUPABASE_ANON_KEY is not configured');
    }
    return key;
  }

  /// Optional redirect URL for OAuth
  static String? get supabaseRedirectUrl {
    final url = dotenv.env['SUPABASE_REDIRECT_URL'];
    return (url != null && url.isNotEmpty) ? url : null;
  }

  /// Whether to show demo credentials on login screen
  static bool get showDemoCredentials {
    final show = dotenv.env['SHOW_DEMO_CREDENTIALS'] ?? 'false';
    return show.toLowerCase() == 'true';
  }

  /// Environment name for display
  static String get environmentName {
    switch (environment) {
      case Environment.development:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.production:
        return 'Production';
    }
  }
}

/// Exception thrown when environment configuration is invalid
class EnvironmentConfigException implements Exception {
  final String message;
  EnvironmentConfigException(this.message);

  @override
  String toString() => 'EnvironmentConfigException: $message';
}
