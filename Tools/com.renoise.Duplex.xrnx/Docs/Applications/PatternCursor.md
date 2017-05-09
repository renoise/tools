# Duplex.Applications.PatternCursor

< Back to [Applications](../Applications.md)

## About

PatternCursor allows you to navigate between lines in the pattern editor.

## Available mappings
  

| Name       | Description   |
| -----------|---------------|  
|`prev_line_editstep`|PatternCursor: previous line (editstep)|  
|`next_line_editstep`|PatternCursor: next line (editstep)|  
|`set_line`|PatternCursor: set selected line|  
|`next_line`|PatternCursor: next line|  
|`prev_line`|PatternCursor: previous line|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`wrap_mode`|Whether to allow continuous movement between patterns or not|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`line_up`||▲|nil|  
|`disabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>||false|  
|`line_down`||▼|nil|  
|`enabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FF8080; color: black">0xFF,0x80,0x80</div>||true|  
|`editstep_down`||▼e|nil|  
|`editstep_up`||▲e|nil|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries

0.99.3
  - First release
