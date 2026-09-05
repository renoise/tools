# Changelog

## 1.11

### Fixes
- **Similarity search now works on Windows**: Sononym answered every search launched from Renoise with `Indexing error - Reason: Unable to resolve location`. The temporary sample file was passed with forward slashes (`C:/Users/.../Renoise_TmpFile.flac`), which Sononym's crawler cannot resolve. Arguments handed to the Sononym executable are now converted to native separators (`App.native_path()`); the same applies to Browse Folder in Sononym.
- **Quoted the search argument**: the temp file path was passed unquoted, so a user or temp folder containing a space broke the launch.
- **"Detect" applied nothing when several Sononym versions were installed**: with 2+ versions the button only populated the dropdown and relied on its notifier. A popup does not fire its notifier when the picked index is already the current one, and it starts at index 1 - so choosing the newest version, the obvious choice, silently left ConfigPath unset and the tool stuck on "invalid paths". Detect now applies the newest version immediately and keeps the dropdown for picking an older one.
- **"Open Path" crashed when ConfigPath was unset**: `App.lua:1521: attempt to concatenate local 'directory_path' (a nil value)`, which Renoise reports as the tool failing in one of its notifiers. Empty and non-matching paths are now reported in the status bar, and both unix and windows separators are accepted. The Linux branch of the same function assigned its command to `os_name` instead of `command`, so Open Path threw there too.
- **A Sononym update no longer breaks the configuration**: Sononym keeps `query.json` in a version-named folder, so `.../Sononym/1.6.2/query.json` becomes `.../Sononym/1.6.14/query.json` as soon as Sononym updates itself. The tool was left pointing at a file that no longer existed and simply reported "invalid paths". It now adopts the newest version it can find and says which one in the status bar.
- **AppPath and ConfigPath are written to disk when set**, rather than only being held in memory until Renoise shuts down cleanly.

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
