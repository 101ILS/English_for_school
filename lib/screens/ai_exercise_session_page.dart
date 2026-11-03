import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

class AIExerciseSessionPage extends StatefulWidget {
  final int exerciseNumber;

  const AIExerciseSessionPage({
    super.key,
    required this.exerciseNumber,
  });

  @override
  State<AIExerciseSessionPage> createState() => _AIExerciseSessionPageState();
}

class _AIExerciseSessionPageState extends State<AIExerciseSessionPage> {
  final AIService aiService = AIService();
  final AuthService authService = AuthService();
  final UserService userService = UserService();
  final TextEditingController fillController = TextEditingController();

  bool isLoading = true;
  List<AIExercise> exercises = [];

  int currentIndex = 0;
  String? selectedAnswer;
  bool answered = false;
  int score = 0;
  bool showHint = false;

  int attempts = 0;
  final int maxAttempts = 2;

  List<String> selectedWords = [];
  List<String> availableWords = [];

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  @override
  void dispose() {
    fillController.dispose();
    super.dispose();
  }

  Future<void> loadExercises() async {
    final user = authService.currentUser;

    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    final profile = await userService.getUserProfile(user.uid);
    final learned = await userService.getLearnedWords(user.uid);

    final allWords = learned
    .map((e) => (e['word'] ?? '').toString())
    .where((e) => e.isNotEmpty)
    .toSet()
    .toList();

final startIndex = (widget.exerciseNumber - 1) * 3;
final endIndex = startIndex + 3;

final words = allWords.length > startIndex
    ? allWords.sublist(
        startIndex,
        endIndex > allWords.length ? allWords.length : endIndex,
      )
    : <String>[];

    

    final generated = await aiService.generateExercises(
      userName: (profile?['name'] ?? 'Student').toString(),
      level: (profile?['level'] ?? 'Beginner').toString(),
      interests: List<String>.from(profile?['interests'] ?? []),
      learnedWords: words,
    );

    setState(() {
      exercises = generated;
      isLoading = false;
    });

    prepareQuestionState();
  }

  void prepareQuestionState() {
  if (exercises.isEmpty) return;

  final current = exercises[currentIndex];

  selectedAnswer = null;
  answered = false;
  attempts = 0;
  fillController.clear();
  selectedWords = [];
  showHint = false;

  if (current.type == 'build_sentence' ||
      current.type == 'mixed_challenge') {
    availableWords = current.correctAnswer
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('!', '')
        .replaceAll('?', '')
        .split(' ')
        .where((word) => word.trim().isNotEmpty)
        .toList()
      ..shuffle();
  } else {
    availableWords = [];
  }

  if (mounted) {
    setState(() {});
  }
}

  String normalizeAnswer(String text) {
    String value = text.trim().toLowerCase();

    value = value
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('!', '')
        .replaceAll('?', '')
        .replaceAll(';', '')
        .replaceAll(':', '')
        .replaceAll('"', '')
        .replaceAll("'", '');

    value = value.replaceAll(RegExp(r'\s+'), ' ');

    if (value.startsWith('the ')) {
      value = value.substring(4);
    } else if (value.startsWith('a ')) {
      value = value.substring(2);
    } else if (value.startsWith('an ')) {
      value = value.substring(3);
    }

    return value.trim();
  }

  bool isAnswerCorrect(String userAnswer, String correctAnswer, String type) {
    final user = normalizeAnswer(userAnswer);
    final correct = normalizeAnswer(correctAnswer);

    if (user.isEmpty || correct.isEmpty) return false;
    if (user == correct) return true;

    if (type == 'fill_blank') {
      final correctParts = correct.split(' ');
      return correctParts.contains(user) || correct.contains(user);
    }

    return false;
  }

  void resetCurrentInput(AIExercise current) {
    selectedAnswer = null;
    fillController.clear();
    selectedWords = [];

    if (current.type == 'build_sentence' ||
    current.type == 'mixed_challenge') {
  availableWords = current.correctAnswer
      .replaceAll('.', '')
      .replaceAll(',', '')
      .replaceAll('!', '')
      .replaceAll('?', '')
      .split(' ')
      .where((word) => word.trim().isNotEmpty)
      .toList()
    ..shuffle();
}
  }

  void checkAnswer() {
    if (exercises.isEmpty) return;

    final current = exercises[currentIndex];
    final correct = current.correctAnswer;
    String userAnswer = '';

    if (current.type == 'multiple_choice') {
      if (selectedAnswer == null) return;
      userAnswer = selectedAnswer!;
    } else if (current.type == 'fill_blank') {
      userAnswer = fillController.text.trim();
      if (userAnswer.isEmpty) return;
      selectedAnswer = userAnswer;
    } else if (current.type == 'build_sentence' ||
        current.type == 'mixed_challenge') {
      if (selectedWords.isEmpty) return;
      userAnswer = selectedWords.join(' ').trim();
      selectedAnswer = userAnswer;
    }

    final correctResult = isAnswerCorrect(
      userAnswer,
      correct,
      current.type,
    );

    setState(() {
      if (correctResult) {
        answered = true;
        score++;
      } else {
        attempts++;

        if (attempts >= maxAttempts) {
          answered = true;
        } else {
          resetCurrentInput(current);
        }
      }
    });
  }

