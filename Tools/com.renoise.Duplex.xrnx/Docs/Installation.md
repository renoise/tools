# Installation

The easiest way to install Duplex is by downloading the tool (.xrnx) from [tools.renoise.com](http://www.renoise.com/tools/duplex), and then install it by double-clicking or 
dragging the file onto the Renoise application.

Alternatively, you can get the latest version from github (see [Links and Resources](Resources.md)) 

## Post-installation steps

These steps are optional, but might provide a better experience. 

### Review your MIDI device preferences

Duplex recieves MIDI input directly from your devices, and these devices are not necessarily the same as the ones you've selected in the Renoise MIDI preferences - the tool has a completely independant input/output system.  
For this reason, you might want to consider disabling the device in Renoise preferences, or messages might arrive twice. 

This doesn't necessarily mean that you will loose your existing MIDI mappings - Duplex has a useful feature which allows you to pass 'unhandled' MIDI messages through to Renoise. Please [look here](Concepts.md#midi-thru--pass-unhandled-messages) for more details. 


### Enable the Renoise OSC Server 

The internal OSC server in Renoise will allow Duplex to trigger notes and send MIDI messages to Renoise. Therefore, it needs to be enabled before applications such as Keyboard will work as expected.  

Enabling the server is done through `Renoise > Preferences > OSC`. You will need to set Duplex to the exact same configuration as Renoise, which can be done through the [options dialog](GettingStarted.md#the-options-dialog). From this dialog, you are also conveniently able to test whether Duplex was able to connect.

#

> Next - [Getting Started](GettingStarted.md) >


