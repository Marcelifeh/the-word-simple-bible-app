import '../../domain/entities/book.dart';

class BookCatalog {
  static const books = <Book>[
    Book(
        id: 'genesis',
        name: 'Genesis',
        testament: Testament.old,
        chapterCount: 50),
    Book(
        id: 'exodus',
        name: 'Exodus',
        testament: Testament.old,
        chapterCount: 40),
    Book(
        id: 'leviticus',
        name: 'Leviticus',
        testament: Testament.old,
        chapterCount: 27),
    Book(
        id: 'numbers',
        name: 'Numbers',
        testament: Testament.old,
        chapterCount: 36),
    Book(
        id: 'deuteronomy',
        name: 'Deuteronomy',
        testament: Testament.old,
        chapterCount: 34),
    Book(
        id: 'joshua',
        name: 'Joshua',
        testament: Testament.old,
        chapterCount: 24),
    Book(
        id: 'judges',
        name: 'Judges',
        testament: Testament.old,
        chapterCount: 21),
    Book(id: 'ruth', name: 'Ruth', testament: Testament.old, chapterCount: 4),
    Book(
        id: '1_samuel',
        name: '1 Samuel',
        testament: Testament.old,
        chapterCount: 31),
    Book(
        id: '2_samuel',
        name: '2 Samuel',
        testament: Testament.old,
        chapterCount: 24),
    Book(
        id: '1_kings',
        name: '1 Kings',
        testament: Testament.old,
        chapterCount: 22),
    Book(
        id: '2_kings',
        name: '2 Kings',
        testament: Testament.old,
        chapterCount: 25),
    Book(
        id: '1_chronicles',
        name: '1 Chronicles',
        testament: Testament.old,
        chapterCount: 29),
    Book(
        id: '2_chronicles',
        name: '2 Chronicles',
        testament: Testament.old,
        chapterCount: 36),
    Book(id: 'ezra', name: 'Ezra', testament: Testament.old, chapterCount: 10),
    Book(
        id: 'nehemiah',
        name: 'Nehemiah',
        testament: Testament.old,
        chapterCount: 13),
    Book(
        id: 'esther',
        name: 'Esther',
        testament: Testament.old,
        chapterCount: 10),
    Book(id: 'job', name: 'Job', testament: Testament.old, chapterCount: 42),
    Book(
        id: 'psalms',
        name: 'Psalms',
        testament: Testament.old,
        chapterCount: 150),
    Book(
        id: 'proverbs',
        name: 'Proverbs',
        testament: Testament.old,
        chapterCount: 31),
    Book(
        id: 'ecclesiastes',
        name: 'Ecclesiastes',
        testament: Testament.old,
        chapterCount: 12),
    Book(
        id: 'song_of_songs',
        name: 'Song of Songs',
        testament: Testament.old,
        chapterCount: 8),
    Book(
        id: 'isaiah',
        name: 'Isaiah',
        testament: Testament.old,
        chapterCount: 66),
    Book(
        id: 'jeremiah',
        name: 'Jeremiah',
        testament: Testament.old,
        chapterCount: 52),
    Book(
        id: 'lamentations',
        name: 'Lamentations',
        testament: Testament.old,
        chapterCount: 5),
    Book(
        id: 'ezekiel',
        name: 'Ezekiel',
        testament: Testament.old,
        chapterCount: 48),
    Book(
        id: 'daniel',
        name: 'Daniel',
        testament: Testament.old,
        chapterCount: 12),
    Book(
        id: 'hosea', name: 'Hosea', testament: Testament.old, chapterCount: 14),
    Book(id: 'joel', name: 'Joel', testament: Testament.old, chapterCount: 3),
    Book(id: 'amos', name: 'Amos', testament: Testament.old, chapterCount: 9),
    Book(
        id: 'obadiah',
        name: 'Obadiah',
        testament: Testament.old,
        chapterCount: 1),
    Book(id: 'jonah', name: 'Jonah', testament: Testament.old, chapterCount: 4),
    Book(id: 'micah', name: 'Micah', testament: Testament.old, chapterCount: 7),
    Book(id: 'nahum', name: 'Nahum', testament: Testament.old, chapterCount: 3),
    Book(
        id: 'habakkuk',
        name: 'Habakkuk',
        testament: Testament.old,
        chapterCount: 3),
    Book(
        id: 'zephaniah',
        name: 'Zephaniah',
        testament: Testament.old,
        chapterCount: 3),
    Book(
        id: 'haggai',
        name: 'Haggai',
        testament: Testament.old,
        chapterCount: 2),
    Book(
        id: 'zechariah',
        name: 'Zechariah',
        testament: Testament.old,
        chapterCount: 14),
    Book(
        id: 'malachi',
        name: 'Malachi',
        testament: Testament.old,
        chapterCount: 4),
    Book(
        id: 'matthew',
        name: 'Matthew',
        testament: Testament.newTestament,
        chapterCount: 28),
    Book(
        id: 'mark',
        name: 'Mark',
        testament: Testament.newTestament,
        chapterCount: 16),
    Book(
        id: 'luke',
        name: 'Luke',
        testament: Testament.newTestament,
        chapterCount: 24),
    Book(
        id: 'john',
        name: 'John',
        testament: Testament.newTestament,
        chapterCount: 21),
    Book(
        id: 'acts',
        name: 'Acts',
        testament: Testament.newTestament,
        chapterCount: 28),
    Book(
        id: 'romans',
        name: 'Romans',
        testament: Testament.newTestament,
        chapterCount: 16),
    Book(
        id: '1_corinthians',
        name: '1 Corinthians',
        testament: Testament.newTestament,
        chapterCount: 16),
    Book(
        id: '2_corinthians',
        name: '2 Corinthians',
        testament: Testament.newTestament,
        chapterCount: 13),
    Book(
        id: 'galatians',
        name: 'Galatians',
        testament: Testament.newTestament,
        chapterCount: 6),
    Book(
        id: 'ephesians',
        name: 'Ephesians',
        testament: Testament.newTestament,
        chapterCount: 6),
    Book(
        id: 'philippians',
        name: 'Philippians',
        testament: Testament.newTestament,
        chapterCount: 4),
    Book(
        id: 'colossians',
        name: 'Colossians',
        testament: Testament.newTestament,
        chapterCount: 4),
    Book(
        id: '1_thessalonians',
        name: '1 Thessalonians',
        testament: Testament.newTestament,
        chapterCount: 5),
    Book(
        id: '2_thessalonians',
        name: '2 Thessalonians',
        testament: Testament.newTestament,
        chapterCount: 3),
    Book(
        id: '1_timothy',
        name: '1 Timothy',
        testament: Testament.newTestament,
        chapterCount: 6),
    Book(
        id: '2_timothy',
        name: '2 Timothy',
        testament: Testament.newTestament,
        chapterCount: 4),
    Book(
        id: 'titus',
        name: 'Titus',
        testament: Testament.newTestament,
        chapterCount: 3),
    Book(
        id: 'philemon',
        name: 'Philemon',
        testament: Testament.newTestament,
        chapterCount: 1),
    Book(
        id: 'hebrews',
        name: 'Hebrews',
        testament: Testament.newTestament,
        chapterCount: 13),
    Book(
        id: 'james',
        name: 'James',
        testament: Testament.newTestament,
        chapterCount: 5),
    Book(
        id: '1_peter',
        name: '1 Peter',
        testament: Testament.newTestament,
        chapterCount: 5),
    Book(
        id: '2_peter',
        name: '2 Peter',
        testament: Testament.newTestament,
        chapterCount: 3),
    Book(
        id: '1_john',
        name: '1 John',
        testament: Testament.newTestament,
        chapterCount: 5),
    Book(
        id: '2_john',
        name: '2 John',
        testament: Testament.newTestament,
        chapterCount: 1),
    Book(
        id: '3_john',
        name: '3 John',
        testament: Testament.newTestament,
        chapterCount: 1),
    Book(
        id: 'jude',
        name: 'Jude',
        testament: Testament.newTestament,
        chapterCount: 1),
    Book(
        id: 'revelation',
        name: 'Revelation',
        testament: Testament.newTestament,
        chapterCount: 22),
  ];

  static Book byId(String id) => books.firstWhere((b) => b.id == id);
}
