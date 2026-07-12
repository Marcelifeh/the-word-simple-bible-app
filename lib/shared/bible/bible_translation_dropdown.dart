import 'package:flutter/material.dart';

import '../../domain/entities/bible_translation.dart';

class BibleTranslationDropdown extends StatelessWidget {
  const BibleTranslationDropdown({
    super.key,
    required this.translation,
    required this.onChanged,
    this.foregroundColor,
    this.textStyle,
    this.isDense = true,
  });

  final BibleTranslation translation;
  final ValueChanged<BibleTranslation> onChanged;
  final Color? foregroundColor;
  final TextStyle? textStyle;
  final bool isDense;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<BibleTranslation>(
        value: translation,
        isDense: isDense,
        style: textStyle,
        icon: Icon(
          Icons.arrow_drop_down,
          size: 16,
          color: foregroundColor,
        ),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
        items: BibleTranslation.values
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item.label,
                  style: foregroundColor == null
                      ? null
                      : TextStyle(color: foregroundColor),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}
