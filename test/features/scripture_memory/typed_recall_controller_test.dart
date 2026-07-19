import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/features/scripture_memory/services/typed_recall_controller.dart';

void main() {
  test('long passages are divided into manageable phrases', () {
    final controller = TypedRecallController(
      expectedText: List.filled(
        45,
        'faith',
      ).join(' '),
      phraseWordLimit: 12,
    );

    expect(controller.phrases.length, greaterThan(1));
    expect(
      controller.phrases.every(
        (phrase) => phrase.split(RegExp(r'\s+')).length <= 12,
      ),
      isTrue,
    );
  });

  test('submitted phrases produce combined internal accuracy', () {
    final controller = TypedRecallController(
      expectedText: 'God is faithful. His mercy endures.',
    );

    controller.submit('God is faithful');
    controller.submit('His mercy endures');

    expect(controller.isComplete, isTrue);
    expect(controller.combinedAccuracy, 1);
  });
}
