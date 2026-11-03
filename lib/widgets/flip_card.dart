import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class FlipCard extends StatefulWidget {
  final String word;
  final String translation;
  final String example;
  final String exampleTranslation;
  final VoidCallback onLearned;

  const FlipCard({
    super.key,
    required this.word,
    required this.translation,
    required this.example,
    required this.exampleTranslation,
    required this.onLearned,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  bool isFront = true;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );

    animation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOut),
    );
  }

  void flip() {
    if (controller.isAnimating) return;

    if (isFront) {
      controller.forward();
    } else {
      controller.reverse();
    }

    setState(() {
      isFront = !isFront;
    });
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.word != widget.word) {
      controller.reset();
      isFront = true;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget cardShell({required Widget child}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget buildFront() {
    return cardShell(
      child: Center(
        child: Text(
          widget.word,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: kTextDark,
          ),
        ),
      ),
    );
  }

  Widget buildBack() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationY(pi),
      child: cardShell(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.translation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: kPrimary,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.example,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextDark,
                fontSize: 16,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.exampleTranslation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kTextLight,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: widget.onLearned,
              child: const Text('Mark as learned'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final angle = animation.value;

            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle),
              child: angle <= pi / 2 ? buildFront() : buildBack(),
            );
          },
        ),
      ),
    );
  }
}