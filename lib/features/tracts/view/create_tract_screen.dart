import 'package:flutter/material.dart';

import '../../../shared/state/app_state.dart';
import '../model/user_tract.dart';

class CreateTractScreen extends StatefulWidget {
  const CreateTractScreen({super.key});

  @override
  State<CreateTractScreen> createState() => _CreateTractScreenState();
}

class _CreateTractScreenState extends State<CreateTractScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _saving = false;

  // Quick-start templates
  static const _templates = [
    (
      'God Loves You',
      'God loves you more than you can imagine. "For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life." — John 3:16\n\nNo matter what you have done or where you have been, His love never ends. You are not too far gone.'
    ),
    (
      'There Is Hope in Christ',
      'If you are carrying a heavy burden today, there is hope. Jesus said, "Come to me, all you who are weary and burdened, and I will give you rest." — Matthew 11:28\n\nHe does not promise a life without pain, but He promises to walk through it with you. You are not alone.'
    ),
    (
      'You Are Forgiven',
      '"If we confess our sins, he is faithful and just and will forgive us our sins and purify us from all unrighteousness." — 1 John 1:9\n\nForgiveness is not earned — it is freely given. Whatever you carry, you can lay it down at His feet today.'
    ),
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final tract = UserTract(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      message: _messageCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    AppScope.of(context).userTractRepo.add(tract);

    if (mounted) Navigator.pop(context, true); // true = saved
  }

  void _applyTemplate(String title, String message) {
    _titleCtrl.text = title;
    _messageCtrl.text = message;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Tract ✍️'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Save', style: TextStyle(color: cs.primary)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            // ── Quick templates ─────────────────────────────────────────
            Text('Start from a template', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _templates.map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(t.$1),
                      onPressed: () => _applyTemplate(t.$1, t.$2),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title ────────────────────────────────────────────────────
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. God Loves You',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.title),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                if (v.trim().length < 3) {
                  return 'Title must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Message ──────────────────────────────────────────────────
            TextFormField(
              controller: _messageCtrl,
              maxLines: 10,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Share God\'s message in your own words…',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 152),
                  child: Icon(Icons.edit_note),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Message is required';
                if (v.trim().length < 20) {
                  return 'Message must be at least 20 characters';
                }
                if (v.trim().length > 2000) {
                  return 'Message must be 2 000 characters or fewer';
                }
                return null;
              },
            ),

            // ── Character count hint ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _messageCtrl,
                  builder: (_, v, __) => Text(
                    '${v.text.length}/2000',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: v.text.length > 2000 ? cs.error : null,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Tract'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
