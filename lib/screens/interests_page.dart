import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class InterestsPage extends StatefulWidget {
  const InterestsPage({super.key});

  @override
  State<InterestsPage> createState() => _InterestsPageState();
}

class _InterestsPageState extends State<InterestsPage> {
  final List<String> interests = [
    'Фильмы',
    'Музыка',
    'Аниме',
    'Спорт',
    'Наука',
    'Технологии',
    'Путешествия',
    'Книги',
    'Игры',
    'Бизнес',
    'Искусство',
    'История',
  ];

  final Set<String> selected = {};
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  Future<void> finish() async {
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы один интерес')),
      );
      return;
    }

    final user = _authService.currentUser;

    if (user != null) {
      await _userService.updateInterests(
        uid: user.uid,
        interests: selected.toList(),
      );
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаг 3 из 3'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Что вам нравится?',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Мы создадим уроки английского языка на основе ваших интересов.',
              style: TextStyle(color: kTextLight, fontSize: 15),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: interests.map((interest) {
                    final isSelected = selected.contains(interest);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selected.remove(interest);
                          } else {
                            selected.add(interest);
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? kPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x10000000),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          interest,
                          style: TextStyle(
                            color: isSelected ? Colors.white : kTextDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: finish,
              child: const Text('Завершить'),
            ),
          ],
        ),
      ),
    );
  }
}