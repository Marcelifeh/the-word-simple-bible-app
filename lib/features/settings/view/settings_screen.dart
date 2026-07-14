import 'package:flutter/material.dart';
import '../../../core/config/app_branding.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/env.dart';
import '../../../shared/state/app_state.dart';
import '../../legal/data/legal_documents.dart';
import '../../legal/view/legal_document_screen.dart';
import 'audio_narration_settings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notifications = true;
  String language = 'English';
  final List<Map<String, dynamic>> colorThemes = [
    {'label': 'Indigo', 'color': Colors.indigo},
    {'label': 'Green', 'color': Colors.green},
    {'label': 'Deep Orange', 'color': Colors.deepOrange},
    {'label': 'Purple', 'color': Colors.purple},
    {'label': 'Blue Grey', 'color': Colors.blueGrey},
  ];
  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('⚙️ Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: state.themeMode == ThemeMode.dark,
            onChanged: (val) =>
                state.setThemeMode(val ? ThemeMode.dark : ThemeMode.light),
          ),
          const Divider(),
          ListTile(
            title: const Text('Color Theme'),
            // Wrap in SingleChildScrollView for horizontal scrolling if needed
            subtitle: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(colorThemes.length, (i) {
                  final color = colorThemes[i]['color'] as Color;
                  final isSelected =
                      color.toARGB32() == state.primarySeed.toARGB32();
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(colorThemes[i]['label']),
                      selected: isSelected,
                      selectedColor: color.withValues(alpha: 0.2),
                      backgroundColor: color.withValues(alpha: 0.1),
                      onSelected: (selected) {
                        if (selected) {
                          state.setPrimarySeed(color);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Text Size'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Slider(
                  min: 0.85,
                  max: 1.5,
                  divisions: 13,
                  value: state.fontScale,
                  label: '${(state.fontScale * 100).round()}%',
                  onChanged: (v) => state.setFontScale(v),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verse Preview',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: (Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.fontSize ??
                                          18) *
                                      state.fontScale,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This is how the commentary will look in the app.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: (Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.fontSize ??
                                      14) *
                                  state.fontScale,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Notifications'),
            value: notifications,
            onChanged: (val) => setState(() => notifications = val),
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            trailing: DropdownButton<String>(
              value: language,
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'French', child: Text('French')),
                DropdownMenuItem(value: 'Spanish', child: Text('Spanish')),
              ],
              onChanged: (val) => setState(() => language = val ?? 'English'),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('Audio & Narration'),
            subtitle: const Text('Configure voice, speed, and reading options'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AudioNarrationSettings(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Cloud API'),
            subtitle: SelectableText(Env.sermonApiUrl),
          ),
          const Divider(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalDocumentScreen(
                          document: LegalDocuments.privacyPolicy,
                        ),
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.description_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalDocumentScreen(
                          document: LegalDocuments.terms,
                        ),
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'About The Word App',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LegalDocumentScreen(
                          document: LegalDocuments.about,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'The Word App • Powered by LOGOS',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white54,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Image.asset(
                    AppBranding.logoAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox.shrink(),
                  ),
                ),
                Text(
                  AppBranding.appName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppBranding.tagline,
                ),
                const SizedBox(height: 16),
                Text(
                  AppBranding.poweredBy,
                  style: const TextStyle(
                    color: Color(0xFF9B6DFF),
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  AppBranding.footer,
                  style: TextStyle(
                    color: applyOpacity(Colors.white, 0.5),
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(title),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
