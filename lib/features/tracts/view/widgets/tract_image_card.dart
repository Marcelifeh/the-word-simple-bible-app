import 'package:flutter/material.dart';

import '../../tract_model.dart';

class TractImageCard extends StatelessWidget {
  const TractImageCard({super.key, required this.tract});

  final TractModel tract;

  @override
  Widget build(BuildContext context) {
    final colors = tract.gradientColors.map((v) => Color(v)).toList();

    return Container(
      width: 1080,
      height: 1080,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Subtle background pattern/overlay could go here if desired.

          Padding(
            padding: const EdgeInsets.all(80.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Hook
                Text(
                  tract.hook,
                  style: TextStyle(
                    fontSize: 48,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 60),

                // Key Verse
                Icon(Icons.format_quote_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 100),
                const SizedBox(height: 20),
                Text(
                  tract.keyVerse,
                  style: const TextStyle(
                    fontSize: 64,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 40),

                // Reference
                Row(
                  children: [
                    Container(
                      width: 80,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 30),
                    Text(
                      tract.keyVerseRef,
                      style: const TextStyle(
                        fontSize: 42,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Footer branding
          Positioned(
            bottom: 60,
            left: 80,
            right: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.menu_book_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 20),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The Word App',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        Text(
                          'Read & Share the Gospel',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white70,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Text(
                    'Get the App',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
