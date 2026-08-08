# Play Store screenshots

The final screenshots are generated at `1080 x 1920` from real Samsung app
captures. The generator removes the Android status and navigation bars so that
personal notification icons are not included in public store artwork.

## Raw filenames

```text
01-home.jpg
02-bible-reader.png
03-devotional.jpg
04-logos-notes.png
05-scripture-memory.jpg
06-word-studio.jpg
```

## Build

From the repository root:

```powershell
.\tools\build_play_store_screenshots.ps1
```

Finished assets are written to `docs/play-store/screenshots/final/`.

## Play Console descriptions

1. The Word App home dashboard showing Daily Verse, Today's Promise, Bible,
   Search, and Reading Plan.
2. Luke 15 in the Bible reader with KJV translation controls and numbered
   verses.
3. A daily devotional titled Living Beyond Fear with Scripture Focus and
   reflection content.
4. LOGOS Notes displaying a saved sample sermon note titled Walking by Faith
   with Proverbs 3:5-6.
5. Scripture Memory showing two due verses and the controls for today's review.
6. Word Studio showing a six-slide gospel tract in a portrait canvas with
   download and share controls.
