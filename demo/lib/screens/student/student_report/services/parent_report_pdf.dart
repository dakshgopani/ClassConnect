import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/student_report.dart';
import '../services/student_insight_engine.dart';

class ParentReportPdf {
  static pw.Document build(StudentReport report) {
    final pdf = pw.Document();
    final insight = StudentInsightEngine.generate(report);
    final currentDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    // Define colors
    final primaryColor = PdfColor.fromHex('#4CAF50');
    final accentColor = PdfColor.fromHex('#2196F3');
    final warningColor = PdfColor.fromHex('#FF9800');
    final successColor = PdfColor.fromHex('#4CAF50');
    final lightGray = PdfColor.fromHex('#F5F5F5');
    final darkGray = PdfColor.fromHex('#424242');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // ===== HEADER WITH COLORED BACKGROUND =====
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(color: primaryColor),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'STUDENT PROGRESS REPORT',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      currentDate,
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                    ),
                  ],
                ),
              ),

              // ===== STUDENT INFO SECTION =====
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                color: lightGray,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Student Name',
                          style: pw.TextStyle(fontSize: 10, color: darkGray),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          report.studentName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: darkGray,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Parent Email',
                          style: pw.TextStyle(fontSize: 10, color: darkGray),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          report.parentEmail,
                          style: pw.TextStyle(fontSize: 12, color: darkGray),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== PERFORMANCE METRICS =====
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('📊 Performance Metrics', accentColor),
                    pw.SizedBox(height: 16),
                    pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildMetricCard(
                            'Attendance',
                            '${report.attendancePercent.toStringAsFixed(1)}%',
                            report.attendancePercent >= 75
                                ? successColor
                                : warningColor,
                          ),
                        ),
                        pw.SizedBox(width: 16),
                        pw.Expanded(
                          child: _buildMetricCard(
                            'Average Quiz Score',
                            '${report.avgQuizScore.toStringAsFixed(1)}%',
                            report.avgQuizScore >= 60
                                ? successColor
                                : warningColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== ENGAGEMENT SUMMARY =====
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('🎯 Engagement Summary', accentColor),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: lightGray, width: 2),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _buildEngagementStat(
                            'PBL Submissions',
                            report.pblSubmitted,
                          ),
                          _buildEngagementStat(
                            'Community Posts',
                            report.communityPosts,
                          ),
                          _buildEngagementStat(
                            'Community Answers',
                            report.communityAnswers,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // ===== WEAK CONCEPTS =====
              if (report.weakConcepts.isNotEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        '⚠️ Areas Needing Attention',
                        warningColor,
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#FFF3E0'),
                          borderRadius: const pw.BorderRadius.all(
                            pw.Radius.circular(8),
                          ),
                        ),
                        child: pw.Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: report.weakConcepts
                              .map(
                                (w) => pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColors.white,
                                    borderRadius: const pw.BorderRadius.all(
                                      pw.Radius.circular(16),
                                    ),
                                    border: pw.Border.all(
                                      color: warningColor,
                                      width: 1,
                                    ),
                                  ),
                                  child: pw.Text(
                                    w,
                                    style: pw.TextStyle(
                                      fontSize: 10,
                                      color: darkGray,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

              pw.SizedBox(height: 20),

              // ===== AI INSIGHTS =====
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 24),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('🤖 AI-Powered Insights', primaryColor),
                    pw.SizedBox(height: 12),

                    // Headline
                    pw.Container(
                      padding: const pw.EdgeInsets.all(16),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#E8F5E9'),
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Text(
                        insight.headline,
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: darkGray,
                        ),
                      ),
                    ),

                    pw.SizedBox(height: 16),

                    // Strengths
                    if (insight.strengths.isNotEmpty) ...[
                      _buildInsightSection(
                        '✅ Strengths',
                        insight.strengths,
                        successColor,
                        PdfColor.fromHex('#E8F5E9'),
                      ),
                      pw.SizedBox(height: 12),
                    ],

                    // Concerns
                    if (insight.concerns.isNotEmpty) ...[
                      _buildInsightSection(
                        '⚠️ Areas of Concern',
                        insight.concerns,
                        warningColor,
                        PdfColor.fromHex('#FFF3E0'),
                      ),
                      pw.SizedBox(height: 12),
                    ],

                    // Recommendations
                    if (insight.recommendations.isNotEmpty)
                      _buildInsightSection(
                        '💡 Recommendations',
                        insight.recommendations,
                        accentColor,
                        PdfColor.fromHex('#E3F2FD'),
                      ),
                  ],
                ),
              ),

              pw.SizedBox(height: 24),

              // ===== FOOTER =====
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: lightGray,
                  border: pw.Border(
                    top: pw.BorderSide(color: primaryColor, width: 2),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'This report is generated automatically by the Student Progress System',
                      style: pw.TextStyle(fontSize: 10, color: darkGray),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'For questions or concerns, please contact your teacher',
                      style: pw.TextStyle(fontSize: 9, color: darkGray),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  // Helper method for section headers
  static pw.Widget _buildSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: color, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16,
          fontWeight: pw.FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // Helper method for metric cards
  static pw.Widget _buildMetricCard(
    String label,
    String value,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColor.fromHex('#424242'),
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for engagement stats
  static pw.Widget _buildEngagementStat(String label, int value) {
    return pw.Column(
      children: [
        pw.Text(
          value.toString(),
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#2196F3'),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('#757575')),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  // Helper method for insight sections
  static pw.Widget _buildInsightSection(
    String title,
    List<String> items,
    PdfColor borderColor,
    PdfColor bgColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: bgColor,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: borderColor,
            ),
          ),
          pw.SizedBox(height: 8),
          ...items.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6, left: 8),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(
                      fontSize: 11,
                      color: borderColor,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      item,
                      style: pw.TextStyle(
                        fontSize: 11,
                        color: PdfColor.fromHex('#424242'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
