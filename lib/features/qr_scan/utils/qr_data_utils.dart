/// Utilities for encoding/decoding student QR code data.
///
/// QR format: `SM:{tenantId}:{admissionNumber}`
class QrDataUtils {
  QrDataUtils._();

  static const String _prefix = 'SM';

  /// Encode student data into a QR string.
  static String encode({
    required String tenantId,
    required String admissionNumber,
  }) {
    return '$_prefix:$tenantId:$admissionNumber';
  }

  /// Decode a QR string into its components.
  /// Returns null if the format is invalid.
  static QrStudentData? decode(String raw) {
    final parts = raw.split(':');
    if (parts.length != 3 || parts[0] != _prefix) return null;
    return QrStudentData(tenantId: parts[1], admissionNumber: parts[2]);
  }

  /// Check whether [raw] looks like a valid student QR code.
  static bool isValid(String raw) => decode(raw) != null;
}

class QrStudentData {
  final String tenantId;
  final String admissionNumber;

  const QrStudentData({
    required this.tenantId,
    required this.admissionNumber,
  });
}
