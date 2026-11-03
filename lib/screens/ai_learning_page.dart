import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import 'ai_reinforce_page.dart';

class AILearningPage extends StatefulWidget {
  const AILearningPage({super.key});

  @override
  State<AILearningPage> createState() => _AILearningPageState();
}

class _AILearningPageState extends State<AILearningPage> {
  final aiService = AIService();
  final authService = AuthService();
  final userService = UserService();

  List<Map<String, String>> words = [];
  int index = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadWords();
  }

  Future<void> loadWords() async {
    try {
      final user = authService.currentUser;
      if (user == null) return;

      final profile = await userService.getUserProfile(user.uid);

      final result = await aiService.generateLearningWords(
        level: (profile?['level'] ?? 'Beginner').toString(),
        interests: List<String>.from(profile?['interests'] ?? []),
      );

      setState(() {
        words = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void next() {
    if (index < words.length - 1) {
      setState(() {
        index++;
      });
    } else {
      // 👉 Переход на закрепление
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AIReinforcePage(words: words),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (words.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No words generated')),
      );
    }

    final word = words[index];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Words'),
        centerTitle: true,
      ),
      backgroundColor: kBackground,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // слово
            Text(
              word['word'] ?? '',
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: kTextDark,
              ),
            ),

            const SizedBox(height: 12),

            // перевод
            Text(
              word['translation'] ?? '',
              style: const TextStyle(
                fontSize: 22,
                color: kPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 24),

            // пример
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                word['example'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: kTextDark,
                ),
              ),
            ),

            const Spacer(),

            // прогресс
            Text(
              '${index + 1} / ${words.length}',
              style: const TextStyle(
                color: kTextLight,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            // кнопка
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: next,
                child: Text(
                  index == words.length - 1 ? 'Start Practice' : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}