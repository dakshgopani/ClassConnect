import 'dart:io';
import 'package:flutter/material.dart';
import 'package:demo/services/firestore_service.dart';
import 'package:demo/services/moderation_service.dart';
import 'package:demo/models/question.dart';
import 'package:demo/models/answer.dart';
import 'package:demo/models/reaction.dart';
import 'package:demo/widgets/tag_widget.dart';
import 'package:demo/widgets/answer_card.dart';
import 'package:demo/widgets/common_widgets.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';
import 'package:demo/widgets/ui/cc_dialog.dart';
import 'package:demo/widgets/ui/cc_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuestionDetailScreen extends StatefulWidget {
  final String questionId;

  const QuestionDetailScreen({super.key, required this.questionId});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ModerationService _moderationService = ModerationService();
  final TextEditingController _answerController = TextEditingController();
  late final String _currentUserId;
  String _userName = 'Student';
  String _userAvatar = '👤';
  bool _isSubmittingAnswer = false;
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey _attachKey = GlobalKey();
  late final Stream<Question?> _questionStream;
  late final Stream<List<Answer>> _answersStream;

  // Uploaded files
  File? _selectedImage;
  File? _selectedVideo;
  File? _selectedDocument;
  String? _uploadedFileName;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadUserData();

    _questionStream = Stream.fromFuture(
      _firestoreService.getQuestionById(widget.questionId),
    );

    _answersStream = _firestoreService.getAnswersStream(widget.questionId);
  }

  Future<void> _loadUserData() async {
    final userData = await _firestoreService.getUserData(_currentUserId);
    if (userData != null && mounted) {
      setState(() {
        _userName = userData['name'] ?? 'Student';
        _userAvatar = userData['photoUrl'] ?? '👤';
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _selectedVideo = null;
          _selectedDocument = null;
          _uploadedFileName = image.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _selectedVideo = null;
          _selectedDocument = null;
          _uploadedFileName = photo.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing photo: $e')));
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedVideo = File(video.path);
          _selectedImage = null;
          _selectedDocument = null;
          _uploadedFileName = video.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking video: $e')));
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedDocument = File(result.files.single.path!);
          _selectedImage = null;
          _selectedVideo = null;
          _uploadedFileName = result.files.single.name;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking document: $e')));
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedImage = null;
      _selectedVideo = null;
      _selectedDocument = null;
      _uploadedFileName = null;
    });
  }

  Future<void> _submitAnswer() async {
    // Check if there's text or an attachment
    if (_answerController.text.trim().isEmpty &&
        _selectedImage == null &&
        _selectedVideo == null &&
        _selectedDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your answer or attach a file'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingAnswer = true;
    });

    String? moderationError;

    // Moderate based on content type
    if (_answerController.text.trim().isNotEmpty) {
      // Moderate text
      moderationError = await _moderationService.moderateAnswer(
        content: _answerController.text,
      );
    }

    if (_selectedVideo != null) {
      // Moderate video
      moderationError = await _moderationService.moderateVideo(
        videoPath: _selectedVideo!.path,
      );
    }

    if (_selectedImage != null) {
      // Moderate image (placeholder)
      moderationError = await _moderationService.moderateImage(
        imagePath: _selectedImage!.path,
      );
    }

    if (_selectedDocument != null) {
      // Moderate document (placeholder)
      moderationError = await _moderationService.moderateDocument(
        documentPath: _selectedDocument!.path,
      );
    }

    setState(() {
      _isSubmittingAnswer = false;
    });

    if (moderationError != null) {
      // Content was rejected
      if (mounted) {
        _showModerationDialog('Answer Not Allowed', moderationError);
      }
      return;
    }

    // Content approved, post the answer
    String content = _answerController.text.trim();
    if (_uploadedFileName != null) {
      content = content.isEmpty
          ? '[Attachment: $_uploadedFileName]'
          : '$content\n[Attachment: $_uploadedFileName]';
    }

    try {
      await _firestoreService.addAnswer(
        questionId: widget.questionId,
        userId: _currentUserId,
        userName: _userName,
        userAvatar: _userAvatar,
        content: content,
      );

      setState(() {
        _answerController.clear();
        _selectedImage = null;
        _selectedVideo = null;
        _selectedDocument = null;
        _uploadedFileName = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Answer posted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting answer: $e')));
      }
    }
  }

  void _showModerationDialog(String title, String message) {
    showCcDialog(
      context: context,
      title: title,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }

  Future<void> _showAttachmentSheet() async {
    final selected = await showCcSheet<String>(
      context: context,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Attach a file',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              CcButton(
                label: 'Photo',
                variant: CcButtonVariant.secondary,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop('image'),
              ),
              const SizedBox(height: 10),
              CcButton(
                label: 'Camera',
                variant: CcButtonVariant.secondary,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop('camera'),
              ),
              const SizedBox(height: 10),
              CcButton(
                label: 'Video',
                variant: CcButtonVariant.secondary,
                icon: const Icon(Icons.videocam_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop('video'),
              ),
              const SizedBox(height: 10),
              CcButton(
                label: 'Document',
                variant: CcButtonVariant.secondary,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                onPressed: () => Navigator.of(context).pop('document'),
              ),
              const SizedBox(height: 10),
              CcButton(
                label: 'Cancel',
                variant: CcButtonVariant.ghost,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected == null) return;

    switch (selected) {
      case 'image':
        await _pickImage();
        break;
      case 'camera':
        await _capturePhoto();
        break;
      case 'video':
        await _pickVideo();
        break;
      case 'document':
        await _pickDocument();
        break;
    }
  }

  void _onAnswerReaction(Answer answer, ReactionType type) {
    final hasReaction = answer.reactions.any(
      (r) => r.userId == _currentUserId && r.type == type,
    );

    if (hasReaction) {
      _firestoreService.removeReactionFromAnswer(
        widget.questionId,
        answer.id,
        _currentUserId,
        type,
      );
    } else {
      _firestoreService.addReactionToAnswer(
        widget.questionId,
        answer.id,
        _currentUserId,
        type,
      );
    }
  }

  void _onQuestionReaction(Question question, ReactionType type) {
    final hasReaction = question.reactions.any(
      (r) => r.userId == _currentUserId && r.type == type,
    );

    if (hasReaction) {
      _firestoreService.removeReactionFromQuestion(
        question.id,
        _currentUserId,
        type,
      );
    } else {
      _firestoreService.addReactionToQuestion(
        question.id,
        _currentUserId,
        type,
      );
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Question?>(
      stream: _questionStream,
      builder: (context, questionSnapshot) {
        if (questionSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFFF4F8FF),
            appBar: AppBar(
              title: const Text(
                'Question Details',
                style: TextStyle(color: Color(0xFF0D1B3D)),
              ),
              backgroundColor: const Color(0xFFF4F8FF),
              foregroundColor: const Color(0xFF0D1B3D),
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                ), // Modern rounded back icon
                color: Color(0xFF0D1B3D),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (questionSnapshot.hasError || questionSnapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Question')),
            body: const Center(child: Text('Question not found')),
          );
        }

        final question = questionSnapshot.data!;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F8FF),
          appBar: AppBar(
            title: const Text(
              'Question Details',
              style: TextStyle(color: Color(0xFF0D1B3D)),
            ),
            backgroundColor: const Color(0xFFF4F8FF),
            foregroundColor: const Color(0xFF0D1B3D),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
              ), // Modern rounded back icon
              color: Color(0xFF0D1B3D),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
          ),
          body: CcDecoratedBackground(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          question.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0D1B3D),
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Author info
                        Row(
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircleAvatar(
                                backgroundColor: const Color(0xFFEAF1FF),
                                backgroundImage:
                                    question.userAvatar
                                        .toLowerCase()
                                        .startsWith('http')
                                    ? NetworkImage(question.userAvatar)
                                    : null,
                                child:
                                    question.userAvatar
                                        .toLowerCase()
                                        .startsWith('http')
                                    ? null
                                    : Text(
                                        (question.userName.isNotEmpty
                                                ? question.userName[0]
                                                : question.userAvatar.isNotEmpty
                                                ? question.userAvatar[0]
                                                : '👤')
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  question.userName,
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: const Color(0xFF0D1B3D),
                                      ),
                                ),
                                Text(
                                  DateFormat(
                                    'MMM d, yyyy - HH:mm',
                                  ).format(question.createdAt),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: const Color(0xFF7A89A8),
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Description
                        Text(
                          question.description,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF0D1B3D)),
                        ),
                        const SizedBox(height: 16),

                        // Tags
                        Wrap(
                          spacing: 8,
                          children: question.tags
                              .map(
                                (tag) =>
                                    TagWidget(tag: tag, isClickable: false),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),

                        // Stats and reactions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.chat_bubble_outline,
                                  label: '${question.answerCount} Answers',
                                ),
                                const SizedBox(width: 8),
                                _StatChip(
                                  icon: Icons.visibility_outlined,
                                  label: '${question.views} Views',
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Question reactions
                        Row(
                          children: [
                            _ReactionButton(
                              icon: Icons.thumb_up_outlined,
                              count: question.likeCount,
                              label: 'Like',
                              onPressed: () => _onQuestionReaction(
                                question,
                                ReactionType.like,
                              ),
                              isActive: question.reactions.any(
                                (r) =>
                                    r.userId == _currentUserId &&
                                    r.type == ReactionType.like,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ReactionButton(
                              icon: Icons.favorite_outline,
                              count: question.heartCount,
                              label: 'Heart',
                              onPressed: () => _onQuestionReaction(
                                question,
                                ReactionType.heart,
                              ),
                              isActive: question.reactions.any(
                                (r) =>
                                    r.userId == _currentUserId &&
                                    r.type == ReactionType.heart,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                      ],
                    ),
                  ),
                  // 🔽 ATTACHMENT PREVIEW (with remove)
                  if (_uploadedFileName != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _selectedImage != null
                                  ? Icons.image
                                  : _selectedVideo != null
                                  ? Icons.videocam
                                  : Icons.description,
                              color: Colors.blue[200],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _uploadedFileName!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF0D1B3D),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: Color(0xFF5C6B8C),
                              ),
                              onPressed: _removeAttachment, // ✅ NOW CALLED
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x1A2E6BFF)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E6BFF).withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // 📎 Attachment button
                        InkWell(
                          key: _attachKey,
                          onTap: _showAttachmentSheet,
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.attach_file,
                              size: 22,
                              color: Color(0xFF5C6B8C),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // 📝 Text input
                        Expanded(
                          child: TextField(
                            controller: _answerController,
                            minLines: 1,
                            maxLines: 5,
                            style: const TextStyle(color: Color(0xFF0D1B3D)),
                            decoration: const InputDecoration(
                              hintText: 'Write your answer...',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              hintStyle: TextStyle(color: Color(0xFF7A89A8)),
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ➤ Send button
                        InkWell(
                          onTap: _isSubmittingAnswer ? null : _submitAnswer,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isSubmittingAnswer
                                  ? Colors.grey
                                  : const Color(0xFF2E6BFF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isSubmittingAnswer
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Answers section
                  StreamBuilder<List<Answer>>(
                    stream: _answersStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final answers = snapshot.data ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Answers (${answers.length})',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0D1B3D),
                                  ),
                            ),
                          ),

                          // Answers list
                          if (answers.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: EmptyStateWidget(
                                title: 'No Answers Yet',
                                message:
                                    'Be the first to answer this question!',
                                icon: Icons.rate_review_outlined,
                              ),
                            )
                          else
                            Column(
                              children: answers
                                  .map(
                                    (answer) => AnswerCard(
                                      answer: answer,
                                      currentUserId: _currentUserId,
                                      isQuestionAuthor:
                                          question.userId == _currentUserId,
                                      onMarkHelpful: () =>
                                          _firestoreService.markAnswerAsHelpful(
                                            question.id,
                                            answer.id,
                                          ),
                                      onReaction: (type) =>
                                          _onAnswerReaction(answer, type),
                                    ),
                                  )
                                  .toList(),
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: const Color(0xFF2E6BFF)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF0D1B3D))),
        ],
      ),
      backgroundColor: const Color(0xFFEAF1FF),
      side: BorderSide.none,
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const _ReactionButton({
    required this.icon,
    required this.count,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? Colors.red : const Color(0xFF5C6B8C),
            ),
            const SizedBox(width: 8),
            Text(
              count > 0 ? '$count' : label,
              style: TextStyle(
                color: isActive ? Colors.red : const Color(0xFF5C6B8C),
                fontWeight: isActive ? FontWeight.bold : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
