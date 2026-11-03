import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AgePage extends StatefulWidget {
  const AgePage({super.key});

  @override
  State<AgePage> createState() => _AgePageState();
}

class _AgePageState extends State<AgePage> {
  String? selectedAge;

  final List<String> ages = [
    'Младше 18',
    '18 - 24',
    '25 - 34',
    '35 - 44',
    '45+',
  ];

  final AuthService _authService = AuthService();
  final UserService _userService = UserService();


  Future<void> goNext() async {
    if (selectedAge == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Пожалуйста, выберите возраст')),
      );
      return;
    }

    final user = _authService.currentUser;

    if (user != null) {
      await _userService.updateAge(
        uid: user.uid,
        age: selectedAge!,
      );
    }

    Navigator.pushNamed(context, '/level');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Шаг 1 из 3'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Сколько вам лет?', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
              'Это поможет нам адаптировать ваш опыт обучения.',
              style: TextStyle(color: kTextLight, fontSize: 15),
            ),
            const SizedBox(height: 22),
            Expanded(
              child: ListView.builder(
                itemCount: ages.length,
                itemBuilder: (context, index) {
                  final age = ages[index];
                  final isSelected = selectedAge == age;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedAge = age;
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
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              color: isSelected ? kPrimary : kTextLight,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              age,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                color: kTextDark,
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