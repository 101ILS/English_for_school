import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  String? selectedLevel;

  final List<Map<String, String>> levels = [
    {
      'title': 'Beginner',
      'subtitle': 'Я знаю только несколько базовых слов и фраз.',
    },
    {
      'title': 'Elementary',
      'subtitle': 'Я могу понимать простой повседневный английский.',
    },
    {
      'title': 'Intermediate',
      'subtitle': 'Я могу говорить и понимать общие темы.',
    },
    {
      'title': 'Advanced',
      'subtitle': 'Я уверенно использую английский в многих ситуациях.',
    },
  ];

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  Future<void> goNext() async {
    if (selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите свой уровень английского')),
      );
      return;
    }

    final user = _authService.currentUser;

    if (user != null) {
      await _userService.updateLevel(
        uid: user.uid,
        level: selectedLevel!,
      );
    }

    Navigator.pushNamed(context, '/interests');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаг 2 из 3'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ваш уровень английского',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите уровень, который лучше всего соответствует вашим навыкам.',
              style: TextStyle(color: kTextLight, fontSize: 15),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView.builder(
                itemCount: levels.length,
                itemBuilder: (context, index) {
                  final item = levels[index];
                  final title = item['title']!;
                  final subtitle = item['subtitle']!;
                  final isSelected = selectedLevel == title;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLevel = title;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary.withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isSelected ? kPrimary : const Color(0xFFE6E8F0),
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 12,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? kPrimary : kTextLight,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: kTextDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: kTextLight,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: goNext,
              child: const Text('Далее'),
            ),
          ],
        ),
      ),
    );
  }
}