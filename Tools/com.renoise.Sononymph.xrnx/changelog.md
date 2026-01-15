# Changelog

## 1.10

### New Features
- **Sample Navigator Enhancement**: Added "Load Selected Sample to Selected Slot" function specifically for Sample Navigator context
- **Targeted Sample Loading**: Load samples from Sononym directly into the currently selected sample slot without creating new instruments
- **Smart Slot Loading**: Preserves slice markers and settings when loading into existing sample slots
- **Menu Entry**: New Sample Navigator menu entry for direct slot loading functionality

### Technical Improvements
- Enhanced sample loading with `load_selected_sample_to_selected_slot()` function
- Improved error handling for sample slot selection validation
- Better user feedback with specific status messages for slot loading operations

## 1.05

### Major Changes
- Removed vLib and xLib dependencies - dialog now uses native Renoise ViewBuilder to show an almost identical dialog. (Cleaned up 101 unused library files, making the tool much lighter)
- About dialog removed - moved documentation and forum buttons to main dialog
- Removed duplicate "Open ConfigPath" button for cleaner UI
- Made "Autostart" text bold to match other labels
- Fixed startup crash caused by DocumentNode constructor error
- Removed AppPrefs.lua from the codebase, as it's consolidated into main.lua.
- Added menu entries in 6 different contexts (Instrument Box, Sample Editor, Sample Navigator, Main Menu)
- Auto-transfer can now create new instruments or sample slots instead of just overwriting
- Added functions for loading samples from Sononym with or without prompts
- Added folder browsing in Sononym and direct app launching
- Smart version detection across Windows, macOS, and Linux

### MIDI Mappings & Keybindings
- `Sononymph:Toggle Auto-Transfer [Trigger]` MIDI mapping and keybinding
- `Sononymph:Load Selected Sample from Sononym` with prompt and no-prompt versions (MIDI + keybindings)
- `Global:Sononymph:Open Sononymph Dialog...` keybinding

### Interface Improvements
- Launch button to start Sononym directly
- Browse Path button to select folders in Sononym
- Open Path button on ConfigPath row for easy file access
- Dropdown for Sononym version selection instead of using the first one found
- Auto-transfer preserves sample slices and automatically switches to Sample Editor
- First-time setup detects paths automatically without nagging the user

### Linux Support
- Proper ConfigPath detection for version-specific files like `/home/user/.config/Sononym/1.5.6/query.json`
- AppPath detection using `which`, `command -v`, and common install locations
- Fixed crashes when `cFilesystem.get_user_folder()` wasn't implemented
- Better error messages when Sononym isn't installed or configured
- Fallback detection for non-standard installations

### Bug Fixes
- Fixed crash in `parse_config()` when closing nil file handles
- Fixed Linux crashes when error messages were nil
- ConfigPath detection now sets full paths instead of just version names
- Better JSON config validation and error handling
- Detect button behavior improved for single vs multiple version scenarios

## 1.0

- Add `changelog.md`
- `cLib.require()`, use for avoiding circular dependencies
- `cTable.is_indexed()`: check if table keys are exclusively numerical
- Add `cPersistence`, a replacement for `cDocument` (now deprecated)
- `cReflection`: several fixes/changes:
  - `get_object_info()`: support objects without properties
  - `get_object_info()`: return table instead of string
  - `get_object_properties()`: hide implementation details
  - `is_standard_type()`: accept any value (previously passed the 'type')
  - `is_serializable_type()`: new method
  
## 0.5

- Standalone version
