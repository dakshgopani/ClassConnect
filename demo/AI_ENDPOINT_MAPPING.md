# AI Endpoint Mapping

This document maps each migrated Gemini-backed method to the backend API endpoint now used.

## Core Quiz and Validation Services

- File: lib/services/gemini_quiz_service.dart
  - `GeminiQuizService.generateQuizForConcept(...)` -> `POST /api/v1/quiz/concept`
  - `GeminiQuizService.generateQuizForChapter(...)` -> `POST /api/v1/quiz/chapter`

- File: lib/services/gemini_diagnostic_service.dart
  - `GeminiDiagnosticService.generateDiagnosticQuiz(...)` -> `POST /api/v1/quiz/diagnostic`

- File: lib/services/gemini_text_validation_service.dart
  - `GeminiTextValidationService.validateTextExplanation(...)` -> `POST /api/v1/validation/text`

- File: lib/services/gemini_video_validation_service.dart
  - `GeminiVideoValidationService.validateVideoExplanation(...)` -> `POST /api/v1/validation/video`

- File: lib/services/gemini_homework_service.dart
  - `GeminiHomeworkService.generateHomework(...)` -> `POST /api/v1/homework/generate`
  - `GeminiHomeworkService.evaluateHomework(...)` -> `POST /api/v1/homework/evaluate`

## Teacher PBL Service

- File: lib/screens/teacher/pbl/services/gemini_service.dart
  - `GeminiService.extractConcepts(...)` -> internally uses `POST /api/v1/pbl/chapters-concepts` and flattens concepts
  - `GeminiService.extractChaptersAndConcepts(...)` -> `POST /api/v1/pbl/chapters-concepts`
  - `GeminiService.generateProjectScenarios(...)` -> `POST /api/v1/pbl/scenarios`
  - `GeminiService.generateProjectDetails(...)` -> `POST /api/v1/pbl/project-details`
  - `GeminiService.extractTextFromPdf(...)` -> `POST /api/v1/pbl/extract/pdf`
  - `GeminiService.extractTextFromDoc(...)` -> `POST /api/v1/pbl/extract/doc`
  - `GeminiService.extractTextFromImage(...)` -> `POST /api/v1/pbl/extract/image`

## Notes

- All migrated services now use the backend base URL placeholder:
  - `ClassConnectAIBackend_BASE_URL`
- Existing method signatures and return shapes were preserved to avoid changing downstream UI/business logic.
