import 'package:flutter/material.dart';

class TractShareTheme {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final Color textColor;
  final Color accentColor;
  final String fontFamily;
  final bool dark;

  // Custom visual enhancement decoration flags
  final bool useGoldBorder;
  final bool useParchmentStyle;
  final bool useClouds;
  final bool useStars;
  final bool useFireGlow;

  const TractShareTheme({
    required this.id,
    required this.name,
    required this.gradientColors,
    required this.textColor,
    required this.accentColor,
    required this.fontFamily,
    required this.dark,
    this.useGoldBorder = false,
    this.useParchmentStyle = false,
    this.useClouds = false,
    this.useStars = false,
    this.useFireGlow = false,
  });
}

const List<TractShareTheme> tractThemes = [
  TractShareTheme(
    id: 'sunset',
    name: 'Sunset Glow',
    gradientColors: [
      Color(0xFF1E3C72),
      Color(0xFF2A5298),
      Color(0xFFE28743),
    ],
    textColor: Colors.white,
    accentColor: Color(0xFFFFD166),
    fontFamily: 'Poppins',
    dark: true,
  ),
  TractShareTheme(
    id: 'gold',
    name: 'Royal Gold',
    gradientColors: [
      Color(0xFF141414),
      Color(0xFF2A2208),
      Color(0xFF0F0E0A),
    ],
    textColor: Colors.white,
    accentColor: Color(0xFFFFD700),
    fontFamily: 'Poppins',
    dark: true,
    useGoldBorder: true,
  ),
  TractShareTheme(
    id: 'light',
    name: 'Minimal Clean',
    gradientColors: [
      Color(0xFFFBFBFB),
      Color(0xFFECEFF1),
    ],
    textColor: Color(0xFF263238),
    accentColor: Color(0xFF6C63FF),
    fontFamily: 'Poppins',
    dark: false,
  ),
  TractShareTheme(
    id: 'emerald',
    name: 'Emerald Grace',
    gradientColors: [
      Color(0xFF064E3B),
      Color(0xFF065F46),
      Color(0xFF047857),
    ],
    textColor: Colors.white,
    accentColor: Color(0xFFFDE047),
    fontFamily: 'Poppins',
    dark: true,
  ),
  TractShareTheme(
    id: 'midnight',
    name: 'Midnight Premium',
    gradientColors: [
      Color(0xFF0A0E17),
      Color(0xFF161E2E),
    ],
    textColor: Colors.white,
    accentColor: Color(0xFF38BDF8),
    fontFamily: 'Poppins',
    dark: true,
  ),
  TractShareTheme(
    id: 'lavender',
    name: 'Lavender Dream',
    gradientColors: [
      Color(0xFF4C1D95),
      Color(0xFF6D28D9),
      Color(0xFF8B5CF6),
    ],
    textColor: Colors.white,
    accentColor: Color(0xFFF472B6),
    fontFamily: 'Poppins',
    dark: true,
  ),
  TractShareTheme(
    id: 'parchment',
    name: 'Bible Paper',
    gradientColors: [
      Color(0xFFFDFBF7),
      Color(0xFFF5EFE6),
      Color(0xFFEAE3D2),
    ],
    textColor: Color(0xFF3C2F2F),
    accentColor: Color(0xFF8C6A5C),
    fontFamily: 'NotoSans',
    dark: false,
    useParchmentStyle: true,
  ),
  TractShareTheme(
    id: 'clouds',
    name: 'Heaven Light',
    gradientColors: [
      Color(0xFFE0F2FE),
      Color(0xFFBAE6FD),
      Color(0xFFF0F9FF),
    ],
    textColor: Color(0xFF0369A1),
    accentColor: Color(0xFF0284C7),
    fontFamily: 'Poppins',
    dark: false,
    useClouds: true,
  ),
  TractShareTheme(
    id: 'stars',
    name: 'Midnight Prayer',
    gradientColors: [
      Color(0xFF030712),
      Color(0xFF0B1528),
      Color(0xFF1E1E38),
    ],
    textColor: Colors.white,
    accentColor: Color(0xFFA5B4FC),
    fontFamily: 'NotoSans',
    dark: true,
    useStars: true,
  ),
  TractShareTheme(
    id: 'fire',
    name: 'Fire Revival',
    gradientColors: [
      Color(0xFF000000),
      Color(0xFF1E0A03),
      Color(0xFF450A0A),
    ],
    textColor: Colors.white,
    accentColor: Color(0xFFF97316),
    fontFamily: 'Poppins',
    dark: true,
    useFireGlow: true,
  ),
];
