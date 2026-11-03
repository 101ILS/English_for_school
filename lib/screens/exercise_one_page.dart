import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

class ExerciseOnePage extends StatefulWidget {
  const ExerciseOnePage({super.key});

  @override
  State<ExerciseOnePage> createState() => _ExerciseOnePageState();
}

class _ExerciseOnePageState extends State<ExerciseOnePage> {
  final AuthService authService = AuthService();
  final UserService userService = UserService();
  final TextEditingController fillBlankController = TextEditingController();

  bool isLoading = true;
  List<Map<String, dynamic>> learnedWords = [];
  List<Map<String, dynamic>> questions = [];

  int currentQuestionIndex = 0;
  String? selectedAnswer;
  bool answered = false;
  int score = 0;
  bool progressSaved = false;

  List<String> sentenceBuilderSelected = [];
  List<String> sentenceBuilderAvailable = [];

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  @override
  void dispose() {
    fillBlankController.dispose();
    super.dispose();
  }

  Future<void> loadQuestions() async {
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final words = await userService.getLearnedWords(user.uid);

    if (words.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final uniqueWords = <String>{};
    final filteredWords = <Map<String, dynamic>>[];

    for (final word in words) {
      final value = (word['word'] ?? '').toString();
      if (value.isNotEmpty && !uniqueWords.contains(value)) {
        uniqueWords.add(value);
        filteredWords.add(word);
      }
    }

    final limitedWords = filteredWords.take(3).toList();

    setState(() {
      learnedWords = limitedWords;
      questions = buildAllQuestions(limitedWords);
      isLoading = false;
    });

    prepareQuestionState();
  }

  List<Map<String, dynamic>> buildAllQuestions(List<Map<String, dynamic>> words) {
    final result = <Map<String, dynamic>>[];
    result.addAll(buildMultipleChoiceQuestions(words));
    result.addAll(buildFillInBlankQuestions(words));
    result.addAll(buildSentenceBuilderQuestions(words));
    return result;
  }

  List<Map<String, dynamic>> buildMultipleChoiceQuestions(
    List<Map<String, dynamic>> words,
  ) {
    final random = Random();

    const translationPool = [
      'Сцена',
      'Актёр',
      'Текст песни',
      'Мелодия',
      'Эпизод',
      'Персонаж',
      'Счёт',
      'Команда',
      'Эксперимент',
      'Теория',
      'Устройство',
      'Программное обеспечение',
      'Путешествие',
      'Билет',
      'Роман',
      'Автор',
      'Уровень',
      'Миссия',
      'Встреча',
      'Клиент',
      'Картина',
      'Галерея',
      'Древний',
      'Империя',
    ];

    return words.map((wordData) {
      final word = (wordData['word'] ?? '').toString();
      final correct = inferTranslation(word);

      final wrongOptions = translationPool.where((item) => item != correct).toList()
        ..shuffle(random);

      final options = [correct, wrongOptions[0], wrongOptions[1]]..shuffle(random);

      return {
        'type': 'multiple_choice',
        'title': 'Choose the correct answer',
        'question': 'Choose the correct translation for "$word"',
        'correctAnswer': correct,
        'options': options,
        'explanation': 'The correct translation of "$word" is "$correct".',
      };
    }).toList();
  }

  List<Map<String, dynamic>> buildFillInBlankQuestions(
    List<Map<String, dynamic>> words,
  ) {
    return words.map((wordData) {
      final word = (wordData['word'] ?? '').toString();
      final example = inferExample(word);
      final blankSentence = example.replaceFirst(word, '_____');

      return {
        'type': 'fill_blank',
        'title': 'Fill in the blank',
        'question': blankSentence,
        'correctAnswer': word,
        'options': null,
        'explanation': 'The missing word is "$word".',
      };
    }).toList();
  }

  List<Map<String, dynamic>> buildSentenceBuilderQuestions(
    List<Map<String, dynamic>> words,
  ) {
    final random = Random();

    return words.map((wordData) {
      final word = (wordData['word'] ?? '').toString();
      final sentence = inferSimpleSentence(word);
      final parts = sentence.split(' ')..shuffle(random);

      return {
        'type': 'build_sentence',
        'title': 'Build a sentence',
        'question': 'Arrange the words into the correct sentence.',
        'correctAnswer': sentence,
        'options': parts,
        'explanation': 'The correct sentence is: "$sentence"',
      };
    }).toList();
  }

  String inferTranslation(String word) {
    const map = {
      'Scene': 'Сцена',
      'Actor': 'Актёр',
      'Lyrics': 'Текст песни',
      'Melody': 'Мелодия',
      'Episode': 'Эпизод',
      'Character': 'Персонаж',
      'Score': 'Счёт',
      'Team': 'Команда',
      'Experiment': 'Эксперимент',
      'Theory': 'Теория',
      'Device': 'Устройство',
      'Software': 'Программное обеспечение',
      'Journey': 'Путешествие',
      'Ticket': 'Билет',
      'Novel': 'Роман',
      'Author': 'Автор',
      'Level': 'Уровень',
      'Mission': 'Миссия',
      'Meeting': 'Встреча',
      'Client': 'Клиент',
      'Painting': 'Картина',
      'Gallery': 'Галерея',
      'Ancient': 'Древний',
      'Empire': 'Империя',
    };

    return map[word] ?? 'Перевод';
  }

  String inferExample(String word) {
    const map = {
      'Scene': 'My favorite Scene was amazing.',
      'Actor': 'The Actor played very well.',
      'Lyrics': 'I like the Lyrics of this song.',
      'Melody': 'The Melody is beautiful.',
      'Episode': 'I watched one Episode yesterday.',
      'Character': 'This Character is brave.',
      'Score': 'The Score was two to one.',
      'Team': 'Our Team worked hard.',
      'Experiment': 'We did an Experiment in class.',
      'Theory': 'This Theory is interesting.',
      'Device': 'This Device is useful.',
      'Software': 'I installed new Software.',
      'Journey': 'The Journey was long.',
      'Ticket': 'I bought a Ticket online.',
      'Novel': 'She is reading a Novel.',
      'Author': 'The Author is famous.',
      'Level': 'I finished the Level.',
      'Mission': 'The Mission was difficult.',
      'Meeting': 'We had a Meeting today.',
      'Client': 'The Client liked the idea.',
      'Painting': 'This Painting is beautiful.',
      'Gallery': 'We visited a Gallery.',
      'Ancient': 'They studied Ancient history.',
      'Empire': 'The Empire was powerful.',
    };

    return map[word] ?? 'I know this $word.';
  }

  String inferSimpleSentence(String word) {
    const map = {
      'Scene': 'I liked the scene.',
      'Actor': 'The actor is famous.',
      'Lyrics': 'The lyrics are nice.',
      'Melody': 'The melody sounds beautiful.',
      'Episode': 'I watched the episode.',
      'Character': 'The character is funny.',
      'Score': 'The score was close.',
      'Team': 'The team won yesterday.',
      'Experiment': 'The experiment was successful.',
      'Theory': 'The theory is interesting.',
      'Device': 'This device works well.',
      'Software': 'The software is new.',
      'Journey': 'The journey was amazing.',
      'Ticket': 'I bought the ticket.',
      'Novel': 'The novel was exciting.',
      'Author': 'The author writes well.',
      'Level': 'The level was hard.',
      'Mission': 'The mission was dangerous.',
      'Meeting': 'The meeting starts now.',
      'Client': 'The client was happy.',
      'Painting': 'The painting looks beautiful.',
      'Gallery': 'The gallery opens today.',
      'Ancient': 'Ancient history is fascinating.',
      'Empire': 'The empire became strong.',
    };

    return map[word] ?? 'I know this word.';
  }

  void prepareQuestionState() {
    if (questions.isEmpty) return;

    final currentQuestion = questions[currentQuestionIndex];
    final type = currentQuestion['type'] as String;

    selectedAnswer = null;
    answered = false;
    fillBlankController.clear();
    sentenceBuilderSelected = [];

    if (type == 'build_sentence') {
      sentenceBuilderAvailable = List<String>.from(currentQuestion['options'] as List);
    } else {
      sentenceBuilderAvailable = [];
    }

    if (mounted) {
      setState(() {});
    }
  }

  void checkAnswer() {
    final currentQuestion = questions[currentQuestionIndex];
    final type = currentQuestion['type'] as String;
    final correctAnswer = currentQuestion['correctAnswer'] as String;

    String userAnswer = '';

    if (type == 'multiple_choice') {
      if (selectedAnswer == null) return;
      userAnswer = selectedAnswer!;
    } else if (type == 'fill_blank') {
      userAnswer = fillBlankController.text.trim();
      if (userAnswer.isEmpty) return;
      selectedAnswer = userAnswer;
    } else if (type == 'build_sentence') {
      if (sentenceBuilderSelected.isEmpty) return;
      userAnswer = sentenceBuilderSelected.join(' ').trim();
      selectedAnswer = userAnswer;
    }

    setState(() {
      answered = true;
      if (userAnswer.toLowerCase() == correctAnswer.toLowerCase()) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      prepareQuestionState();
    } else {
      showResultDialog();
    }
  }

  Future<void> showResultDialog() async {
  final user = authService.currentUser;

  if (user != null) {
    await userService.saveExerciseProgress(
      uid: user.uid,
      exerciseId: 'exercise1',
      score: score,
      total: questions.length,
      completed: true,
    );
  }

  if (!mounted) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Exercise completed'),
        content: Text('Your score: $score / ${questions.length}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Finish'),
          ),
        ],
      );
    },
  );
}

  Color getOptionColor(String option, String correctAnswer) {
    if (!answered) {
      return Colors.white;
    }

    if (option.toLowerCase() == correctAnswer.toLowerCase()) {
      return Colors.green.withOpacity(0.15);
    }

    if (option == selectedAnswer && option.toLowerCase() != correctAnswer.toLowerCase()) {
      return Colors.red.withOpacity(0.15);
    }

    return Colors.white;
  }

  Border getOptionBorder(String option, String correctAnswer) {
    if (!answered) {
      return Border.all(
        color: selectedAnswer == option ? kPrimary : Colors.grey.shade300,
        width: 1.5,
      );
    }

    if (option.toLowerCase() == correctAnswer.toLowerCase()) {
      return Border.all(color: Colors.green, width: 1.5);
    }

    if (option == selectedAnswer && option.toLowerCase() != correctAnswer.toLowerCase()) {
      return Border.all(color: Colors.red, width: 1.5);
    }

    return Border.all(color: Colors.grey.shade300, width: 1.5);
  }

  Widget buildAnswerOptions(
    List<String> options,
    String correctAnswer,
  ) {
    return Column(
      children: options.map((option) {
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
              color: getOptionColor(option, correctAnswer),
              borderRadius: BorderRadius.circular(18),
              border: getOptionBorder(option, correctAnswer),
            ),
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 16,
                color: kTextDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildFillBlankInput() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: TextField(
      controller: fillBlankController,
      enabled: !answered,
      onChanged: (_) {
        setState(() {});
      },
      decoration: const InputDecoration(
        hintText: 'Type the missing word',
        border: InputBorder.none,
      ),
    ),
  );
}

  Widget buildSentenceBuilder(String correctAnswer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap words to build the sentence:',
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
            border: Border.all(
              color: answered
                  ? (selectedAnswer?.toLowerCase() == correctAnswer.toLowerCase()
                      ? Colors.green
                      : Colors.red)
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sentenceBuilderSelected.isEmpty
                ? [
                    const Text(
                      'Your sentence will appear here',
                      style: TextStyle(color: kTextLight),
                    )
                  ]
                : sentenceBuilderSelected.map((word) {
                    return GestureDetector(
                      onTap: answered
                          ? null
                          : () {
                              setState(() {
                                sentenceBuilderSelected.remove(word);
                                sentenceBuilderAvailable.add(word);
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
          children: sentenceBuilderAvailable.map((word) {
            return GestureDetector(
              onTap: answered
                  ? null
                  : () {
                      setState(() {
                        sentenceBuilderAvailable.remove(word);
                        sentenceBuilderSelected.add(word);
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

    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: kBackground,
        appBar: AppBar(
          title: const Text('Exercise 1'),
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            'No learned words found yet.',
            style: TextStyle(color: kTextLight),
          ),
        ),
      );
    }

    final currentQuestion = questions[currentQuestionIndex];
    final type = currentQuestion['type'] as String;
    final title = currentQuestion['title'] as String;
    final correctAnswer = currentQuestion['correctAnswer'] as String;
    final explanation = currentQuestion['explanation'] as String;
    final options = currentQuestion['options'] == null
        ? <String>[]
        : List<String>.from(currentQuestion['options']);

    final bool hasAnswer = type == 'multiple_choice'
        ? selectedAnswer != null
        : type == 'fill_blank'
            ? fillBlankController.text.trim().isNotEmpty
            : sentenceBuilderSelected.isNotEmpty;

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Exercise 1'),
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
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Question ${currentQuestionIndex + 1} of ${questions.length}',
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
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    currentQuestion['question'] as String,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: kTextDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (type == 'multiple_choice')
                      buildAnswerOptions(options, correctAnswer),

                    if (type == 'fill_blank')
                      buildFillBlankInput(),

                    if (type == 'build_sentence')
                      buildSentenceBuilder(correctAnswer),

                    if (answered) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (selectedAnswer?.toLowerCase() ==
                                  correctAnswer.toLowerCase())
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          explanation,
                          style: TextStyle(
                            color: (selectedAnswer?.toLowerCase() ==
                                    correctAnswer.toLowerCase())
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