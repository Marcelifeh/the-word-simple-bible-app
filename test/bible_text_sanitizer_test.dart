import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/core/utils/bible_text_sanitizer.dart';

void main() {
  group('BibleTextSanitizer', () {
    test('removes Psalm 119 Hebrew acrostic markers with letter names', () {
      expect(
        BibleTextSanitizer.clean(
          'I will keep thy statutes: O forsake me not utterly. ב BETH.',
        ),
        'I will keep thy statutes: O forsake me not utterly',
      );
      expect(
        BibleTextSanitizer.clean(
          'Dukan maganganunka gaskiya ne. ש Sin da Shin',
        ),
        'Dukan maganganunka gaskiya ne',
      );
      expect(
        BibleTextSanitizer.clean(
          'Okwu gị niile bụ eziokwu. ש Sin na Shin',
        ),
        'Okwu gị niile bụ eziokwu',
      );
    });
  });
}
