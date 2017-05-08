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
|`edit_mode`|Transport: Toggle edit-mode
|`metronome_toggle`|Transport: Toggle Metronome on/off|  
|`start_playback`|Transport: Start playback
|`follow_player`|Transport: Toggle play-follow mode
|`block_loop`|Transport: Toggle block-loop mode
|`stop_playback`|Transport: Stop playback
|`loop_pattern`|Transport: Toggle pattern looping
|`bpm_display`|Transport: Display current BPM|  
|`songpos_display`|Transport: Display song-position|  
|`bpm_increase`|Transport: Increase BPM|  
|`bpm_decrease`|Transport: Decrease BPM|  
|`goto_previous`|Transport: Goto previous pattern/block
|`goto_next`|Transport: Goto next pattern/block

## Available options

| Name       | Description   |
| -----------|---------------|
|`pattern_play`|When play is pressed, choose an action|  
|`pattern_stop`|When stop is pressed *twice*, choose an action|  
|`pattern_switch`|Choose how next/previous buttons will work|  
|`jump_mode`|Choose between standard pattern or hybrid pattern/block-loop control |  

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
