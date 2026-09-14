import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Stub email service for both mobile and web.
///
/// In a production environment you would replace this with a call to a
/// Firebase Cloud Function (or another backend) that actually sends the
/// email. For now the method logs the request and returns `true` so the
/// rest of the app can compile and run.
class EmailService {
  /// Sends a PDF report via email.
  ///
  /// Returns `true` on success. The implementation is a no‑op placeholder.
  static Future<bool> sendReportEmail({
    required String recipientEmail,
    required String studentName,
    required Uint8List pdfBytes,
    String? customMessage,
  }) async {
    debugPrint('EmailService.sendReportEmail called');
    debugPrint('Recipient: $recipientEmail');
    debugPrint('Student: $studentName');
    debugPrint('PDF size: ${pdfBytes.lengthInBytes} bytes');
    debugPrint('Custom message: ${customMessage ?? ""}');
    // TODO: integrate with real backend (e.g., Firebase Cloud Function).
    return true;
  }
}
