import 'package:demo/services/firestore_service.dart';
import 'package:demo/services/student_chatbot_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatMessageItem {
  final String role;
  final String content;

  const ChatMessageItem({required this.role, required this.content});
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();

  final List<ChatMessageItem> _messages = [
    const ChatMessageItem(
      role: 'assistant',
      content:
          'Hi, I am your ClassConnect study assistant. Ask me about classes, homework, concepts, or how to use the app.',
    ),
  ];

  bool _isSending = false;
  late final String _currentUserId;
  String _studentName = 'Student';
  String _className = 'ClassConnect';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _loadUserData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userData = await _firestoreService.getUserData(_currentUserId);
    if (userData == null || !mounted) {
      return;
    }

    setState(() {
      _studentName = (userData['name'] as String?)?.trim().isNotEmpty == true
          ? userData['name'] as String
          : 'Student';
      _className =
          (userData['studentClass'] as String?)?.trim().isNotEmpty == true
          ? userData['studentClass'] as String
          : 'ClassConnect';
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage([String? presetMessage]) async {
    final message = (presetMessage ?? _messageController.text).trim();
    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _messages.add(ChatMessageItem(role: 'user', content: message));
      _isSending = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final history = _messages
          .map((item) => {'role': item.role, 'content': item.content})
          .toList();

      final reply = await StudentChatbotService.sendMessage(
        message: message,
        history: history,
        studentName: _studentName,
        className: _className,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(
          ChatMessageItem(
            role: 'assistant',
            content: reply.isEmpty
                ? 'I could not generate a response right now. Please try again.'
                : reply,
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            const ChatMessageItem(
              role: 'assistant',
              content:
                  'I could not reach Grok right now. Please try again in a moment.',
            ),
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quickPrompts = <String>[
      'Explain this topic simply',
      'Help me with homework',
      'Study tips for exams',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1C3F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1C3F),
        foregroundColor: Colors.white,
        title: const Text('Study Assistant'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12224A), Color(0xFF0B132B)],
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Ask anything about your classes, concepts, or study plan. The assistant will keep responses short and useful.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
            ),
            if (_messages.length <= 1)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: quickPrompts
                        .map(
                          (prompt) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              backgroundColor: Colors.white.withOpacity(0.08),
                              side: const BorderSide(color: Colors.white24),
                              label: Text(
                                prompt,
                                style: const TextStyle(color: Colors.white),
                              ),
                              onPressed: () => _sendMessage(prompt),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return const _TypingIndicator();
                  }

                  final message = _messages[index];
                  final isUser = message.role == 'user';

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: isUser
                            ? const Color(0xFF00D9FF).withOpacity(0.18)
                            : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(isUser ? 18 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 18),
                        ),
                        border: Border.all(
                          color: isUser
                              ? const Color(0xFF00D9FF).withOpacity(0.35)
                              : Colors.white12,
                        ),
                      ),
                      child: Text(
                        message.content,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF091224).withOpacity(0.95),
                  border: const Border(top: BorderSide(color: Colors.white12)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      heroTag: 'chatSendFab',
                      onPressed: _isSending ? null : _sendMessage,
                      backgroundColor: const Color(0xFF00D9FF),
                      mini: true,
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white12),
        ),
        child: const SizedBox(
          width: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(radius: 3.5, backgroundColor: Colors.white70),
              CircleAvatar(radius: 3.5, backgroundColor: Colors.white70),
              CircleAvatar(radius: 3.5, backgroundColor: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }
}