import 'dart:typed_data';

import 'package:flutter/material.dart';

List<WordStudioCustomBackground> replaceWordStudioCustomBackground(
  Iterable<WordStudioCustomBackground> backgrounds,
  WordStudioCustomBackground replacement,
) {
  return <WordStudioCustomBackground>[
    for (final background in backgrounds)
      if (background.id == replacement.id) replacement else background,
  ];
}

class WordStudioCustomBackground {
  const WordStudioCustomBackground({
    required this.id,
    required this.createdAtUtc,
    required this.displayName,
    this.filePath,
    this.bytes,
    this.mimeType,
    this.overlayOpacity = 0.35,
    this.scale = 1,
    this.fit = BoxFit.cover,
    this.alignmentX = 0,
    this.alignmentY = 0,
  });

  final String id;
  final DateTime createdAtUtc;
  final String displayName;
  final String? filePath;
  final Uint8List? bytes;
  final String? mimeType;
  final double overlayOpacity;
  final double scale;
  final BoxFit fit;
  final double alignmentX;
  final double alignmentY;

  bool get hasImage => bytes != null && bytes!.isNotEmpty;

  Alignment get alignment => Alignment(alignmentX, alignmentY);

  WordStudioCustomBackground copyWith({
    String? displayName,
    String? filePath,
    Uint8List? bytes,
    String? mimeType,
    double? overlayOpacity,
    double? scale,
    BoxFit? fit,
    double? alignmentX,
    double? alignmentY,
  }) {
    return WordStudioCustomBackground(
      id: id,
      createdAtUtc: createdAtUtc,
      displayName: displayName ?? this.displayName,
      filePath: filePath ?? this.filePath,
      bytes: bytes ?? this.bytes,
      mimeType: mimeType ?? this.mimeType,
      overlayOpacity: (overlayOpacity ?? this.overlayOpacity).clamp(0.0, 0.8),
      scale: (scale ?? this.scale).clamp(1.0, 3.0),
      fit: fit ?? this.fit,
      alignmentX: (alignmentX ?? this.alignmentX).clamp(-1.0, 1.0),
      alignmentY: (alignmentY ?? this.alignmentY).clamp(-1.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'createdAtUtc': createdAtUtc.toUtc().toIso8601String(),
        'displayName': displayName,
        'filePath': filePath,
        'mimeType': mimeType,
        'overlayOpacity': overlayOpacity,
        'scale': scale,
        'fit': fit.name,
        'alignmentX': alignmentX,
        'alignmentY': alignmentY,
      };

  factory WordStudioCustomBackground.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final createdAtUtc = DateTime.tryParse(
      json['createdAtUtc'] as String? ?? '',
    );
    if (id == null || id.isEmpty || createdAtUtc == null) {
      throw const FormatException('Invalid Word Studio background');
    }

    return WordStudioCustomBackground(
      id: id,
      createdAtUtc: createdAtUtc.toUtc(),
      displayName: (json['displayName'] as String?)?.trim().isNotEmpty == true
          ? (json['displayName'] as String).trim()
          : 'My background',
      filePath: json['filePath'] as String?,
      mimeType: json['mimeType'] as String?,
      overlayOpacity: _readDouble(json['overlayOpacity'], 0.35, 0, 0.8),
      scale: _readDouble(json['scale'], 1, 1, 3),
      fit: _readFit(json['fit'] as String?),
      alignmentX: _readDouble(json['alignmentX'], 0, -1, 1),
      alignmentY: _readDouble(json['alignmentY'], 0, -1, 1),
    );
  }

  static BoxFit _readFit(String? value) {
    return switch (value) {
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      _ => BoxFit.cover,
    };
  }

  static double _readDouble(
    dynamic value,
    double fallback,
    double min,
    double max,
  ) {
    if (value is! num || !value.toDouble().isFinite) return fallback;
    return value.toDouble().clamp(min, max);
  }
}
