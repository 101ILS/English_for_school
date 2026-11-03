import 'package:flutter/material.dart';
import '../theme.dart';

class AIReinforcePage extends StatefulWidget {
  final List<Map<String, String>> words;

  const AIReinforcePage({super.key, required this.words});

  @override
  State<AIReinforcePage> createState() => _AIReinforcePageState();
}

class _AIReinforcePageState extends State<AIReinforcePage> {
  Map<String, String> userAnswers = {};
  late List<String> shuffledTranslations;

  @override
  void initState() {
    super.initState();

    shuffledTranslations = widget.words
        .map((e) => e['translation']!)
        .toList()
      ..shuffle();
  }

  bool get isComplete =>
      userAnswers.length == widget.words.length;

  bool get isCorrect {
    for (var word in widget.words) {
      if (userAnswers[word['word']] != word['translation']) {
        return false;
      }
    }
    return true;
  }

  void select(String word, String translation) {
    setState(() {
      userAnswers[word] = translation;
    });
  }

  void next() {
    Navigator.pushNamed(
      context,
      '/exercise-session',
      arguments: widget.words,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Match Words')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Match words with translations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            ...widget.words.map((wordData) {
              final word = wordData['word']!;
              final selected = userAnswers[word];

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      children: shuffledTranslations.map((t) {
                        final isSelected = selected == t;

                        return GestureDetector(
                          onTap: () => select(word, t),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? kPrimary.withOpacity(0.2)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(t),
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              );
            }),

            const Spacer(),

            ElevatedButton(
              onPressed: isComplete ? next : null,
              child: const Text('Continue'),
            )
          ],
        ),
      ),
    );
  }
}