import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/gemini_quiz_service.dart';

class QuizDetailScreen extends StatefulWidget {
  final String classId;
  final String conceptId; // chapterId
  final String conceptName; // chapter name
  final int order;
  final List<String> chapterConcepts;

  const QuizDetailScreen({
    super.key,
    required this.classId,
    required this.conceptId,
    required this.conceptName,
    required this.order,
    required this.chapterConcepts,
  });

  @override
  State<QuizDetailScreen> createState() => _QuizDetailScreenState();
}

class _QuizDetailScreenState extends State<QuizDetailScreen> {
  bool loading = false;
  bool isPublished = false; // 🔒 STEP-4 FLAG

  DocumentReference get quizDoc => FirebaseFirestore.instance
      .collection('classes')
      .doc(widget.classId)
      .collection('quizzes')
      .doc(widget.conceptId);

  CollectionReference get quizRef => quizDoc.collection('questions');

  @override
  void initState() {
    super.initState();
    _loadQuizStatus();
  }

  /// 🔹 LOAD QUIZ STATUS (STEP-4)
  Future<void> _loadQuizStatus() async {
    final snap = await quizDoc.get();
    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;
      if (data['status'] == 'published') {
        setState(() => isPublished = true);
      }
    }
  }

  /// 🔹 GENERATE CHAPTER QUIZ
  Future<void> generateQuiz() async {
    if (isPublished) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Quiz is already published and locked 🔒"),
        ),
      );
      return;
    }

    setState(() => loading = true);

    // 1️⃣ Generate questions from Gemini
    final questions = await GeminiQuizService.generateQuizForChapter(
      chapterName: widget.conceptName,
      concepts: widget.chapterConcepts,
    );

    // 2️⃣ Create / update quiz metadata
    await quizDoc.set({
      'quizId': quizDoc.id,
      'chapterId': widget.conceptId,
      'chapterName': widget.conceptName,
      'concepts': widget.chapterConcepts,
      'chapterOrder': widget.order,
      'status': 'draft',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3️⃣ Clear old questions (VERY IMPORTANT)
    final oldQuestions = await quizRef.get();
    for (final doc in oldQuestions.docs) {
      await doc.reference.delete();
    }

    // 4️⃣ STRICT syllabus-aligned concept mapping
    final syllabusConcepts = widget.chapterConcepts;

    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];

      // 🔐 Enforce syllabus concept names
      String assignedConcept;
      if (q.containsKey('concept') && syllabusConcepts.contains(q['concept'])) {
        // Gemini returned a valid syllabus concept
        assignedConcept = q['concept'];
      } else {
        // Fallback: deterministic round-robin mapping
        assignedConcept = syllabusConcepts[i % syllabusConcepts.length];
      }

      await quizRef.add({
        'question': q['question'],
        'options': q['options'],
        'correctAnswer': q['correctAnswer'],
        'difficulty': q['difficulty'],

        // ✅ GUARANTEED syllabus-aligned concept
        'concept': assignedConcept,

        // Optional but recommended
        'chapter': widget.conceptName,
        'order': i + 1,
      });
    }

    // 5️⃣ Mark chapter as having a quiz
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('chapters')
        .doc(widget.conceptId)
        .update({'hasQuiz': true});

    setState(() => loading = false);
  }

  /// 🔹 PUBLISH QUIZ (LOCK FOREVER + CREATE POST)
  Future<void> publishQuiz() async {
    if (isPublished) return;

    final now = DateTime.now();

    // 1️⃣ Publish the quiz
    await quizDoc.update({
      'status': 'published',
      'publishedAt': FieldValue.serverTimestamp(),
    });

    // 2️⃣ CREATE POST FOR STUDENTS (🔥 STEP-A CORE)
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('posts')
        .doc(widget.conceptId) // chapterId = postId
        .set({
          'type': 'chapter_quiz',
          'chapterId': widget.conceptId,
          'chapterName': widget.conceptName,
          'classId': widget.classId,
          'publishedAt': Timestamp.fromDate(now),
          'deadline': Timestamp.fromDate(now.add(const Duration(days: 7))),
          'status': 'active',
        });

    // 3️⃣ Update UI state
    setState(() => isPublished = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Chapter quiz published & posted to students 🔔"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: Text(
          widget.conceptName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3D),
          ),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        foregroundColor: const Color(0xFF0D1B3D),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (isPublished)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.greenAccent, size: 14),
                  SizedBox(width: 6),
                  Text(
                    "LOCKED",
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          /// 🔹 ACTION BAR
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E6BFF).withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading || isPublished ? null : generateQuiz,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_fix_high),
                    label: Text(loading ? "Generating..." : "Generate AI Quiz"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isPublished ? null : publishQuiz,
                    icon: Icon(
                      Icons.publish,
                      color: isPublished
                          ? const Color(0xFF8DA6D8)
                          : const Color(0xFF2E6BFF),
                    ),
                    label: Text(
                      isPublished ? "Published" : "Publish",
                      style: TextStyle(
                        color: isPublished
                            ? const Color(0xFF8DA6D8)
                            : const Color(0xFF2E6BFF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: isPublished
                            ? const Color(0x1A2E6BFF)
                            : const Color(0xFF2E6BFF),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isPublished)
            Container(
              width: double.infinity,
              color: Colors.green.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
              child: const Text(
                "This quiz is live. Changes are disabled to maintain integrity.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF2E6BFF), fontSize: 12),
              ),
            ),

          /// 🔹 QUESTIONS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: quizRef.orderBy('order').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.quiz_outlined,
                          size: 64,
                          color: const Color(0xFF2E6BFF).withOpacity(0.15),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No questions generated yet",
                          style: TextStyle(
                            color: const Color(0xFF5C6B8C),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap 'Generate AI Quiz' to start",
                          style: TextStyle(
                            color: const Color(0xFF8DA6D8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final questions = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index].data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x1A2E6BFF)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E6BFF).withOpacity(0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF2E6BFF,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${index + 1}",
                                    style: const TextStyle(
                                      color: Color(0xFF0D1B3D),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    q['question'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D1B3D),
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: q['difficulty'] == 'easy'
                                        ? const Color(0xFFDCFCE7)
                                        : q['difficulty'] == 'medium'
                                        ? const Color(0xFFFFEDD5)
                                        : const Color(0xFFFEE2E2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: q['difficulty'] == 'easy'
                                          ? const Color(0xFF86EFAC)
                                          : q['difficulty'] == 'medium'
                                          ? const Color(0xFFFBBF24)
                                          : const Color(0xFFFCA5A5),
                                    ),
                                  ),
                                  child: Text(
                                    q['difficulty'].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: q['difficulty'] == 'easy'
                                          ? const Color(0xFF166534)
                                          : q['difficulty'] == 'medium'
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFFB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(color: Color(0x1A2E6BFF)),
                            const SizedBox(height: 16),

                            ...List<String>.from(q['options']).map((opt) {
                              final isCorrect = opt == q['correctAnswer'];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCorrect
                                        ? const Color(0xFF86EFAC)
                                        : const Color(0x1A2E6BFF),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      size: 18,
                                      color: isCorrect
                                          ? const Color(0xFF166534)
                                          : const Color(0xFFA5B2C8),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        opt,
                                        style: TextStyle(
                                          color: isCorrect
                                              ? const Color(0xFF0D1B3D)
                                              : const Color(0xFF5C6B8C),
                                          fontWeight: isCorrect
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
