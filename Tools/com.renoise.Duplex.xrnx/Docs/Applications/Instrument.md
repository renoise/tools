# Duplex.Applications.Instrument

< Back to [Applications](../Applications.md)

## About

This application can control certain properties of the selected instrument

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`next_scale`|Instrument: select the next harmonic scale|  
|`label_scale`|Instrument: display name of current scale|  
|`set_key`|Instrument: select the harmonic key|  
|`prev_scale`|Instrument: select the previous harmonic scale|  

## Default options 
  
*This application has no options.*  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`scale_prev_enabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|-≣|true|  
|`scale_prev_disabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|-≣|false|  
|`key_select_disabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`scale_next_disabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|+≣|false|  
|`key_select_enabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>||true|  
|`scale_next_enabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|+≣|true|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries

0.99.3
  - First release



