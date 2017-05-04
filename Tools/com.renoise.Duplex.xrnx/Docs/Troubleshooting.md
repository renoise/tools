# Duplex.xrnx - Troubleshooting 

As a general rule, whenever possible, operation should be plug-and-play. The following is a checklist you might want to go through, before creating a topic on the Renoise forum:

1. For MIDI devices, check that the right input and output ports are selected in the options dialog. For OSC devices, ensure that network communication is working, and not blocked by a firewall.
2. Open one of the device configurations, and read the comments in the lower part of the virtual control surface. Often, this might reveal details about special presets or editor files that are required in order to get the device working.
3. Enable the “MIDI dump” feature in the Duplex menu. The console should now list any communication between Renoise and the device. This is useful for debugging, and might reveal any problem in the setup. 