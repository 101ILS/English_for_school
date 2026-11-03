import 'dart:math';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../theme.dart';

class SpeakingSentencePage extends StatefulWidget {
  const SpeakingSentencePage({super.key});

  @override
  State<SpeakingSentencePage> createState() =>
      _SpeakingSentencePageState();
}

class _SpeakingSentencePageState
    extends State<SpeakingSentencePage> {

  final stt.SpeechToText speech = stt.SpeechToText();
  final Random random = Random();

  bool isListening = false;

  String spokenText = '';
  String resultText = '';

  int currentIndex = 0;

  final List<List<String>> sentencePool = [
    ['I','need','some','food'],
    ['The','book','is','interesting'],
    ['She','likes','to','read'],
    ['We','play','football','today'],
    ['The','robot','can','help'],
    ['My','friend','likes','anime'],
    ['I','watch','movies','everyday'],
    ['The','teacher','is','kind'],
    ['He','plays','video','games'],
    ['Technology','helps','people'],

    ['The','dog','is','happy'],
    ['I','love','music'],
    ['She','watches','anime'],
    ['We','study','English'],
    ['The','cat','likes','milk'],
    ['My','robot','is','smart'],
    ['History','helps','students'],
    ['The','movie','was','good'],
    ['I','play','basketball'],
    ['The','lesson','is','easy'],

    ['My','phone','is','new'],
    ['The','teacher','likes','books'],
    ['We','need','more','time'],
    ['I','have','a','friend'],
    ['The','game','is','fun'],
  ];

  late List<List<String>> tasks;

  List<String> get currentWords =>
      tasks[currentIndex];

  String get correctSentence =>
      currentWords.join(' ');

  @override
  void initState() {
    super.initState();

    generateTasks();
  }

  void generateTasks() {
    final shuffled =
        List<List<String>>
            .from(sentencePool);

    shuffled.shuffle(random);

    tasks =
        shuffled
            .take(10)
            .toList();
  }

  Future<void> startListening() async {

    final available =
        await speech.initialize();

    if (!available) return;

    setState(() {
      isListening = true;
      spokenText = '';
      resultText = '';
    });

    speech.listen(
      onResult: (result) {

        setState(() {
          spokenText =
              result.recognizedWords;
        });

      },
    );
  }

  Future<void> stopListening() async {

    await speech.stop();

    setState(() {
      isListening = false;
    });

    checkAnswer();
  }

  String normalize(String text) {

    return text
        .toLowerCase()
        .replaceAll('.', '')
        .replaceAll(',', '')
        .replaceAll('!', '')
        .replaceAll('?', '')
        .trim()
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        );
  }

  void checkAnswer() {

    final spoken =
        normalize(spokenText);

    final correct =
        normalize(correctSentence);

    final spokenWords =
        spoken.split(' ');

    final expected =
        currentWords
            .map(
              (e)=>normalize(e),
            )
            .toList();

    final missing =
        expected
            .where(
              (w)=>
                  !spokenWords
                      .contains(w),
            )
            .toList();

    if (spoken == correct) {

      resultText =
          'Correct!';

    } else {

      resultText =
'''
Needs correction

Correct:
$correctSentence

Missing:
${missing.join(", ")}
''';

    }

    setState(() {});
  }

  void nextTask() {

    if (currentIndex == 9) {

      showDialog(
        context: context,

        builder: (_) {

          return AlertDialog(

            title:
                const Text(
                    'Finished'),

            content:
                const Text(
'''
You completed all 10 tasks
'''),

            actions: [

              TextButton(

                onPressed: () {

                  Navigator.pop(
                      context);

                  setState(() {

                    generateTasks();

                    currentIndex = 0;

                    spokenText = '';

                    resultText = '';

                  });

                },

                child:
                    const Text(
                        'Restart'),
              )

            ],

          );

        },

      );

      return;

    }

    setState(() {

      currentIndex++;

      spokenText='';

      resultText='';

    });

  }

  Widget chip(String text){

    return Container(

      padding:
          const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),

      decoration:
          BoxDecoration(

        color:
            kPrimary
                .withOpacity(
                    0.1),

        borderRadius:
            BorderRadius.circular(
                14),

      ),

      child: Text(

        text,

        style:
            const TextStyle(

          fontWeight:
              FontWeight.w700,

          color:
              kPrimary,

        ),

      ),

    );

  }

  @override
  Widget build(
      BuildContext context) {

    final correct =
        resultText.startsWith(
            'Correct');

    return Scaffold(

      backgroundColor:
          kBackground,

      appBar: AppBar(

        title: Text(
'''
Speaking ${currentIndex+1}/10
''',
        ),

      ),

      body: Padding(

        padding:
            const EdgeInsets.all(
                20),

        child: Column(

          children: [

            const Text(

              'Use ALL words',

              style: TextStyle(

                fontSize: 24,

                fontWeight:
                    FontWeight.w800,

              ),

            ),

            const SizedBox(
                height: 20),

            Wrap(

              spacing: 8,

              runSpacing: 8,

              children:
                  currentWords
                      .map(chip)
                      .toList(),

            ),

            const SizedBox(
                height: 30),

            Container(

              width:
                  double.infinity,

              padding:
                  const EdgeInsets.all(
                      18),

              decoration:
                  BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(
                        18),

              ),

              child: Text(

                spokenText.isEmpty

                    ? 'Speak now...'

                    : spokenText,

              ),

            ),

            const SizedBox(
                height: 20),

            ElevatedButton.icon(

              onPressed:

                  isListening

                      ? stopListening

                      : startListening,

              icon: Icon(

                isListening

                    ? Icons.stop

                    : Icons.mic,

              ),

              label: Text(

                isListening

                    ? 'Stop'

                    : 'Start',

              ),

            ),

            const SizedBox(
                height: 20),

            if(resultText.isNotEmpty)

              Container(

                width:
                    double.infinity,

                padding:
                    const EdgeInsets.all(
                        16),

                decoration:
                    BoxDecoration(

                  color: correct

                      ? Colors.green
                          .withOpacity(
                              0.1)

                      : Colors.red
                          .withOpacity(
                              0.1),

                  borderRadius:
                      BorderRadius.circular(
                          18),

                ),

                child: Text(
                    resultText),

              ),

            const Spacer(),

            SizedBox(

              width:
                  double.infinity,

              child:
                  ElevatedButton(

                onPressed:
                    nextTask,

                child:
                    const Text(
'''
Next sentence
''',
                ),

              ),

            )

          ],

        ),

      ),

    );

  }

}