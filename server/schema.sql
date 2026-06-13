-- Simple Bible App schema (PostgreSQL)
-- Saved for a clean reset/reimport workflow.

CREATE TABLE IF NOT EXISTS verses (
  id SERIAL PRIMARY KEY,
  translation VARCHAR(16) NOT NULL,
  book_id VARCHAR(32) NOT NULL,
  book VARCHAR(64) NOT NULL,
  chapter INTEGER NOT NULL,
  verse INTEGER NOT NULL,
  text TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc'),
  CONSTRAINT uq_verse_ref UNIQUE (translation, book_id, chapter, verse)
);

CREATE INDEX IF NOT EXISTS ix_verses_translation_book_chapter
  ON verses (translation, book_id, chapter);

CREATE INDEX IF NOT EXISTS ix_verses_translation_chapter_verse
  ON verses (translation, chapter, verse);

CREATE TABLE IF NOT EXISTS commentary (
  id SERIAL PRIMARY KEY,
  verse_id INTEGER NOT NULL REFERENCES verses(id) ON DELETE CASCADE,
  language VARCHAR(16) NOT NULL DEFAULT 'english',
  style VARCHAR(32) NOT NULL DEFAULT 'simple',
  model VARCHAR(128) NOT NULL DEFAULT '',
  text TEXT NOT NULL,
  payload_json TEXT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc'),
  CONSTRAINT uq_commentary_verse_style_lang UNIQUE (verse_id, style, language)
);

CREATE INDEX IF NOT EXISTS ix_commentary_verse_id
  ON commentary (verse_id);
