import 'package:printing/printing.dart';
import 'parent_report_pdf.dart';
import 'email_service.dart';
import '../models/student_report.dart';

class ParentReportExport {
  static Future<void> preview(StudentReport report) async {
    final pdf = ParentReportPdf.build(report);

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static Future<void> share(StudentReport report) async {
    final pdf = ParentReportPdf.build(report);

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${report.studentName}_Parent_Report.pdf',
    );
  }

  /// Send the report PDF to parent's email
  static Future<bool> sendToParentEmail(
    StudentReport report, {
    String? customMessage,
  }) async {
    try {
      final pdf = ParentReportPdf.build(report);
      final pdfBytes = await pdf.save();

      return await EmailService.sendReportEmail(
        recipientEmail: report.parentEmail,
        studentName: report.studentName,
        pdfBytes: pdfBytes,
        customMessage: customMessage,
      );
    } catch (e) {
      print('Error sending report email: $e');
      return false;
    }
  }
}
