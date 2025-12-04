/// Application-wide configuration constants
class AppConfig {
  AppConfig._();

  static const String appName = 'EduSaaS';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // Cache durations
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(hours: 1);
  static const Duration longCacheDuration = Duration(hours: 24);
  
  // Sync intervals
  static const Duration syncInterval = Duration(minutes: 5);
  static const Duration offlineQueueRetryInterval = Duration(seconds: 30);
  
  // File upload limits
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int maxFileSizeBytes = 25 * 1024 * 1024; // 25MB
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
  static const List<String> allowedFileExtensions = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'];
  
  // Date formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  
  // Attendance
  static const int attendanceLateThresholdMinutes = 15;
  
  // Session
  static const Duration sessionTimeout = Duration(hours: 24);
}
