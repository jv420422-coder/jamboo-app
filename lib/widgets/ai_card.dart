import 'package:flutter/material.dart';
import '../screens/jamboo_ai_screen.dart';
class AICard extends StatelessWidget {
  const AICard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 15,
      ),
      child: GestureDetector(
        onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const JambooAIScreen(),
    ),
  );
},
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 16 / 5.5,
            child: Image.asset(
              "assets/images/jamboo_ai.png",
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}