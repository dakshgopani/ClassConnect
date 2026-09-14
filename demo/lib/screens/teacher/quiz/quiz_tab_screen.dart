import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/cc_breadcrumb_bar.dart';
import 'quiz_detail_screen.dart';

class QuizTabScreen extends StatelessWidget {
  final String classId;
  final String? className;

  const QuizTabScreen({super.key, required this.classId, this.className});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (className != null && className!.isNotEmpty) {
      if (isDesktop) return _buildDesktopLayout(context, className!);
      return _buildMobileLayout(context, className!);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('classes').doc(classId).snapshots(),
      builder: (context, snapshot) {
        final fetchedName = snapshot.data?.data()?['class_name'] ?? 'Class';
        if (isDesktop) {
          return _buildDesktopLayout(context, fetchedName);
        }
        return _buildMobileLayout(context, fetchedName);
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, String currentClassName) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          CCBreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Classes',
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              BreadcrumbItem(
                label: currentClassName,
                onTap: () => Navigator.pop(context),
              ),
              const BreadcrumbItem(
                label: 'Quizzes',
              ),
            ],
          ),
          Expanded(
            child: _buildDesktopContent(context, currentClassName),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context, String currentClassName) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('chapters')
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CcLoadingAnimation(color: Color(0xFF3B82F6)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.book_outlined,
                    size: 72,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "No chapters found",
                  style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "No syllabus chapters available for this class yet.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to Class'),
                ),
              ],
            ),
          );
        }

        final chapters = snapshot.data!.docs;

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.quiz_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Smart Quiz Chapters',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Manage chapter-wise quizzes with automated question generation and progress tracking.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${chapters.length} ${chapters.length == 1 ? 'Chapter' : 'Chapters'}',
                            style: const TextStyle(
                              color: Color(0xFFEC4899),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      itemCount: chapters.length,
                      itemBuilder: (context, index) {
                        final chapterDoc = chapters[index];
                        return _ChapterCardDesktop(
                          classId: classId,
                          chapterDoc: chapterDoc,
                          index: index,
                          className: currentClassName,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, String currentClassName) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D1B3D)),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: const Text(
          'Smart Quiz Chapters',
          style: TextStyle(
            color: Color(0xFF0D1B3D),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(classId)
              .collection('chapters')
              .orderBy('order')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CcLoadingAnimation(color: Color(0xFF2E6BFF)),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(context);
            }

            final chapters = snapshot.data!.docs;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Text(
                    'Smart Quiz Chapters',
                    style: TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Manage chapter-wise quizzes with cleaner progress tracking.',
                    style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 13),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: chapters.length,
                    itemBuilder: (context, index) {
                      final chapterDoc = chapters[index];
                      return _ChapterCard(
                        classId: classId,
                        chapterDoc: chapterDoc,
                        index: index,
                        className: currentClassName,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.indigo.shade200,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No chapters found",
            style: TextStyle(
              color: Colors.indigo.shade100,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No syllabus chapters available for this class yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF5C6B8C), fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            "Add optional syllabus during class creation to auto-generate chapters and concepts.",
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF8DA6D8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final String classId;
  final QueryDocumentSnapshot chapterDoc;
  final int index;
  final String? className;

  const _ChapterCard({
    required this.classId,
    required this.chapterDoc,
    required this.index,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    final data = chapterDoc.data() as Map<String, dynamic>;
    final String chapterName = data['title'] ?? data['name'] ?? 'Chapter';
    final int order = data['order'] ?? index + 1;
    final List<String> concepts = List<String>.from(data['concepts'] ?? []);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(chapterDoc.id)
          .snapshots(),
      builder: (context, quizSnap) {
        bool isCompleted = false;

        if (quizSnap.hasData && quizSnap.data!.exists) {
          final quizData = quizSnap.data!.data() as Map<String, dynamic>;
          isCompleted = quizData['status'] == 'published';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : const Color(0x1A2E6BFF),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E6BFF).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor:
                  Colors.transparent, // Remove expansion tile dividers
            ),
            child: ExpansionTile(
              iconColor: const Color(0xFF2E6BFF),
              collapsedIconColor: const Color(0xFFA5B2C8),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : const Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : const Color(0xFFA5B2C8),
                  size: 20,
                ),
              ),
              title: Text(
                "Chapter $order",
                style: const TextStyle(
                  color: Color(0xFF2E6BFF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  chapterName,
                  style: const TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: isCompleted
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text(
                        "Published",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : null, // Let default icon show if not completed
              children: [
                const Divider(color: Color(0x1A2E6BFF)),
                const SizedBox(height: 12),

                // Concepts List
                if (concepts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: const Color(0xFFA5B2C8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "No concepts added yet",
                          style: const TextStyle(
                            color: Color(0xFF8DA6D8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...concepts.map(
                    (concept) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade200,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              concept,
                              style: TextStyle(
                                color: const Color(0xFF5C6B8C),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizDetailScreen(
                            classId: classId,
                            conceptId: chapterDoc.id,
                            conceptName: chapterName,
                            order: order,
                            chapterConcepts: concepts,
                            className: className,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      isCompleted
                          ? Icons.visibility_rounded
                          : Icons.edit_note_rounded,
                      size: 18,
                      color: isCompleted
                          ? Colors.black
                          : const Color(0xFF2E6BFF),
                    ),
                    label: Text(
                      isCompleted ? "View Published Quiz" : "Manage Quiz",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? Colors.black
                            : const Color(0xFF2E6BFF),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? Colors.greenAccent
                          : Colors.transparent,
                      foregroundColor: isCompleted
                          ? Colors.black
                          : const Color(0xFF2E6BFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: isCompleted
                          ? null
                          : const BorderSide(color: Color(0xFF2E6BFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isCompleted ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChapterCardDesktop extends StatelessWidget {
  final String classId;
  final QueryDocumentSnapshot chapterDoc;
  final int index;
  final String? className;

  const _ChapterCardDesktop({
    required this.classId,
    required this.chapterDoc,
    required this.index,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    final data = chapterDoc.data() as Map<String, dynamic>;
    final String chapterName = data['title'] ?? data['name'] ?? 'Chapter';
    final int order = data['order'] ?? index + 1;
    final List<String> concepts = List<String>.from(data['concepts'] ?? []);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(chapterDoc.id)
          .snapshots(),
      builder: (context, quizSnap) {
        bool isCompleted = false;

        if (quizSnap.hasData && quizSnap.data!.exists) {
          final quizData = quizSnap.data!.data() as Map<String, dynamic>;
          isCompleted = quizData['status'] == 'published';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.green : const Color(0xFF64748B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Chapter $order",
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chapterName,
                            style: const TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock, color: Colors.green, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              "Published",
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 16),
                if (concepts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "No concepts added yet",
                          style: TextStyle(
                            color: const Color(0xFF94A3B8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: concepts.map((concept) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          concept,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => QuizDetailScreen(
                              classId: classId,
                              conceptId: chapterDoc.id,
                              conceptName: chapterName,
                              order: order,
                              chapterConcepts: concepts,
                              className: className,
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isCompleted
                            ? Icons.visibility_rounded
                            : Icons.edit_note_rounded,
                        size: 18,
                        color: isCompleted
                            ? Colors.white
                            : const Color(0xFF3B82F6),
                      ),
                      label: Text(
                        isCompleted ? "View Published Quiz" : "Manage Quiz",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isCompleted
                              ? Colors.white
                              : const Color(0xFF3B82F6),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted
                            ? Colors.green
                            : Colors.white,
                        foregroundColor: isCompleted
                            ? Colors.white
                            : const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        side: isCompleted
                            ? null
                            : const BorderSide(color: Color(0xFF3B82F6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
