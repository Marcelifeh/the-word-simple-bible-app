import 'package:flutter_test/flutter_test.dart';
import 'package:simple_bible_app/data/search/search_relevance.dart';

void main() {
  test('exact phrase outranks unrelated shared terms', () {
    const query = 'for God so loved the world';
    final exact = SearchRelevance.score(query,
        'For God so loved the world, that he gave his only begotten Son');
    final unrelated = SearchRelevance.score(query,
        'Where is the wise? Has not God made foolish the wisdom of this world?');
    expect(exact, greaterThan(200));
    expect(unrelated, 0);
  });

  test('major keywords support alternative prepositions', () {
    expect(SearchRelevance.score('precept upon precept',
        'For precept must be upon precept, precept upon precept'), greaterThan(0));
    expect(SearchRelevance.score('precept on precept',
        'For precept must be upon precept, precept upon precept'), greaterThan(0));
  });

  test('negation remains a meaningful keyword', () {
    expect(SearchRelevance.important('do not fear'), contains('not'));
  });
}
