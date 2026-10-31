import 'package:flutter/material.dart';

import '../model/daily_altar_feature.dart';

/// Development-only shell for My Daily Altar.
///
/// MDA-1 does not register this screen in production navigation.
/// It exists only so the module has an independently testable UI boundary.
class DailyAltarPlaceholderScreen extends StatelessWidget {
  const DailyAltarPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(DailyAltarFeature.title),
      ),
      body: const SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  DailyAltarFeature.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  DailyAltarFeature.subtitle,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  'Feature foundation ready.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
