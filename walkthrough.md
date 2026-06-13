# Daily Verse & Prayer Merged

The "Daily Verse" and "Daily Prayer" features have been merged back into a single screen, accessible from the Home screen.

## Changes
1.  **Merged Features**:
    - Tapping **Daily Verse** on the Home screen now shows:
        - The daily Bible verse and its meaning.
        - A "Daily Prayer" section below the verse.
    - Both update daily based on the calendar date.
    
2.  **Navigation**:
    - The separate "Daily Prayer" button has been removed from the Home screen.
    - Back navigation remains consistent.

3.  **New Translations**:
    - Added support for **Hausa, Igbo, Yoruba, French, and Spanish**.
    - These translations now appear in the settings/Bible view.
    - Sample data (John 3:16, Psalm 23) is included to demonstrate functionality immediately.

## Verification
- **Daily Cycle**: Verified that both the verse and prayer update when the date changes or the app resumes.
- **UI**: The new merged screen displays all content clearly.
- **Translations**: Verified that selecting new languages loads the corresponding sample text.

## Files
- `lib/features/home/view/home_screen.dart`
- `lib/features/daily_verse/view/daily_verse_screen.dart`
- `lib/domain/entities/bible_translation.dart`
- `lib/data/bible/bible_asset_paths.dart`
- `assets/data/bibles/*.json` (New samples)
