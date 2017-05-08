# Duplex.Applications.TrackSelector

## About

The Duplex TrackSelector application allows you to select between tracks, including shortcuts for master & send tracks

## Available mappings 

| Name       | Description   |
| -----------|---------------|
|`next_column`|TrackSelector: Select next column|  
|`prev_column`|TrackSelector: Select previous column|  
|`next_page`|TrackSelector: Select next track-page|  
|`prev_page`|TrackSelector: Select previous track-page|  
|`next_track`|TrackSelector: Select next track|  
|`prev_track`|TrackSelector: Select previous track|  
|`select_track`|TrackSelector: Select active track|  
|`select_first`|TrackSelector: Select first track|  
|`select_master`|TrackSelector: Select master-track|  
|`select_sends`|TrackSelector: Select 1st send-track|  

## Available options

| Name       | Description   |
| -----------|---------------|
|`page_size`|Specify the step size when using paged navigation|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries

0.99.4 by Eran Dax Lonker
- New mappings: prev/next column

0.99.3
- All "pattern line mappings" has moved into 
  Duplex.Applications.PatternCursor

0.98.28
- New mappings: “next_track”,”prev_track” (UIButtons, replaces UISpinner)
- New mappings: “next_page”,”prev_page” (UIButtons, replaces UISpinner)
- FEATURE: Hold prev/next track to select first/last track
- New mappings: “next_line”,”prev_line” (UIButtons)
- New mappings: “line”(UISlider, replaces UISpinner)

0.98.21
- Fixed: application was updating display when stopped/paused

0.98  
- Deprecated UISpinner controls (exchanged with UIButtons)

0.97
- Allows to set focus to track by index, previous or next track
- Supports paged navigation features (previous/next, page size)
- Allows direct access to sequencer-track #1, master or send-track #1

0.96  
- First release

