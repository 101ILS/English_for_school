import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../theme.dart';

class GrammarCheckPage extends StatefulWidget {
  const GrammarCheckPage({super.key});

  @override
  State<GrammarCheckPage> createState() => _GrammarCheckPageState();
}

class _GrammarCheckPageState extends State<GrammarCheckPage> {
  final TextEditingController controller = TextEditingController();
  final AIService aiService = AIService();

  bool isLoading = false;

  bool? isCorrect;
  String correctedText = '';
  String hint = '';

  Future<void> checkGrammar() async {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      isLoading = true;
      isCorrect = null;
      correctedText = '';
      hint = '';
    });

    try {
      final result = await aiService.sendMessage(
        message: text,
        userName: 'Student',
        level: 'Intermediate',
        interests: [],
      );

      setState(() {
        isCorrect = result.isCorrect;
        correctedText = result.correctedText;
        hint = result.hint;
      });
    } catch (e) {
      setState(() {
        hint = 'Error checking sentence';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget resultCard() {
    if (isCorrect == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCorrect! ? Icons.check_circle : Icons.error,
                color: isCorrect! ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isCorrect! ? 'Correct' : 'Needs correction',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCorrect! ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (!isCorrect! && correctedText.isNotEmpty) ...[
            const Text(
              'Correction:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(correctedText),
            const SizedBox(height: 12),
          ],

          if (hint.isNotEmpty) ...[
            const Text(
              'Explanation:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(hint),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Grammar Check'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write your sentence...',
                  border: InputBorder.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            GestureDetector(
              onTap: isLoading ? null : checkGrammar,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Check',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/speaking-sentence');
                },
                icon: const Icon(Icons.mic),
                label: const Text('Speaking sentence practice'),
              ),
            ),

            resultCard(),
          ],
        ),
      ),
    );
  }
}