import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  bool isLoading = true;
  int learnedWordsCount = 0;
  bool isExercisesUnlocked = false;
  double overallProgress = 0;
  String name = '';
  String email = '';
  String age = '';
  String level = '';
  List<String> interests = [];

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    try {
      final user = _authService.currentUser;
      

      if (user == null) {
        return;
      }

      final data = await _userService.getUserProfile(user.uid);
      final learnedCount = await _userService.getLearnedWordsCount(user.uid);
      final progress = await _userService.getOverallProgress(user.uid);

      if (data != null && mounted) {
        setState(() {
          name = data['name'] ?? '';
          email = data['email'] ?? '';
          age = data['age'] ?? '';
          level = data['level'] ?? '';
          interests = List<String>.from(data['interests'] ?? []);
          learnedWordsCount = learnedCount;
          isExercisesUnlocked = learnedCount >= 5;
          overallProgress = progress;
          isLoading = false;
          
        });
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
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
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    color: kTextLight,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _interestChip(String text) {
    return Container(
      margin: const EdgeInsets.only(right: 10, bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextDark,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
  width: double.infinity,
  padding: const EdgeInsets.all(26),
  decoration: gradientCardDecoration,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              'Hello, ${name.isEmpty ? 'User' : name} 👋',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        email.isEmpty ? 'Welcome to English AI' : email,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 18),
      Wrap(
        children: [
          if (age.isNotEmpty) _infoChip('Age: $age'),
          if (level.isNotEmpty) _infoChip('Level: $level'),
        ],
      ),
      const SizedBox(height: 14),
      Text(
  'Overall progress: ${(overallProgress * 100).toInt()}%',
  style: const TextStyle(
    color: Colors.white,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  ),
),

const SizedBox(height: 8),

LinearProgressIndicator(
  value: overallProgress,
  backgroundColor: Colors.white24,
  color: Colors.white,
),
    ],
  ),
),
              const SizedBox(height: 24),
              if (interests.isNotEmpty) ...[
                const Text(
                  'Твои интересы',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: kTextDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  children: interests.map((item) => _interestChip(item)).toList(),
                ),
                const SizedBox(height: 20),
              ],
              const Text(
                'Твои инструменты обучения',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kTextDark,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/chat');
                      },
                      child: _featureCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'AI Chat',
                        subtitle: 'Общайтесь с ИИ и получайте мгновенную обратную связь.',
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/vocabulary');
                      },
                      child: _featureCard(
                        icon: Icons.menu_book_outlined,
                        title: 'Изучение слов',
                        subtitle: 'Учитесь словам и фразам, которые вас интересуют.',
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
  onTap: () {
    Navigator.pushNamed(context, '/exercises');
  },
  child: _featureCard(
    icon: Icons.quiz_outlined,
    title: 'Упражнения',
    subtitle: isExercisesUnlocked
        ? 'Упражнение 1 разблокировано.'
        : 'Выучите 5 слов, чтобы разблокировать упражнения.',
    color: Colors.orange,
  ),
),
                    const SizedBox(height: 14),
                    
                    

                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/grammar');
                      },
                      child: _featureCard(
                        icon: Icons.auto_fix_high_outlined,
                        title: 'Грамматика',
                        subtitle: 'Пишите предложения и позволяйте ИИ исправлять ваши ошибки.',
                        color: Colors.green,
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
  }
}