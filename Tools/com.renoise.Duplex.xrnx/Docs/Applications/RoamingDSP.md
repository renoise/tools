# Duplex.RoamingDSP

## About

This class offers 'roaming 'control of a DSP device, which means that you can lock onto a specific type of device, and navigate between similar devices.

RoamingDSP is not an application in itself, but rather, a baseclass that other applications can choose to extend. 

## How it works

The class can target any device that has been selected in Renoise, freely roaming the tracks. If the lock button starts to blink slowly, it is to remind you that the application is currently 'homeless', has no matching device to control. 

Opposite to the "free-roaming mode" we have the "locked mode" which will lock to a single device. The locked mode can either be set by being mapped to a button, or via the options dialog. In either case, the application will 'tag' the device with a unique name. 

To complement the "lock" button, we also have a "focus" button. This button brings focus back to the locked device, whenever you have (manually) selected an un-locked device.

Finally, we can navigate between devices by using the 'next' and 'previous' buttons. In case we have locked to a device, previous/next will "transfer" the lock to that device.

## Available mappings 

| Name          | Description   |
| ------------- |---------------|
|`next_device`|RoamingDSP: Next device|  
|`prev_device`|RoamingDSP: Previous device|  

## Available options 

| Name          | Description   |
| ------------- |---------------|
|`locked`|Disable if you want to follow the currently selected device |  
|`record_method`|Determine how to record automation|  
|`follow_pos`|Follow the selected device in the DSP chain|  

## Changelog

0.98
- First release


