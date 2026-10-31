import 'package:flutter/material.dart';

class SermonTranscriptEditorScreen extends StatefulWidget {
  const SermonTranscriptEditorScreen(
      {super.key, required this.transcript, required this.onSave});

  final String transcript;
  final Future<void> Function(String text) onSave;

  @override
  State<SermonTranscriptEditorScreen> createState() => _TranscriptEditorState();
}

class _TranscriptEditorState extends State<SermonTranscriptEditorScreen> {
  late final TextEditingController _controller;
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  bool _allowPop = false;
  bool _confirming = false;
  bool get _dirty => _controller.text.trim() != widget.transcript.trim();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.transcript);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_saving || _confirming) return;
    if (_dirty) {
      _confirming = true;
      final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('Discard transcript changes?'),
                content:
                    const Text('Your saved transcript will stay as it was.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep Editing')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Discard')),
                ],
              ));
      _confirming = false;
      if (discard != true || !mounted) return;
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.pop(context, false);
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(_controller.text.trim());
      if (!mounted) return;
      setState(() {
        _allowPop = true;
        _saving = false;
      });
      Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Could not save your transcript. Your edits are still here. Please retry.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
        canPop: _allowPop || (!_dirty && !_saving),
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _leave();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Edit Transcript'),
            leading: IconButton(
                onPressed: _saving ? null : _leave,
                tooltip: 'Cancel',
                icon: const Icon(Icons.close)),
            actions: [
              TextButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save'))
            ],
          ),
          body: SafeArea(
              child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                  'Corrections stay on this device. Editing resets generated insights and word timings.'),
                              const SizedBox(height: 16),
                              SizedBox(
                                  height: (constraints.maxHeight - 140)
                                      .clamp(180.0, double.infinity),
                                  child: Form(
                                      key: _form,
                                      child: TextFormField(
                                        controller: _controller,
                                        enabled: !_saving,
                                        expands: true,
                                        maxLines: null,
                                        minLines: null,
                                        textAlignVertical:
                                            TextAlignVertical.top,
                                        textCapitalization:
                                            TextCapitalization.sentences,
                                        decoration: const InputDecoration(
                                            labelText: 'Transcript',
                                            alignLabelWithHint: true,
                                            border: OutlineInputBorder()),
                                        validator: (value) => value == null ||
                                                value.trim().isEmpty
                                            ? 'Enter some transcript text before saving.'
                                            : null,
                                        onChanged: (_) => setState(() {}),
                                      ))),
                            ]),
                      ))),
        ),
      );
}
