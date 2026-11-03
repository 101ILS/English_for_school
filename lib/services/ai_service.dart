import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AIChatResult {
  final bool isCorrect;
  final String correctedText;
  final String hint;
  final String reply;
  final String translation;

  AIChatResult({
    required this.isCorrect,
    required this.correctedText,
    required this.hint,
    required this.reply,
    required this.translation,
  });

  factory AIChatResult.fromJson(Map<String, dynamic> json) {
    final feedback =
        (json['user_message_feedback'] ?? {}) as Map<String, dynamic>;

    return AIChatResult(
      isCorrect: feedback['is_correct'] == true,
      correctedText: (feedback['corrected_text'] ?? '').toString(),
      hint: (feedback['hint'] ?? '').toString(),
      reply: (json['reply'] ?? 'Sorry, I could not generate a reply.').toString(),
      translation: (json['translation'] ?? '').toString(),
    );
  }
}

class AIExercise {
  final String type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String hint;
  final List<String> wordBank;
  final String translation;

  AIExercise({
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.hint,
    required this.wordBank,
    required this.translation,
  });

  factory AIExercise.fromJson(Map<String, dynamic> json) {
    return AIExercise(
      type: (json['type'] ?? '').toString(),
      question: (json['question'] ?? '').toString(),
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: (json['correctAnswer'] ?? '').toString(),
      explanation: (json['explanation'] ?? '').toString(),
      hint: (json['hint'] ?? '').toString(),
      wordBank: List<String>.from(json['wordBank'] ?? []),
      translation: (json['translation'] ?? '').toString(),
    );
  }
}

class AIService {
  static String get apiKey => dotenv.env['OPENAI_API_KEY'] ?? '';

  bool get _hasApiKey => apiKey.trim().startsWith('sk-');

