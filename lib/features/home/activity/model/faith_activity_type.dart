/// All seven faith activity types tracked by the weekly rhythm ring.
///
/// The four "legacy" types (bibleReading, devotional, sermon, saved) are
/// derived from existing repositories at calculation time.
///
/// The three "new" types (dailyVerse, promise, scriptureMemory) are persisted
/// by [FaithActivityRepository] because no prior storage existed for them.
enum FaithActivityType {
  bibleReading,
  devotional,
  dailyVerse,
  promise,
  scriptureMemory,
  sermon,
  saved,
}
