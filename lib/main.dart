import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/age_page.dart';
import 'screens/level_page.dart';
import 'screens/interests_page.dart';
import 'screens/home_page.dart';
import 'screens/ai_chat_page.dart';
import 'screens/grammar_check_page.dart';
import 'screens/vocabulary_page.dart';
import 'screens/exercises_page.dart';
import 'screens/exercise_one_page.dart';
import 'screens/exercise_two_page.dart';
import 'screens/ai_exercise_session_page.dart';
import 'screens/ai_learning_page.dart';
import 'screens/speaking_sentence_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EnglishAiApp());
}

class EnglishAiApp extends StatelessWidget {
  const EnglishAiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'English AI',
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/age': (context) => const AgePage(),
        '/level': (context) => const LevelPage(),
        '/interests': (context) => const InterestsPage(),
        '/home': (context) => const HomePage(),
        '/chat': (context) => const AIChatPage(),
        '/grammar': (context) => const GrammarCheckPage(),
        '/vocabulary': (context) => const VocabularyPage(),
        '/exercises': (context) => const ExercisesPage(),
        '/exercise1': (context) => const ExerciseOnePage(),
        '/exercise2': (context) => const ExerciseTwoPage(),
        '/exercise-session': (context) => const AIExerciseSessionPage(exerciseNumber: 1),
        '/ai-learning': (context) => const AILearningPage(),
        '/exercise3': (context) => const AIExerciseSessionPage(exerciseNumber: 3),
        '/exercise4': (context) => const AIExerciseSessionPage(exerciseNumber: 4),
        '/exercise5': (context) => const AIExerciseSessionPage(exerciseNumber: 5),
        '/speaking-sentence': (context) => const SpeakingSentencePage(),
      },
    );
  }
}
