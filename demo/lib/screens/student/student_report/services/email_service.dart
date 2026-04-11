import 'dart:typed_data';
import 'dart:io';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';

class EmailService {
  // Email configuration for Gmail
  static const String _senderEmail = 'rudraparmar1309@gmail.com';
  static const String _senderName = 'Student Progress System';

  // App password for Gmail
  static String _appPassword = 'uxka egtr btiq redq';

  /// Configure the app password for Gmail
  static void setAppPassword(String password) {
    _appPassword = password;
  }

  /// Send student report PDF via email
  static Future<bool> sendReportEmail({
    required String recipientEmail,
    required String studentName,
    required Uint8List pdfBytes,
    String? customMessage,
  }) async {
    try {
      // Save PDF bytes to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/${studentName}_Progress_Report.pdf',
      );
      await tempFile.writeAsBytes(pdfBytes);

      // Configure Gmail SMTP server
      final smtpServer = gmail(_senderEmail, _appPassword);

      // Create the email message
      final message = Message()
        ..from = Address(_senderEmail, _senderName)
        ..recipients.add(recipientEmail)
        ..subject = 'Student Progress Report - $studentName'
        ..text = customMessage ?? _getDefaultMessage(studentName)
        ..html = _getHtmlMessage(studentName, customMessage)
        ..attachments.add(FileAttachment(tempFile));

      // Send the email
      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');

      // Clean up temporary file
      await tempFile.delete();

      return true;
    } on MailerException catch (e) {
      print('Email sending failed: $e');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    } catch (e) {
      print('Unexpected error sending email: $e');
      return false;
    }
  }

  /// Default plain text message
  static String _getDefaultMessage(String studentName) {
    return '''
Dear Parent/Guardian,

Please find attached the progress report for $studentName.

This report includes:
- Attendance record
- Quiz performance and scores
- Weak concepts that need attention
- Project-Based Learning (PBL) engagement
- Community participation
- Personalized feedback and recommendations

Please review the report and feel free to contact us if you have any questions or concerns.

Best regards,
Student Progress System
''';
  }

  /// HTML formatted message for better presentation
  static String _getHtmlMessage(String studentName, String? customMessage) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background-color: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .footer { background-color: #f4f4f4; padding: 10px; text-align: center; font-size: 12px; }
    ul { padding-left: 20px; }
  </style>
</head>
<body>
  <div class="header">
    <h2>Student Progress Report</h2>
  </div>
  <div class="content">
    <p>Dear Parent/Guardian,</p>
    
    <p>${customMessage ?? 'Please find attached the progress report for <strong>$studentName</strong>.'}</p>
    
    <p>This comprehensive report includes:</p>
    <ul>
      <li>Attendance record</li>
      <li>Quiz performance and average scores</li>
      <li>Identified weak concepts that need attention</li>
      <li>Project-Based Learning (PBL) engagement metrics</li>
      <li>Community participation statistics</li>
      <li>Personalized AI-generated feedback and recommendations</li>
    </ul>
    
    <p>Please review the attached PDF report carefully. If you have any questions or concerns about your child's progress, please don't hesitate to contact us.</p>
    
    <p>Best regards,<br>
    <strong>Student Progress System</strong></p>
  </div>
  <div class="footer">
    <p>This is an automated message. Please do not reply to this email.</p>
  </div>
</body>
</html>
''';
  }
}
