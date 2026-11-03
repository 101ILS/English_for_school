import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/ai_service.dart';
import '../services/tts_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage> {
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final AIService aiService = AIService();
  final TTSService ttsService = TTSService();
  String? speakingMessageId;
  final AuthService authService = AuthService();
  final UserService userService = UserService();

  String userName = 'Student';
  String userLevel = 'Beginner';
  List<String> userInterests = [];
  bool profileLoaded = false;

  bool isTyping = false;

  final List<Map<String, dynamic>> messages = [
    {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': 'Hi! I’m your AI tutor. Write to me in English, and I will help you improve.',
      'isUser': false,
      'translation': 'Привет! Я твой AI-репетитор. Пиши мне на английском, и я помогу тебе стать лучше.',
      'showTranslation': false,
    }
  ];

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    ttsService.stop();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    loadUserProfile();
    ttsService.init();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || isTyping) return;

    final userMessageId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      messages.add({
        'id': userMessageId,
        'text': text,
        'isUser': true,
        'isCorrect': null,
        'correctedText': '',
        'hint': '',
      });
      controller.clear();
      isTyping = true;
    });

    scrollToBottom();

    try {
      final result = await aiService.sendMessage(
        message: text,
        userName: userName,
        level: userLevel,
        interests: userInterests,
      );

      final userIndex = messages.indexWhere((m) => m['id'] == userMessageId);
      if (userIndex != -1) {
        messages[userIndex]['isCorrect'] = result.isCorrect;
        messages[userIndex]['correctedText'] = result.correctedText;
        messages[userIndex]['hint'] = result.hint;
      }

      messages.add({
        'id': '${DateTime.now().millisecondsSinceEpoch}_ai',
        'text': result.reply,
        'isUser': false,
        'translation': result.translation,
        'showTranslation': false,
      });
    } catch (e) {
      messages.add({
        'id': '${DateTime.now().millisecondsSinceEpoch}_error',
        'text': 'AI is currently unavailable. Please try again.',
        'isUser': false,
        'translation': 'ИИ сейчас недоступен. Попробуйте снова.',
        'showTranslation': false,
      });
    } finally {
      if (mounted) {
        setState(() {
          isTyping = false;
        });
      }
      scrollToBottom();
    }
  }

  Future<void> loadUserProfile() async {
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        profileLoaded = true;
      });
      return;
    }

    final data = await userService.getUserProfile(user.uid);

    if (data != null) {
      setState(() {
        userName = (data['name'] ?? 'Student').toString();
        userLevel = (data['level'] ?? 'Beginner').toString();
        userInterests = List<String>.from(data['interests'] ?? []);
        profileLoaded = true;
      });
    } else {
      setState(() {
        profileLoaded = true;
      });
    }
  }

  Widget buildUserMessage(Map<String, dynamic> message) {
    final bool? isCorrect = message['isCorrect'] as bool?;
    final String correctedText = (message['correctedText'] ?? '').toString();
    final String hint = (message['hint'] ?? '').toString();

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: kPrimary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['text'].toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
              ),
            ),
            if (isCorrect != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withOpacity(0.18)
                      : Colors.red.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isCorrect ? 'Correct' : 'Needs correction',
                  style: TextStyle(
                    color: isCorrect ? Colors.greenAccent : const Color(0xFFFFD6D6),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!isCorrect && correctedText.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Correction:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  correctedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
              if (hint.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  hint,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

Widget buildAIMessage(Map<String, dynamic> message) {
  final bool showTranslation = message['showTranslation'] == true;
  final String translation = (message['translation'] ?? '').toString();
  final String messageId = message['id'].toString();
  final bool isSpeaking = speakingMessageId == messageId;

  return Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message['text'].toString(),
            style: const TextStyle(
              color: kTextDark,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    message['showTranslation'] = !showTranslation;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.translate, size: 16, color: kPrimary),
                      SizedBox(width: 6),
                      Text(
                        'Translate',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  if (isSpeaking) {
                    await ttsService.stop();
                    if (!mounted) return;
                    setState(() {
                      speakingMessageId = null;
                    });
                  } else {
                    setState(() {
                      speakingMessageId = messageId;
                    });
                    await ttsService.speak(message['text'].toString());
                    if (!mounted) return;
                    setState(() {
                      speakingMessageId = null;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSpeaking
                        ? Colors.green.withOpacity(0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                        size: 16,
                        color: isSpeaking ? Colors.green : kTextLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isSpeaking ? 'Stop' : 'Audio',
                        style: TextStyle(
                          color: isSpeaking ? Colors.green : kTextLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (showTranslation && translation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                translation,
                style: const TextStyle(
                  color: kTextLight,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

  Widget buildMessage(Map<String, dynamic> message) {
    return message['isUser'] == true
        ? buildUserMessage(message)
        : buildAIMessage(message);
  }

  @override
  Widget build(BuildContext context) {
  if (!profileLoaded) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('AI Tutor'),
        centerTitle: true,
      ),
      body: Column(
        children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Level: $userLevel',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userInterests.isEmpty
                    ? 'No interests selected yet'
                    : 'Topics: ${userInterests.join(', ')}',
                style: const TextStyle(
                  color: kTextLight,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),
          if (isTyping)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'AI is typing...',
                style: TextStyle(color: kTextLight),
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Write in English...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}