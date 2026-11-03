import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme.dart';
import '../widgets/flip_card.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage>
    with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();
  final UserService userService = UserService();
  final AIService aiService = AIService();

  late TabController tabController;

  bool isLoading = true;
  bool isGenerating = false;

  List<String> userInterests = [];
  String userLevel = 'Beginner';

  List<Map<String, String>> vocabulary = [];
  List<Map<String, dynamic>> learnedWords = [];

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    loadVocabulary();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  Future<void> loadVocabulary() async {
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final profile = await userService.getUserProfile(user.uid);
    final learned = await userService.getLearnedWords(user.uid);

    final interests = List<String>.from(profile?['interests'] ?? []);
    final level = (profile?['level'] ?? 'Beginner').toString();

    final excludeWords = learned
    .map((e) => (e['word'] ?? '').toString())
    .where((e) => e.isNotEmpty)
    .toList();

final generatedWords = await aiService.generateVocabularyWords(
  level: level,
  interests: interests,
  excludeWords: excludeWords,
);


    if (!mounted) return;

    setState(() {
      userInterests = interests;
      userLevel = level;
      vocabulary = generatedWords;
      learnedWords = learned;
      currentIndex = 0;
      isLoading = false;
    });
  }

  Future<void> refreshVocabulary() async {
    setState(() {
      isGenerating = true;
    });

    final excludeWords = learnedWords
    .map((e) => (e['word'] ?? '').toString())
    .where((e) => e.isNotEmpty)
    .toList();

final generatedWords = await aiService.generateVocabularyWords(
  level: userLevel,
  interests: userInterests,
  excludeWords: excludeWords,
);

    if (!mounted) return;

    setState(() {
      vocabulary = generatedWords;
      currentIndex = 0;
      isGenerating = false;
    });
  }

  Future<void> reloadLearnedWords() async {
    final user = authService.currentUser;
    if (user == null) return;

    final learned = await userService.getLearnedWords(user.uid);

    if (!mounted) return;

    setState(() {
      learnedWords = learned;
    });
  }

  void nextCard() {
    if (currentIndex < vocabulary.length - 1) {
      setState(() {
        currentIndex++;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You finished all words 🎉'),
        ),
      );
    }
  }

  Future<void> markCurrentWordAsLearned() async {
    final user = authService.currentUser;
    if (user == null || vocabulary.isEmpty) return;

    final currentWord = vocabulary[currentIndex];

    await userService.addLearnedWord(
      uid: user.uid,
      word: currentWord['word'] ?? '',
      translation: currentWord['translation'] ?? '',
      example: currentWord['example'] ?? '',
      exampleTranslation: currentWord['exampleTranslation'] ?? '',
      topic: userInterests.isNotEmpty ? userInterests.first : 'General',
    );

    await reloadLearnedWords();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved as learned'),
      ),
    );

    nextCard();
  }

  Widget topicsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Your AI Vocabulary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kTextDark,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  userLevel,
                  style: const TextStyle(
                    color: kPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...userInterests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget learnTab() {
    if (isGenerating) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (vocabulary.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'No vocabulary generated.',
              style: TextStyle(color: kTextLight),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: refreshVocabulary,
              child: const Text('Generate words'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        topicsCard(),
        const SizedBox(height: 16),
        Expanded(
          child: FlipCard(
         key: ValueKey(vocabulary[currentIndex]['word']),
         word: vocabulary[currentIndex]['word'] ?? '',
         translation: vocabulary[currentIndex]['translation'] ?? '',
         example: vocabulary[currentIndex]['example'] ?? '',
         exampleTranslation: vocabulary[currentIndex]['exampleTranslation'] ?? '',
         onLearned: markCurrentWordAsLearned,
         ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${currentIndex + 1} / ${vocabulary.length}',
              style: const TextStyle(color: kTextLight),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: refreshVocabulary,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Text(
                      'New words',
                      style: TextStyle(
                        color: kTextDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: nextCard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget learnedTab() {
    if (learnedWords.isEmpty) {
      return const Center(
        child: Text(
          'No learned words yet.',
          style: TextStyle(color: kTextLight),
        ),
      );
    }

    return ListView.builder(
      itemCount: learnedWords.length,
      itemBuilder: (context, index) {
        final item = learnedWords[index];

        final word = (item['word'] ?? '').toString();
        final translation = (item['translation'] ?? '').toString();
        final example = (item['example'] ?? '').toString();
        final exampleTranslation =
            (item['exampleTranslation'] ?? '').toString();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
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
                word,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                translation,
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (example.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  example,
                  style: const TextStyle(
                    color: kTextDark,
                    height: 1.4,
                  ),
                ),
              ],
              if (exampleTranslation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  exampleTranslation,
                  style: const TextStyle(
                    color: kTextLight,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Vocabulary'),
        centerTitle: true,
        bottom: TabBar(
          controller: tabController,
          labelColor: kPrimary,
          unselectedLabelColor: kTextLight,
          indicatorColor: kPrimary,
          tabs: const [
            Tab(text: 'Learn'),
            Tab(text: 'Learned'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TabBarView(
          controller: tabController,
          children: [
            learnTab(),
            learnedTab(),
          ],
        ),
      ),
    );
  }
}