  Future<void> nextQuestion() async {
    if (currentIndex < exercises.length - 1) {
      setState(() {
        currentIndex++;
      });
      prepareQuestionState();
    } else {
      await saveProgress();
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Exercises completed'),
          content: Text('Score: $score / ${exercises.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Finish'),
            )
          ],
        ),
      );
    }
  }

  Future<void> saveProgress() async {
    final user = authService.currentUser;
    if (user == null) return;

    await userService.saveExerciseProgress(
      uid: user.uid,
      exerciseId: 'exercise${widget.exerciseNumber}',
      score: score,
      total: exercises.length,
      completed: true,
    );
  }

  Widget buildHintCard(AIExercise ex) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 12),

      GestureDetector(
        onTap: () {
          setState(() {
            showHint = !showHint;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb_outline, size: 18),
              const SizedBox(width: 6),
              Text(
                showHint ? 'Hide hint' : 'Show hint',
                style: const TextStyle(
                  color: kPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),

      if (showHint && ex.hint.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            ex.hint,
            style: const TextStyle(
              color: kPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ],
  );
}

  Widget buildRetryMessage() {
    if (answered || attempts == 0) return const SizedBox();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Try again. Attempts left: ${maxAttempts - attempts}',
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget buildMultipleChoice(AIExercise ex) {
    return Column(
      children: ex.options.map((option) {
        final isCorrect = isAnswerCorrect(
          option,
          ex.correctAnswer,
          ex.type,
        );

        final isWrongSelected =
            answered && selectedAnswer == option && !isCorrect;

        return GestureDetector(
          onTap: answered
              ? null
              : () {
                  setState(() {
                    selectedAnswer = option;
                  });
                },
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: answered
                  ? isCorrect
                      ? Colors.green.withOpacity(0.15)
                      : isWrongSelected
                          ? Colors.red.withOpacity(0.15)
                          : Colors.white
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: answered
                    ? isCorrect
                        ? Colors.green
                        : isWrongSelected
                            ? Colors.red
                            : Colors.grey.shade300
                    : selectedAnswer == option
                        ? kPrimary
                        : Colors.grey.shade300,
              ),
            ),
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kTextDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildFillBlank(AIExercise ex) {
  final showWordBank = attempts > 0 && !answered && ex.wordBank.isNotEmpty;

  return Column(
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: fillController,
          enabled: !answered,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: attempts == 0
                ? 'Type your answer'
                : 'Try again or choose a word below',
            border: InputBorder.none,
          ),
        ),
      ),

      if (showWordBank) ...[
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Choose one:',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ex.wordBank.map((word) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  fillController.text = word;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    ],
  );
}

  Widget buildSentenceBuilder(AIExercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap words to build the answer:',
          style: TextStyle(
            color: kTextLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selectedWords.isEmpty
                ? [
                    const Text(
                      'Your sentence will appear here',
                      style: TextStyle(color: kTextLight),
                    )
                  ]
                : selectedWords.map((word) {
                    return GestureDetector(
                      onTap: answered
                          ? null
                          : () {
                              setState(() {
                                selectedWords.remove(word);
                                availableWords.add(word);
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          word,
                          style: const TextStyle(
                            color: kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableWords.map((word) {
            return GestureDetector(
              onTap: answered
                  ? null
                  : () {
                      setState(() {
                        availableWords.remove(word);
                        selectedWords.add(word);
                      });
                    },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  word,
                  style: const TextStyle(
                    color: kTextDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (exercises.isEmpty) {
      return Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          title: const Text('Exercises'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'Could not generate exercises.',
            style: TextStyle(color: kTextLight),
          ),
        ),
      );
    }

    final ex = exercises[currentIndex];

    final hasAnswer = ex.type == 'multiple_choice'
        ? selectedAnswer != null
        : ex.type == 'fill_blank'
            ? fillController.text.trim().isNotEmpty
            : selectedWords.isNotEmpty;

    final isCorrect = selectedAnswer != null
        ? isAnswerCorrect(selectedAnswer!, ex.correctAnswer, ex.type)
        : false;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text('Exercise ${widget.exerciseNumber}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                'Exercise ${widget.exerciseNumber} • Question ${currentIndex + 1} / ${exercises.length}',
                style: const TextStyle(
                  color: kTextLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex.type.replaceAll('_', ' '),
                    style: const TextStyle(
                      color: kPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    ex.question,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                  buildHintCard(ex),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (ex.type == 'multiple_choice') buildMultipleChoice(ex),
                    if (ex.type == 'fill_blank') buildFillBlank(ex),
                    if (ex.type == 'build_sentence' ||
                        ex.type == 'mixed_challenge')
                      buildSentenceBuilder(ex),
                    buildRetryMessage(),
                    if (answered) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          ex.explanation,
                          style: TextStyle(
                            color: isCorrect
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !hasAnswer
                    ? null
                    : answered
                        ? nextQuestion
                        : checkAnswer,
                child: Text(answered ? 'Next' : 'Check'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}