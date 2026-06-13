enum NarrationStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

enum NarrationSourceType {
  bible,
  devotional,
  tract,
  prayer,
  sermon,
  note,
}

enum NarrationMode {
  reading,
  devotional, // guided devotional experience
  prayer, // slow, reverent
  meditation, // deeply unhurried
  sermon, // authoritative, natural speech
  children, // warm, elevated pitch for Bible stories
}

enum NarrationMood {
  calm,
  reflective,
  teaching,
  energetic,
}
