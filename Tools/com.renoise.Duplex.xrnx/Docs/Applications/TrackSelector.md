# Duplex.Applications.TrackSelector

< Back to [Applications](../Applications.md)

## About

The Duplex TrackSelector application allows you to select between tracks, including shortcuts for master & send tracks

* Supports [paged navigation](../Concepts.md#paged-navigation)

## Available mappings

| Name       | Description   |
| -----------|---------------|  
|`prev_track`|TrackSelector: Select previous track|  
|`next_track`|TrackSelector: Select next track|  
|`select_track`|TrackSelector: Select active track|  
|`select_sends`|TrackSelector: Select 1st send-track|  
|`next_column`|TrackSelector: Select next column|  
|`select_first`|TrackSelector: Select first track|  
|`prev_page`|TrackSelector: Select previous track-page|  
|`select_master`|TrackSelector: Select master-track|  
|`next_page`|TrackSelector: Select next track-page|  
|`prev_column`|TrackSelector: Select previous column|  

## Default options 

> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`page_size`|Specify the step size when using paged navigation|  

## Default palette 

> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`track_send_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|S|true|  
|`track_master_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|M|true|  
|`track_next_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|»|true|  
|`column_next_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|›|true|  
|`column_prev_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|‹|true|  
|`track_next_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|»|false|  
|`track_send_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|S|false|  
|`select_device_back`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#404080; color: white">0x40,0x40,0x80</div>|▫|false|  
|`column_next_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|›|false|  
|`page_next_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|>|true|  
|`track_sequencer_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|T|true|  
|`page_next_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|>|false|  
|`page_prev_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|<|false|  
|`track_sequencer_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|T|false|  
|`page_prev_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|<|true|  
|`select_device_tip`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▪|true|  
|`column_prev_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|‹|false|  
|`track_master_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|M|false|  
|`track_prev_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|«|false|  
|`track_prev_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|«|true|  

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

