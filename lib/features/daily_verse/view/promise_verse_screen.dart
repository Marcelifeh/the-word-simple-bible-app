import 'package:flutter/material.dart';

import '../model/promise_verse.dart';

class PromiseVerseScreen extends StatelessWidget {
  final PromiseVerse promise;

  const PromiseVerseScreen({
    super.key,
    required this.promise,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Promise"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  promise.reference,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF8B5CF6),
                      ),
                ),
              ),
              _PromiseTagLarge(tag: promise.tag),
            ],
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [
                  Color(0x332D1B69),
                  Color(0x22111427),
                ],
              ),
              border: Border.all(
                color: Color(0x558B5CF6),
              ),
            ),
            child: Text(
              '"${promise.text}"',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Promise Insight',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            promise.commentary,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.65,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
          ),
        ],
      ),
    );
  }
}

class _PromiseTagLarge extends StatelessWidget {
  final String tag;

  const _PromiseTagLarge({
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEC4899).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFFEC4899).withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: Color(0xFFFF7AB6),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
