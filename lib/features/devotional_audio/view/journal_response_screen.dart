import 'package:flutter/material.dart';
import '../../devotional/model/devotional_model.dart';
import 'completion_screen.dart';
import '../../../shared/state/app_state.dart';

class JournalResponseScreen extends StatefulWidget {
  final DevotionalModel devotional;

  const JournalResponseScreen({super.key, required this.devotional});

  @override
  State<JournalResponseScreen> createState() => _JournalResponseScreenState();
}

class _JournalResponseScreenState extends State<JournalResponseScreen> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final prefilledText = "What spoke to your heart today?\n\nToday's Truth:\n${widget.devotional.finalRevelation}\n\n";
    _controller = TextEditingController(text: prefilledText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveAndComplete() {
    // Here we would integrate with the actual LOGOS Notes / Journal feature
    // For MVP, we'll assume it's saved successfully and navigate to completion.
    final state = AppScope.of(context);
    state.narrationController.stop(); // Ensure audio is stopped

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => CompletionScreen(devotional: widget.devotional),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () {
            final state = AppScope.of(context);
            state.narrationController.stop();
            Navigator.pop(context);
          },
        ),
        title: const Text('Journal Response', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '📝',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write your thoughts here...',
                      hintStyle: TextStyle(color: Colors.white54),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveAndComplete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1E1E2C),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save to Journal & Finish',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
