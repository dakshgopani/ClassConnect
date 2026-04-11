import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/pbl_project.dart';

class GeminiService {
  static const String _baseUrl = 'https://samyak000-amep.hf.space';
  static const String _chaptersConceptsUrl =
      '$_baseUrl/api/v1/pbl/chapters-concepts';
  static const String _scenariosUrl = '$_baseUrl/api/v1/pbl/scenarios';
  static const String _projectDetailsUrl =
      '$_baseUrl/api/v1/pbl/project-details';
  static const String _extractPdfUrl = '$_baseUrl/api/v1/pbl/extract/pdf';
  static const String _extractDocUrl = '$_baseUrl/api/v1/pbl/extract/doc';
  static const String _extractImageUrl = '$_baseUrl/api/v1/pbl/extract/image';

  /// STEP 1: Extract main concepts
  static Future<List<String>> extractConcepts(String syllabusText) async {
    final chapters = await extractChaptersAndConcepts(syllabusText);
    final concepts = <String>[];
    for (final chapterConcepts in chapters.values) {
      for (final concept in chapterConcepts) {
        if (concept.isNotEmpty && !concepts.contains(concept)) {
          concepts.add(concept);
        }
      }
    }
    return concepts;
  }

  /// STEP 1 (New): Extract Chapters and Concepts
  static Future<Map<String, List<String>>> extractChaptersAndConcepts(
    String syllabusText,
  ) async {
    try {
      final body = await _postJson(_chaptersConceptsUrl, {
        'syllabusText': syllabusText,
      });
      final List<dynamic> chapters = body['chapters'] ?? [];

      final Map<String, List<String>> result = {};
      for (final chapter in chapters) {
        if (chapter is Map) {
          final String name = _toStringValue(chapter['name']);
          final List<dynamic> conceptsJson = chapter['concepts'] ?? [];
          final List<String> concepts = conceptsJson
              .map((c) => _toStringValue(c))
              .where((c) => c.isNotEmpty)
              .toList();
          if (name.isNotEmpty) {
            result[name] = concepts;
          }
        }
      }
      return result;
    } catch (e) {
      debugPrint('Syllabus extraction error: $e');
      return {};
    }
  }

  /// STEP 2: Generate Problem Scenarios (Options)
  static Future<List<Map<String, dynamic>>> generateProjectScenarios(
    List<String> concepts,
  ) async {
    try {
      final json = await _postJson(_scenariosUrl, {'concepts': concepts});
      final List<dynamic> list = json['scenarios'] ?? [];
      return list.map((e) {
        if (e is Map) {
          final map = <String, dynamic>{
            'title': _toStringValue(e['title']),
            'problemStatement': _toStringValue(e['problemStatement']),
            'educationalValue': _toStringValue(e['educationalValue']),
          };

          final miniList = e['miniProjects'];
          if (miniList is List) {
            map['miniProjects'] = miniList.map((m) {
              if (m is Map) {
                return <String, String>{
                  'title': _toStringValue(m['title']),
                  'description': _toStringValue(m['description']),
                };
              }
              return <String, String>{};
            }).toList();
          } else {
            map['miniProjects'] = <Map<String, String>>[];
          }

          return map;
        }
        return <String, dynamic>{};
      }).toList();
    } catch (e) {
      debugPrint('Scenario generation error: $e');
      return [];
    }
  }

  /// STEP 3: Generate full PBL Project from selected scenario
  static Future<PblProject> generateProjectDetails(
    String title,
    String problemStatement,
    List<String> concepts,
  ) async {
    try {
      final json = await _postJson(_projectDetailsUrl, {
        'title': title,
        'problemStatement': problemStatement,
        'concepts': concepts,
      });

      final learningObjectives = (json['learningObjectives'] ?? [])
          .map((e) => _toStringValue(e))
          .toList()
          .cast<String>();

      final milestones = (json['milestones'] ?? [])
          .map((e) => _toStringValue(e))
          .toList()
          .cast<String>();

      final List<Map<String, dynamic>> rubricList = [];
      if (json['rubric'] is List) {
        for (final item in json['rubric']) {
          if (item is Map) {
            rubricList.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final List<Map<String, String>> miniProjectsList = [];
      if (json['miniProjects'] is List) {
        for (final item in json['miniProjects']) {
          if (item is Map) {
            miniProjectsList.add(
              Map<String, String>.from(
                item.map((k, v) => MapEntry(k.toString(), _toStringValue(v))),
              ),
            );
          }
        }
      }

      return PblProject(
        title: title,
        problemStatement: problemStatement,
        learningObjectives: learningObjectives,
        milestones: milestones,
        rubric: rubricList,
        miniProjects: miniProjectsList,
      );
    } catch (e) {
      debugPrint('Project details generation error: $e');
      return PblProject(
        title: title,
        problemStatement: problemStatement,
        learningObjectives: const [],
        milestones: const [],
        rubric: const [],
        miniProjects: const [],
      );
    }
  }

  /// Extract text from PDF file
  static Future<String> extractTextFromPdf(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final body = await _postJson(_extractPdfUrl, {
        'filename': _fileName(file),
        'contentBase64': base64Encode(bytes),
      });
      return _toStringValue(body['text']).trim();
    } catch (e) {
      debugPrint('PDF extraction error: $e');
      return '';
    }
  }

  /// Extract text from image
  static Future<String> extractTextFromImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final body = await _postJson(_extractImageUrl, {
        'filename': _fileName(file),
        'mimeType': _imageMimeType(file),
        'contentBase64': base64Encode(bytes),
      });
      return _toStringValue(body['text']).trim();
    } catch (e) {
      debugPrint('Image extraction error: $e');
      return '';
    }
  }

  /// Extract text from DOC/DOCX file
  static Future<String> extractTextFromDoc(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final body = await _postJson(_extractDocUrl, {
        'filename': _fileName(file),
        'contentBase64': base64Encode(bytes),
      });
      return _toStringValue(body['text']).trim();
    } catch (e) {
      debugPrint('DOC extraction error: $e');
      return '';
    }
  }

  static Future<Map<String, dynamic>> _postJson(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('API failed with ${response.statusCode}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static String _fileName(File file) {
    final path = file.path;
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isNotEmpty ? parts.last : 'file';
  }

  static String _imageMimeType(File file) {
    final lower = file.path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'image/jpeg';
  }

  /// Helper to safely convert any value to String
  static String _toStringValue(dynamic value) {
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    if (value is Map) return value.toString();
    if (value is List) return value.toString();
    return value?.toString() ?? '';
  }
}




