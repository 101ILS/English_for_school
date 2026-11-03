import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme.dart';

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  final AuthService authService = AuthService();
  final UserService userService = UserService();

  bool isLoading = true;
  int learnedWordsCount = 0;

  bool exercise1Unlocked = false;
  bool exercise1Completed = false;

  bool exercise2Unlocked = false;
  bool exercise2Completed = false;

  bool exercise3Unlocked = false;
  bool exercise3Completed = false;

  bool exercise4Unlocked = false;
  bool exercise4Completed = false;

  bool exercise5Unlocked = false;
  bool exercise5Completed = false;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final user = authService.currentUser;

    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    final count = await userService.getLearnedWordsCount(user.uid);

    final exercise1Progress = await userService.getExerciseProgress(
      uid: user.uid,
      exerciseId: 'exercise1',
    );
    final exercise2Progress = await userService.getExerciseProgress(
      uid: user.uid,
      exerciseId: 'exercise2',
    );
    final exercise3Progress = await userService.getExerciseProgress(
      uid: user.uid,
      exerciseId: 'exercise3',
    );
    final exercise4Progress = await userService.getExerciseProgress(
      uid: user.uid,
      exerciseId: 'exercise4',
    );
    final exercise5Progress = await userService.getExerciseProgress(
      uid: user.uid,
      exerciseId: 'exercise5',
    );

    final ex1Completed = exercise1Progress?['completed'] == true;
    final ex2Completed = exercise2Progress?['completed'] == true;
    final ex3Completed = exercise3Progress?['completed'] == true;
    final ex4Completed = exercise4Progress?['completed'] == true;
    final ex5Completed = exercise5Progress?['completed'] == true;

    setState(() {
      learnedWordsCount = count;

      exercise1Unlocked = count >= 3;
      exercise1Completed = ex1Completed;

      exercise2Unlocked = ex1Completed && count >= 6;
      exercise2Completed = ex2Completed;

      exercise3Unlocked = ex2Completed && count >= 9;
      exercise3Completed = ex3Completed;

      exercise4Unlocked = ex3Completed && count >= 12;
      exercise4Completed = ex4Completed;

      exercise5Unlocked = ex4Completed && count >= 15;
      exercise5Completed = ex5Completed;

      isLoading = false;
    });
  }

  Widget exerciseCard({
    required String title,
    required String subtitle,
    required bool unlocked,
    required bool completed,
    required int requiredWords,
    required VoidCallback? onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
              ),
              if (completed)
                const Icon(Icons.check_circle, color: Colors.green)
              else if (!unlocked)
                const Icon(Icons.lock_outline, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: kTextLight,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (learnedWordsCount / requiredWords).clamp(0, 1),
            backgroundColor: Colors.grey.shade300,
            color: completed ? Colors.green : kPrimary,
          ),
          const SizedBox(height: 8),
          Text(
            '${learnedWordsCount >= requiredWords ? requiredWords : learnedWordsCount} / $requiredWords learned words',
            style: const TextStyle(
              color: kTextLight,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: unlocked ? onTap : null,
              child: Text(
                completed
                    ? 'Completed'
                    : unlocked
                        ? 'Start'
                        : 'Locked',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String lockedSubtitleForExercise({
    required int exerciseNumber,
    required bool previousCompleted,
  }) {
    final requiredWords = exerciseNumber * 3;

    if (learnedWordsCount < requiredWords) {
      return 'Learn ${requiredWords - learnedWordsCount} more words to unlock this level.';
    }

    if (!previousCompleted && exerciseNumber > 1) {
      return 'Complete Exercise ${exerciseNumber - 1} to unlock this level.';
    }

    return 'Locked.';
  }

  String unlockedSubtitle(int exerciseNumber) {
    final startWord = ((exerciseNumber - 1) * 3) + 1;
    final endWord = exerciseNumber * 3;

    return 'Practice with learned words $startWord–$endWord.';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Exercises'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (!exercise1Unlocked)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Exercises are locked',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: kTextDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learn ${3 - learnedWordsCount} more words to unlock Exercise 1.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kTextLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: (learnedWordsCount / 3).clamp(0, 1),
                      backgroundColor: Colors.grey.shade300,
                      color: kPrimary,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$learnedWordsCount / 3 words learned',
                      style: const TextStyle(color: kTextLight),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                children: [
                  exerciseCard(
                    title: 'Exercise 1',
                    subtitle: exercise1Completed
                        ? 'You completed Exercise 1.'
                        : exercise1Unlocked
                            ? unlockedSubtitle(1)
                            : lockedSubtitleForExercise(
                                exerciseNumber: 1,
                                previousCompleted: true,
                              ),
                    unlocked: exercise1Unlocked,
                    completed: exercise1Completed,
                    requiredWords: 3,
                    onTap: () {
                      Navigator.pushNamed(context, '/exercise1').then((_) {
                        loadProgress();
                      });
                    },
                  ),
                  exerciseCard(
                    title: 'Exercise 2',
                    subtitle: exercise2Completed
                        ? 'You completed Exercise 2.'
                        : exercise2Unlocked
                            ? unlockedSubtitle(2)
                            : lockedSubtitleForExercise(
                                exerciseNumber: 2,
                                previousCompleted: exercise1Completed,
                              ),
                    unlocked: exercise2Unlocked,
                    completed: exercise2Completed,
                    requiredWords: 6,
                    onTap: () {
                      Navigator.pushNamed(context, '/exercise2').then((_) {
                        loadProgress();
                      });
                    },
                  ),
                  exerciseCard(
                    title: 'Exercise 3',
                    subtitle: exercise3Completed
                        ? 'You completed Exercise 3.'
                        : exercise3Unlocked
                            ? unlockedSubtitle(3)
                            : lockedSubtitleForExercise(
                                exerciseNumber: 3,
                                previousCompleted: exercise2Completed,
                              ),
                    unlocked: exercise3Unlocked,
                    completed: exercise3Completed,
                    requiredWords: 9,
                    onTap: () {
                      Navigator.pushNamed(context, '/exercise3').then((_) {
                        loadProgress();
                      });
                    },
                  ),
                  exerciseCard(
                    title: 'Exercise 4',
                    subtitle: exercise4Completed
                        ? 'You completed Exercise 4.'
                        : exercise4Unlocked
                            ? unlockedSubtitle(4)
                            : lockedSubtitleForExercise(
                                exerciseNumber: 4,
                                previousCompleted: exercise3Completed,
                              ),
                    unlocked: exercise4Unlocked,
                    completed: exercise4Completed,
                    requiredWords: 12,
                    onTap: () {
                      Navigator.pushNamed(context, '/exercise4').then((_) {
                        loadProgress();
                      });
                    },
                  ),
                  exerciseCard(
                    title: 'Exercise 5',
                    subtitle: exercise5Completed
                        ? 'You completed Exercise 5.'
                        : exercise5Unlocked
                            ? unlockedSubtitle(5)
                            : lockedSubtitleForExercise(
                                exerciseNumber: 5,
                                previousCompleted: exercise4Completed,
                              ),
                    unlocked: exercise5Unlocked,
                    completed: exercise5Completed,
                    requiredWords: 15,
                    onTap: () {
                      Navigator.pushNamed(context, '/exercise5').then((_) {
                        loadProgress();
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}