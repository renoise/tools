# Devices: Controllers & Troubleshooting

## Supported controllers

We maintain a list of supported controllers in [this Google spreadsheet](https://docs.google.com/spreadsheet/ccc?key=0AkXQ8SxsnmZKdHZwTVVkUnh0WUxfOEtYblhMbWp6R3c&hl=en#gid=0). 

### Using MIDI Controllers

Many of the controllers supported by Duplex will work out of the box, using the factory settings (the default settings of your controller). But if your controller settings are somehow configurable (via an editor software), Duplex might not be able to communicate with it. 

In such a case, you have two options: tweak Duplex to make it understand your controller, or tweak the controller to make it transmit the messages that Duplex is expecting. 

Sometimes, a supported controller will come with a provided preset file, which you can then find in this folder: `Duplex > Controllers > YourController > Presets`. If this is the case, open your controller’s editor software and point it to this file. Loading the preset should ensure that the controller is outputting some values that Duplex has been configured to understand. 

### Using OSC Controllers

Often, OSC controllers will require a valid IP address, port and _prefix_ (see below) before they can be used with Duplex. Exactly how the port & IP are obtained varies from device to device. 
Here are some common scenarios:

**Monome/MonomeSerial**: the IP adress is the one provided in the Monome Serial interface.  
**TouchOSC** (iPhone, Android): check Settings > Connections, look for Local IP address.

> The prefix is an extra string which can be added to any communication with OSC devices. 
Consult your device documentation, to see if it is making use of an OSC prefix or not. 

## Support for new controllers

If your controller is not listed in the spreadsheet (see above), you have a number of options

If you are comfortable writing XML by hand, you can [put together a control-map yourself](http://forum.renoise.com/index.php/topic/28284-how-to-start-editing-duplex-files/). Many controllers require only such a file to work with Duplex. 
Alternatively, you can create a topic on the [Renoise forum](http://forum.renoise.com/). Don't forget to mention Duplex in the title, or it might get overlooked. 

## Troubleshooting your device

As a general rule, whenever possible, operation should be plug-and-play. The following is a checklist you might want to go through, before creating a topic on the Renoise forum:

1. For MIDI devices, check that the right input and output ports are selected in the options dialog. For OSC devices, ensure that network communication is working, and not blocked by a firewall.
2. Open one of the device configurations, and read the comments in the lower part of the virtual control surface. Often, this might reveal details about special presets or editor files that are required in order to get the device working.
3. Enable the “MIDI dump” feature in the Duplex menu. The console should now list any communication between Renoise and the device. This is useful for debugging, and might reveal any problem in the setup. 

> Don't forget to check the [Duplex FAQ](FAQ.md) as well

#

> < Previous - [Bundled Applications](Applications.md) &nbsp; &nbsp; | &nbsp; &nbsp; Next - [Custom Configurations](Configurations.md) >