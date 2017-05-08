# Duplex.Applications.Transport

## About

This application offers extended transport control for Renoise

     _______ _______ ______ ______ ______ ______ ________ _______
    |       |       |      |      |      |      |        |       |
    |  |◄   |   ►   |  ►|  | ∞/═  |  ■   |  ●   |   ↓    |   ∆   |
    | Prev  | Play  | Next | Loop | Stop | Edit | Follow | Metro |
    |_______|_______|______|______|______|______|________|_______|
     _______________ ______ ______ ______
    |               |      |      |      |
    |   01:04.25    |  +   | 95.2 |  -   |
    |  Song playpos | BPM  | BPM  | BPM  |
    |_______________|______|______|______|

## Available mappings

| Name       | Description   |
| -----------|---------------|  
|`edit_mode`|Transport: Toggle edit-mode|  
|`metronome_toggle`|Transport: Toggle Metronome on/off|  
|`start_playback`|Transport: Start playback|  
|`follow_player`|Transport: Toggle play-follow mode|  
|`block_loop`|Transport: Toggle block-loop mode|  
|`stop_playback`|Transport: Stop playback|  
|`loop_pattern`|Transport: Toggle pattern looping|  
|`bpm_display`|Transport: Display current BPM|  
|`songpos_display`|Transport: Display song-position|  
|`bpm_increase`|Transport: Increase BPM|  
|`bpm_decrease`|Transport: Decrease BPM|  
|`goto_previous`|Transport: Goto previous pattern/block|  
|`goto_next`|Transport: Goto next pattern/block|  

## Default options 

> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`pattern_play`|When play is pressed, choose an action|  
|`pattern_stop`|When stop is pressed *twice*, choose an action|  
|`pattern_switch`|Choose how next/previous buttons will work|  
|`jump_mode`|Choose between standard pattern or optional<br>hybrid pattern/block-loop control |  

## Default palette 

> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`loop_block_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|═|true|  
|`edit_mode_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|●|false|  
|`bpm_decrease_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|-|true|  
|`loop_pattern_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#80FF40; color: black">0x80,0xFF,0x40</div>|∞|true|  
|`bpm_decrease_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|-|false|  
|`bpm_increase_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|+|true|  
|`playing_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  
|`playing_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`stop_playback_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|□|true|  
|`loop_pattern_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|∞|false|  
|`prev_patt_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>||◄|true|  
|`stop_playback_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|■|false|  
|`edit_mode_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FF4040; color: white">0xFF,0x40,0x40</div>|●|true|  
|`prev_patt_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#808080; color: white">0x80,0x80,0x80</div>||◄|false|  
|`bpm_increase_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|+|false|  
|`loop_block_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|═|false|  
|`follow_player_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#40FF40; color: white">0x40,0xFF,0x40</div>|↓|true|  
|`metronome_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|∆|false|  
|`next_patt_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#808080; color: white">0x80,0x80,0x80</div>|►||false|  
|`follow_player_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|↓|false|  
|`next_patt_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►||false|  
|`next_patt_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►||true|  
|`metronome_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#808080; color: white">0x80,0x80,0x80</div>|∆|true|  
|`prev_patt_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>||◄|false|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries

0.98  
- New mapping: "metronome_toggle", minor optimizations

0.96  
- Fixed: Option "pattern_switch" didn't switch instantly

0.92  
- New option: "stop playback" (playback toggle button)

0.91  
- Fixed: always turn off "start" when hitting "stop"

0.90  
- Follow player option

0.81  
- First release
