import 'package:flutter/material.dart';

import '../../../core/navigation/app_router.dart';
import '../../../core/navigation/page_transition_type.dart';
import 'prayer_result_screen.dart';
import '../service/prayer_service.dart';
import '../../../core/config/app_branding.dart';
import '../../../shared/widgets/branding_widgets.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final List<String> topics = [
    'Peace',
    'Fear',
    'Guidance',
    'Gratitude',
    'Strength',
  ];

  bool _loading = false;
  String? _loadingTopic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const LogosHeader('${AppBranding.logosPrayer} 🙏'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: topics.length,
            itemBuilder: (_, i) {
              final topic = topics[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    topic,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _loading ? null : () => _generatePrayer(topic),
                ),
              );
            },
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('Seeking guidance for $_loadingTopic...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generatePrayer(String topic) async {
    setState(() {
      _loading = true;
      _loadingTopic = topic;
    });

    try {
      final result = await PrayerService.generate(topic);
      if (!mounted) return;
      AppRouter.push(
        context,
        PrayerResultScreen(prayer: result),
        transition: AppTransitionType.devotional,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate prayer: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingTopic = null;
        });
      }
    }
  }
}
