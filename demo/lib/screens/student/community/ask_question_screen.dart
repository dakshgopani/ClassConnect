import 'package:flutter/material.dart';
import 'package:demo/services/firestore_service.dart';
import 'package:demo/services/moderation_service.dart';
import 'package:demo/services/student_chatbot_service.dart';
import 'package:demo/models/tag.dart';
import 'package:demo/models/question.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_dialog.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';
import 'package:demo/widgets/ui/cc_text_field.dart';

class AskQuestionScreen extends StatefulWidget {
  const AskQuestionScreen({super.key});

  @override
  State<AskQuestionScreen> createState() => _AskQuestionScreenState();
}

class _AskQuestionScreenState extends State<AskQuestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ModerationService _moderationService = ModerationService();
  bool _isSubmitting = false;
  final List<Tag> _selectedTags = [];
  final List<Tag> _customTags = [];

  // Available tags
  final List<Tag> _availableTags = [
    Tag(id: 't1', name: 'Flutter', color: '#42A5F5'),
    Tag(id: 't2', name: 'Dart', color: '#AB47BC'),
    Tag(id: 't3', name: 'UI/UX', color: '#66BB6A'),
    Tag(id: 't4', name: 'Database', color: '#FFA726'),
    Tag(id: 't5', name: 'API', color: '#EC407A'),
    Tag(id: 't6', name: 'State Management', color: '#AB47BC'),
    Tag(id: 't7', name: 'Performance', color: '#FFCA28'),
  ];

  late final String _currentUserId;
  String _userName = 'Student';
  String _userAvatar = '👤';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadUserData();
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

  Future<void> _submitQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one tag')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Moderate the question first
    final moderationError = await _moderationService.moderateQuestion(
      title: _titleController.text,
      description: _descriptionController.text,
    );

    setState(() {
      _isSubmitting = false;
    });

    if (moderationError != null) {
      // Content was rejected
      if (mounted) {
        _showModerationDialog('Question Not Allowed', moderationError);
      }
      return;
    }

    // Content approved, post the question
    try {
      final question = await _firestoreService.addQuestion(
        userId: _currentUserId,
        userName: _userName,
        userAvatar: _userAvatar,
        title: _titleController.text,
        description: _descriptionController.text,
        tags: _selectedTags,
      );

      // Fire and forget so the user is not blocked if AI is slow.
      _postAutomaticAiAnswer(question);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Question posted successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting question: $e')));
      }
    }
  }

  Future<void> _postAutomaticAiAnswer(Question question) async {
    try {
      final aiReply = await StudentChatbotService.sendMessage(
        message:
            'A student posted this community question. Write one direct, useful answer with short steps. '
            'If details are missing, include a brief clarifying suggestion.\n\n'
            'Title: ${question.title}\n'
            'Description: ${question.description}',
        studentName: _userName,
      );

      final content = aiReply.trim();
      if (content.isEmpty) {
        return;
      }

      await _firestoreService.addSystemAnswer(
        questionId: question.id,
        userId: 'classconnect_ai_assistant',
        userName: 'ClassConnect AI',
        userAvatar: '🤖',
        content: content,
      );
    } catch (_) {
      // Non-blocking: question is already posted successfully.
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

  void _addCustomTag() {
    final tagName = _customTagController.text.trim();
    if (tagName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a tag name')));
      return;
    }

    // Check if tag already exists
    final allTags = [..._availableTags, ..._customTags];
    if (allTags.any((t) => t.name.toLowerCase() == tagName.toLowerCase())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tag already exists')));
      return;
    }

    // Generate random color for custom tag
    final colors = [
      '#42A5F5',
      '#AB47BC',
      '#66BB6A',
      '#FFA726',
      '#EC407A',
      '#FFCA28',
      '#26C6DA',
    ];
    final color = colors[_customTags.length % colors.length];

    setState(() {
      final customTag = Tag(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: tagName,
        color: color,
      );
      _customTags.add(customTag);
      _selectedTags.add(customTag);
      _customTagController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Tag "$tagName" added')));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Ask a Question',
          style: TextStyle(color: Color(0xFF0D1B3D)),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        foregroundColor: const Color(0xFF0D1B3D),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ), // Modern rounded back icon
          color: const Color(0xFF0D1B3D),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: CcDecoratedBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CcSectionHeader(
                    title: 'Ask a Question',
                    subtitle: 'Share a clear problem so others can help faster',
                  ),
                  const SizedBox(height: 8),
                  CcTextField(
                    controller: _titleController,
                    label: 'Question Title',
                    icon: Icons.title_rounded,
                    maxLength: 200,
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a question title';
                      }
                      if (value.trim().length < 10) {
                        return 'Title must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Description',
                    style: TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0x1A2E6BFF),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2E6BFF,
                          ).withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLength: 2000,
                      maxLines: 4,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(
                        color: Color(0xFF0D1B3D),
                        fontSize: 14,
                        height: 0.6,
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Describe your problem clearly. Mention what you tried and where you got stuck.',
                        hintStyle: TextStyle(
                          color: Color(0xFF7A89A8),
                          height: 1.4,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 38),
                          child: Icon(
                            Icons.description_rounded,
                            color: Color(0xFF5C6B8C),
                          ),
                        ),
                        prefixIconConstraints: BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        contentPadding: EdgeInsets.fromLTRB(14, 10, 14, 10),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a description';
                        }
                        if (value.trim().length < 20) {
                          return 'Description must be at least 20 characters';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  const CcSectionHeader(
                    title: 'Tags',
                    subtitle: 'Select at least one topic tag',
                  ),
                  const SizedBox(height: 8),

                  CcCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Predefined Tags',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableTags.map((tag) {
                            final isSelected = _selectedTags.any(
                              (t) => t.id == tag.id,
                            );
                            return FilterChip(
                              label: Text(tag.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.removeWhere(
                                      (t) => t.id == tag.id,
                                    );
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  CcTextField(
                    controller: _customTagController,
                    label: 'Add Custom Tag',
                    icon: Icons.add_circle_outline,
                    maxLength: 20,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: 10),
                  CcButton(
                    label: 'Add Tag',
                    variant: CcButtonVariant.secondary,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    onPressed: _addCustomTag,
                  ),
                  const SizedBox(height: 8),

                  if (_customTags.isNotEmpty) ...[
                    Text(
                      'Your Custom Tags:',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF0D1B3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _customTags.map((tag) {
                        final isSelected = _selectedTags.any(
                          (t) => t.id == tag.id,
                        );
                        return FilterChip(
                          label: Text(tag.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.removeWhere(
                                  (t) => t.id == tag.id,
                                );
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 20),

                  if (_selectedTags.isNotEmpty) ...[
                    Text(
                      'Selected Tags',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _selectedTags.map((tag) {
                        return Chip(
                          label: Text(tag.name),
                          onDeleted: () {
                            setState(() {
                              _selectedTags.removeWhere((t) => t.id == tag.id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  CcButton(
                    label: _isSubmitting ? 'Posting...' : 'Post Question',
                    isLoading: _isSubmitting,
                    icon: const Icon(Icons.send_rounded, size: 18),
                    onPressed: _isSubmitting ? null : _submitQuestion,
                  ),
                  const SizedBox(height: 16),
                  CcButton(
                    label: 'Cancel',
                    variant: CcButtonVariant.ghost,
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            Navigator.of(context).pop();
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