  Future<AIChatResult> sendMessage({
    required String message,
    required String userName,
    required String level,
    required List<String> interests,
  }) async {
    if (!_hasApiKey) {
      return AIChatResult(
        isCorrect: true,
        correctedText: '',
        hint: 'Demo mode: API key is not added.',
        reply: 'This is demo mode. Add your API key to enable AI responses.',
        translation: 'Это демо-режим. Добавьте API ключ, чтобы включить ответы ИИ.',
      );
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final personalizedPrompt = '''
You are an English tutor inside a mobile app for learning English.

Student profile:
- Name: $userName
- English level: $level
- Interests: ${interests.join(', ')}

Instructions:
1. The user should practice English only.
2. Always reply in English.
3. Also provide a Russian translation of your English reply.
4. Check the user's English grammar.
5. Keep explanations short and simple.
6. Adapt your English to the student's level.
7. Use the student's interests naturally in examples and follow-up questions.
8. Return valid JSON only, without markdown.

Required JSON format:
{
  "user_message_feedback": {
    "is_correct": true,
    "corrected_text": "",
    "hint": "Good job!"
  },
  "reply": "Your English reply here.",
  "translation": "Русский перевод ответа."
}
''';

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "model": "gpt-4o-mini",
              "response_format": {"type": "json_object"},
              "messages": [
                {"role": "system", "content": personalizedPrompt},
                {"role": "user", "content": message},
              ],
              "temperature": 0.7,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        return AIChatResult(
          isCorrect: false,
          correctedText: '',
          hint: 'AI request failed.',
          reply: 'Sorry, I am having trouble right now. Please try again.',
          translation: 'Извините, сейчас есть проблема с ответом ИИ. Попробуйте снова.',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['choices']?[0]?['message']?['content'];

      if (content == null || content.toString().trim().isEmpty) {
        throw Exception('Empty AI response');
      }

      final parsed = jsonDecode(content.toString()) as Map<String, dynamic>;
      return AIChatResult.fromJson(parsed);
    } catch (_) {
      return AIChatResult(
        isCorrect: false,
        correctedText: '',
        hint: 'Connection or parsing error.',
        reply: 'Sorry, something went wrong. Please try again.',
        translation: 'Извините, произошла ошибка. Попробуйте снова.',
      );
    }
  }

  Future<List<AIExercise>> generateExercises({
    required String userName,
    required String level,
    required List<String> interests,
    required List<String> learnedWords,
  }) async {
    if (!_hasApiKey) {
      return [
        AIExercise(
          type: 'multiple_choice',
          question: 'Выберите перевод слова "actor"',
          options: ['актёр', 'сцена', 'билет'],
          wordBank: [],
          correctAnswer: 'актёр',
          hint: 'Это человек, который играет в фильмах.',
          translation: 'Choose the translation of “actor”.',
          explanation: 'Actor переводится как актёр.',
        ),
        AIExercise(
          type: 'multiple_choice',
          question: 'Выберите перевод слова "scene"',
          options: ['песня', 'сцена', 'уровень'],
          wordBank: [],
          correctAnswer: 'сцена',
          hint: 'Это часть фильма или спектакля.',
          translation: 'Choose the translation of “scene”.',
          explanation: 'Scene переводится как сцена.',
        ),
        AIExercise(
          type: 'fill_blank',
          question: 'The _____ is famous.',
          options: [],
          wordBank: ['actor', 'scene', 'ticket'],
          correctAnswer: 'actor',
          hint: 'Нужно вставить слово: человек, который играет в фильме.',
          translation: 'Этот актёр известный.',
          explanation: 'Правильный ответ: actor.',
        ),
        AIExercise(
          type: 'fill_blank',
          question: 'This _____ is beautiful.',
          options: [],
          wordBank: ['scene', 'actor', 'episode'],
          correctAnswer: 'scene',
          hint: 'Это часть фильма.',
          translation: 'Эта сцена красивая.',
          explanation: 'Правильный ответ: scene.',
        ),
        AIExercise(
          type: 'build_sentence',
          question: 'Соберите предложение: Актёр известный.',
          options: ['famous', 'actor', 'is', 'The'],
          wordBank: [],
          correctAnswer: 'The actor is famous',
          hint: 'Начало предложения: The actor...',
          translation: 'Актёр известный.',
          explanation: 'Правильный порядок: The actor is famous.',
        ),
      ];
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final prompt = '''
You are an English learning assistant inside a mobile learning app.

Student profile:
- Name: $userName
- Level: $level
- Interests: ${interests.join(', ')}
- Learned words: ${learnedWords.join(', ')}

Generate exactly 10 exercises:
- 3 multiple_choice
- 3 fill_blank
- 3 build_sentence
- 1 mixed_challenge

Universal rules:
- Use the student's learned words naturally.
- Use the student's interests in examples when possible.
- Return valid JSON only.
- Do not include markdown.
- Every exercise MUST include: type, question, options, wordBank, correctAnswer, hint, translation, explanation.
- For multiple_choice, provide exactly 3 options.
- For fill_blank, options must be an empty array and wordBank must contain exactly 3 English word options.
- For build_sentence and mixed_challenge, options must contain shuffled words.
- correctAnswer must match the expected answer exactly.
- Hints must help the user but must not directly reveal the answer unless the level is Beginner.

Beginner rules:
- Questions must be mostly in Russian.
- Keep target English words in English.
- Explanations must be in Russian.
- Hints must be in Russian.
- Provide translation field in Russian.
- Use very short English sentences.
- For fill_blank, use simple sentences like: "The _____ is famous."
- For build_sentence, use only 3–5 words.
- Avoid complex grammar, idioms, and phrasal verbs.

Intermediate rules:
- Questions can be in simple English.
- Explanations should be in Russian.
- Hints can be in Russian or simple English.
- Use everyday English sentences.
- For build_sentence, use 5–8 words.

Advanced rules:
- Questions, hints, and explanations must be in English.
- Use richer vocabulary and more natural expressions.
- For build_sentence, use 7–12 words.

Required JSON:
{
  "exercises": [
    {
      "type": "fill_blank",
      "question": "The _____ is famous.",
      "options": [],
      "wordBank": ["actor", "scene", "ticket"],
      "correctAnswer": "actor",
      "hint": "Это человек, который играет в фильме.",
      "translation": "Актёр известный.",
      "explanation": "Actor — это актёр."
    }
  ]
}
''';

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "model": "gpt-4o-mini",
              "response_format": {"type": "json_object"},
              "messages": [
                {"role": "system", "content": prompt}
              ],
              "temperature": 0.7,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['choices']?[0]?['message']?['content'];

      if (content == null || content.toString().trim().isEmpty) return [];

      final parsed = jsonDecode(content.toString()) as Map<String, dynamic>;
      final exercises = parsed['exercises'];

      if (exercises == null || exercises is! List) return [];

      return exercises
          .map((e) => AIExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, String>>> generateLearningWords({
    required String level,
    required List<String> interests,
  }) async {
    if (!_hasApiKey) {
      return [
        {
          'word': 'actor',
          'translation': 'актёр',
          'example': 'The actor is famous.',
        },
        {
          'word': 'scene',
          'translation': 'сцена',
          'example': 'This scene is beautiful.',
        },
        {
          'word': 'episode',
          'translation': 'эпизод',
          'example': 'I watched one episode.',
        },
      ];
    }

    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    final prompt = '''
Generate exactly 3 English words for learning.

Rules:
- Adapt to level: $level.
- Match interests: ${interests.join(', ')}.
- Provide Russian translation.
- Provide a simple example sentence.
- If level is Beginner, use very simple words.
- Return valid JSON only.

Format:
{
  "words": [
    {
      "word": "actor",
      "translation": "актёр",
      "example": "The actor is famous."
    }
  ]
}
''';

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              "model": "gpt-4o-mini",
              "response_format": {"type": "json_object"},
              "messages": [
                {"role": "system", "content": prompt}
              ],
              "temperature": 0.7,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) return [];

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final content = decoded['choices']?[0]?['message']?['content'];

      if (content == null || content.toString().trim().isEmpty) return [];

      final parsed = jsonDecode(content.toString()) as Map<String, dynamic>;
      final words = parsed['words'];

      if (words == null || words is! List) return [];

      return words.map<Map<String, String>>((item) {
        final map = item as Map<String, dynamic>;
        return {
          'word': (map['word'] ?? '').toString(),
          'translation': (map['translation'] ?? '').toString(),
          'example': (map['example'] ?? '').toString(),
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
  Future<List<Map<String, String>>> generateVocabularyWords({
  required String level,
  required List<String> interests,
  required List<String> excludeWords,
}) async {
  if (!_hasApiKey) {
    return [
      {
        'word': 'director',
        'translation': 'режиссёр',
        'example': 'The director made a great movie.',
        'exampleTranslation': 'Режиссёр снял отличный фильм.',
      },
      {
        'word': 'soundtrack',
        'translation': 'саундтрек',
        'example': 'The soundtrack was very emotional.',
        'exampleTranslation': 'Саундтрек был очень эмоциональным.',
      },
      {
        'word': 'plot',
        'translation': 'сюжет',
        'example': 'The plot was interesting.',
        'exampleTranslation': 'Сюжет был интересным.',
      },
    ];
  }

  final url = Uri.parse('https://api.openai.com/v1/chat/completions');

  final prompt = '''
Generate exactly 20 different English vocabulary words for a learning app.

Student:
- Level: $level
- Interests: ${interests.join(', ')}
- Already learned / excluded words: ${excludeWords.join(', ')}

Rules:
- Do NOT repeat any excluded words.
- Do NOT generate very common repeated words like actor, scene, episode if they are excluded.
- Match the student's interests.
- Adapt words to the student's level.
- Provide Russian translation.
- Provide one simple English example sentence.
- Provide Russian translation of the example.
- All words must be unique.
- Return valid JSON only.

Format:
{
  "words": [
    {
      "word": "director",
      "translation": "режиссёр",
      "example": "The director made a great movie.",
      "exampleTranslation": "Режиссёр снял отличный фильм."
    }
  ]
}
''';

  try {
    final response = await http
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            "model": "gpt-4o-mini",
            "response_format": {"type": "json_object"},
            "messages": [
              {"role": "system", "content": prompt}
            ],
            "temperature": 1.0,
          }),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) return [];

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = decoded['choices']?[0]?['message']?['content'];

    if (content == null || content.toString().trim().isEmpty) return [];

    final parsed = jsonDecode(content.toString()) as Map<String, dynamic>;
    final words = parsed['words'];

    if (words == null || words is! List) return [];

    final seen = <String>{};

    return words.map<Map<String, String>>((item) {
      final map = item as Map<String, dynamic>;
      return {
        'word': (map['word'] ?? '').toString(),
        'translation': (map['translation'] ?? '').toString(),
        'example': (map['example'] ?? '').toString(),
        'exampleTranslation': (map['exampleTranslation'] ?? '').toString(),
      };
    }).where((item) {
      final word = (item['word'] ?? '').toLowerCase().trim();
      if (word.isEmpty) return false;
      if (seen.contains(word)) return false;
      seen.add(word);
      return !excludeWords.map((e) => e.toLowerCase()).contains(word);
    }).toList();
  } catch (_) {
    return [];
  }
}
}