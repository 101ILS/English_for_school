import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

class ExerciseTwoPage extends StatefulWidget {
  const ExerciseTwoPage({super.key});

  @override
  State<ExerciseTwoPage> createState() => _ExerciseTwoPageState();
}

class _ExerciseTwoPageState extends State<ExerciseTwoPage> {
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
    result.addAll(buildMeaningQuestions(words));
    result.addAll(buildAdvancedFillBlankQuestions(words));
    result.addAll(buildAdvancedSentenceBuilderQuestions(words));
    return result;
  }

  List<Map<String, dynamic>> buildMeaningQuestions(
    List<Map<String, dynamic>> words,
  ) {
    final random = Random();

    const distractors = [
      'A kind of music',
      'A place to study',
      'A person in a story',
      'A part of a movie',
      'A written song text',
      'A long trip',
      'A software program',
      'A picture made by an artist',
      'A group of players',
      'A scientific idea',
    ];

    return words.map((wordData) {
      final word = (wordData['word'] ?? '').toString();
      final correct = inferMeaning(word);

      final wrongOptions = distractors.where((item) => item != correct).toList()
        ..shuffle(random);

      final options = [correct, wrongOptions[0], wrongOptions[1]]..shuffle(random);

      return {
        'type': 'multiple_choice',
        'title': 'Choose the best meaning',
        'question': 'What does "$word" mean in English?',
        'correctAnswer': correct,
        'options': options,
        'explanation': 'The best meaning of "$word" is "$correct".',
      };
    }).toList();
  }

  List<Map<String, dynamic>> buildAdvancedFillBlankQuestions(
    List<Map<String, dynamic>> words,
  ) {
    return words.map((wordData) {
      final word = (wordData['word'] ?? '').toString();
      final sentence = inferAdvancedExample(word);
      final blankSentence = sentence.replaceFirst(word, '_____');

      return {
        'type': 'fill_blank',
        'title': 'Fill in the blank',
        'question': blankSentence,
        'correctAnswer': word,
        'options': null,
        'explanation': 'The correct word is "$word".',
      };
    }).toList();
  }

  List<Map<String, dynamic>> buildAdvancedSentenceBuilderQuestions(
    List<Map<String, dynamic>> words,
  ) {
    final random = Random();

    return words.map((wordData) {
      final word = (wordData['word'] ?? '').toString();
      final sentence = inferAdvancedSentence(word);
      final parts = sentence.split(' ')..shuffle(random);

      return {
        'type': 'build_sentence',
        'title': 'Build the sentence',
        'question': 'Arrange the words into a correct sentence.',
        'correctAnswer': sentence,
        'options': parts,
        'explanation': 'The correct sentence is: "$sentence"',
      };
    }).toList();
  }

  String inferMeaning(String word) {
    const map = {
      'Scene': 'A part of a movie',
      'Actor': 'A person in a story',
      'Lyrics': 'A written song text',
      'Melody': 'A kind of music',
      'Episode': 'A part of a movie',
      'Character': 'A person in a story',
      'Score': 'A number in a game',
      'Team': 'A group of players',
      'Experiment': 'A scientific test',
      'Theory': 'A scientific idea',
      'Device': 'A useful machine',
      'Software': 'A software program',
      'Journey': 'A long trip',
      'Ticket': 'A paper for travel',
      'Novel': 'A long story book',
      'Author': 'A person who writes books',
      'Level': 'A stage in a game',
      'Mission': 'A special task',
      'Meeting': 'A planned discussion',
      'Client': 'A customer',
      'Painting': 'A picture made by an artist',
      'Gallery': 'A place with art',
      'Ancient': 'Very old',
      'Empire': 'A large powerful state',
    };

    return map[word] ?? 'A useful word';
  }

  String inferAdvancedExample(String word) {
    const map = {
      'Scene': 'The final Scene in the film was emotional.',
      'Actor': 'The Actor won an award for his performance.',
      'Lyrics': 'The Lyrics of the song are easy to remember.',
      'Melody': 'The Melody stayed in my head all day.',
      'Episode': 'This Episode was better than the last one.',
      'Character': 'My favorite Character changed a lot in the story.',
      'Score': 'The Score remained the same until the end.',
      'Team': 'Their Team worked together very well.',
      'Experiment': 'The Experiment gave surprising results.',
      'Theory': 'Her Theory was supported by the data.',
      'Device': 'This Device helps people work faster.',
      'Software': 'The Software needs an update.',
      'Journey': 'Our Journey across the country took two days.',
      'Ticket': 'I forgot to print my Ticket before the trip.',
      'Novel': 'The Novel became popular around the world.',
      'Author': 'The Author spoke about his new book.',
      'Level': 'This Level is harder than the first one.',
      'Mission': 'The Mission was completed successfully.',
      'Meeting': 'The Meeting started later than expected.',
      'Client': 'The Client asked for a new design.',
      'Painting': 'That Painting looks even better in real life.',
      'Gallery': 'The Gallery closes at six o’clock.',
      'Ancient': 'They studied Ancient traditions in class.',
      'Empire': 'The Empire expanded quickly during that period.',
    };

    return map[word] ?? 'I use this $word often.';
  }

  String inferAdvancedSentence(String word) {
    const map = {
      'Scene': 'The scene made everyone laugh.',
      'Actor': 'The actor played the role perfectly.',
      'Lyrics': 'The lyrics are easy to understand.',
      'Melody': 'The melody sounds calm and soft.',
      'Episode': 'The episode ended with a surprise.',
      'Character': 'The character became more confident.',
      'Score': 'The score changed in the final minute.',
      'Team': 'The team prepared for the match.',
      'Experiment': 'The experiment showed clear results.',
      'Theory': 'The theory explains the process well.',
      'Device': 'The device stopped working suddenly.',
      'Software': 'The software helps people save time.',
      'Journey': 'The journey taught us many lessons.',
      'Ticket': 'The ticket was in my bag.',
      'Novel': 'The novel tells a powerful story.',
      'Author': 'The author described the world beautifully.',
      'Level': 'The level became harder after midnight.',
      'Mission': 'The mission required careful planning.',
      'Meeting': 'The meeting lasted for two hours.',
      'Client': 'The client approved the final version.',
      'Painting': 'The painting attracted many visitors.',
      'Gallery': 'The gallery displayed modern art.',
      'Ancient': 'Ancient cities can teach us a lot.',
      'Empire': 'The empire controlled many regions.',
    };

    return map[word] ?? 'This word is important.';
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

  Future<void> nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
      prepareQuestionState();
    } else {
      await showResultDialog();
    }
  }

  Future<void> showResultDialog() async {
    final user = authService.currentUser;

    if (user != null) {
      await userService.saveExerciseProgress(
        uid: user.uid,
        exerciseId: 'exercise2',
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
          title: const Text('Exercise 2 completed'),
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

    if (option == selectedAnswer &&
        option.toLowerCase() != correctAnswer.toLowerCase()) {
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

    if (option == selectedAnswer &&
        option.toLowerCase() != correctAnswer.toLowerCase()) {
      return Border.all(color: Colors.red, width: 1.5);
    }

    return Border.all(color: Colors.grey.shade300, width: 1.5);
  }

  Widget buildAnswerOptions(List<String> options, String correctAnswer) {
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
          title: const Text('Exercise 2'),
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
        title: const Text('Exercise 2'),
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