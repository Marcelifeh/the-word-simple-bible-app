# Implementation Plan - Merge Daily Verse & Prayer

The goal is to merge the "Daily Verse" and "Daily Prayer" features back into a single screen, ensuring both update daily based on the calendar date.

## Proposed Changes

### Feature: Daily Verse & Prayer (Merged)
#### [MODIFY] [daily_verse_screen.dart](file:///c:/Users/hp/The_word_simple_bible_app/lib/features/daily_verse/view/daily_verse_screen.dart)
- Re-add the `static const prayers` list.
- Re-add logic to pick a daily prayer in `_loadVerse` or a parallel method, using the date as a seed.
- Re-add the UI section at the bottom of the screen to display the selected prayer.
- **Critical**: Preserve `WidgetsBindingObserver` logic to refresh both verse and prayer when the app resumes.

### UI & Navigation
#### [MODIFY] [home_screen.dart](file:///c:/Users/hp/The_word_simple_bible_app/lib/features/home/view/home_screen.dart)
- Remove the "Daily Prayer" button from the Grid.
- Update the "Daily Verse" card title/subtitle to reflect it contains both (e.g., "Daily Inspiration" or just keep "Daily Verse" and let user discover prayer inside).

### Cleanup
#### [DELETE] [daily_prayer_screen.dart](file:///c:/Users/hp/The_word_simple_bible_app/lib/features/daily_verse/view/daily_prayer_screen.dart)
- Delete the now redundant file.

## Verification Plan

### Manual Verification
1.  **Home Screen**:
    - Verify "Daily Prayer" button is gone.
    - Tap "Daily Verse".
2.  **Merged Screen**:
    - Verify it shows the Verse.
    - Verify it shows the Prayer below the verse.
    - Verify Back button works.
3.  **Daily Update**:
    - Background/Resume app and ensure content refreshes (simulated by logic check or changing system time if possible).
