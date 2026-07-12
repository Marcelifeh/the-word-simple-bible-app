class SermonOutline {
  final String title;
  final String mainText;
  final String introduction;
  final List<String> mainPoints;
  final List<String> supportingScriptures;
  final String lifeApplication;
  final String conclusion;
  final String closingPrayer;

  const SermonOutline({
    required this.title,
    required this.mainText,
    required this.introduction,
    required this.mainPoints,
    required this.supportingScriptures,
    required this.lifeApplication,
    required this.conclusion,
    required this.closingPrayer,
  });

  bool get hasContent =>
      title.trim().isNotEmpty ||
      mainText.trim().isNotEmpty ||
      introduction.trim().isNotEmpty ||
      mainPoints.isNotEmpty ||
      supportingScriptures.isNotEmpty ||
      lifeApplication.trim().isNotEmpty ||
      conclusion.trim().isNotEmpty ||
      closingPrayer.trim().isNotEmpty;

  factory SermonOutline.fromJson(Map<String, dynamic> json) {
    return SermonOutline(
      title: json['title']?.toString() ?? '',
      mainText: json['mainText']?.toString() ?? '',
      introduction: json['introduction']?.toString() ?? '',
      mainPoints: _stringList(json['mainPoints']),
      supportingScriptures: _stringList(json['supportingScriptures']),
      lifeApplication: json['lifeApplication']?.toString() ?? '',
      conclusion: json['conclusion']?.toString() ?? '',
      closingPrayer: json['closingPrayer']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'mainText': mainText,
      'introduction': introduction,
      'mainPoints': mainPoints,
      'supportingScriptures': supportingScriptures,
      'lifeApplication': lifeApplication,
      'conclusion': conclusion,
      'closingPrayer': closingPrayer,
    };
  }

  String toShareText() {
    return '''
$title

Main Text:
$mainText

Introduction:
$introduction

Main Points:
${mainPoints.map((point) => '- $point').join('\n')}

Supporting Scriptures:
${supportingScriptures.map((scripture) => '- $scripture').join('\n')}

Life Application:
$lifeApplication

Conclusion:
$conclusion

Closing Prayer:
$closingPrayer
'''
        .trim();
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
