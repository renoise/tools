# Frequently Asked Questions 

|Question |Answer |
|---------|-------|
|Is my device supported?| First, install Duplex, and check to see if the menu list your device. If this is the case, then the answer is obviously “yes”. Otherwise, consult the “list of controllers” (with pending controllers)|
|My device is not working?| If you experience trouble getting the device to do anything, please see [troubleshooting your device](Controllers.md#troubleshooting-your-device)|
|Where do I locate the Duplex folder?|The Duplex folder is located in the Renoise Tools folder, named `com.renoise.Duplex.xrnx`. While in Renoise, you can open the Duplex folder like this: go to the tools menu, select the Tool Browser and locate Duplex. Right-click the tool, and there should be an option to reveal the folder (in explorer, finder etc.)|
|How do I locate an application class?| The applications are located in the Duplex folder, under `Duplex/Applications`|
|How do I locate a device configuration?| The device configuration is located in `Duplex/Controllers/[DeviceName]/[Device Name]/Configurations/` <br>Note: replace [Device Name] with the name of your device.|
|How do locate a control-map?| The control-map is located in `Duplex/Controllers/[Device Name]/[Device Name]/Controlmaps/` <br>Note: replace [Device Name] with the name of your device. If you're unsure which control-map you're looking for, but you know which device configuration is using the control-map, open the device configuration in a text editor and look for the "control_map" property inside each configuration.|
|Can I reset my device configurations?| Duplex settings are stored in a file called `preferences.xml`. If you want to go back to the default settings, delete this file when Renoise is not running.|
|My personal preferences (application settings) are gone?| When you install a new version of Duplex, your preferences might be deleted. To avoid this, take a backup of the file (preferences.xml) first. You can copy the file back to your folder once Renoise isn’t running.|
|I see a lot of “garbage” commands in the pattern?|It's most likely because the controller is also configured in Renoise as an input device. Simply uncheck the device from Renoise preferences > MIDI input devices. The commands you're seeing are probably CC pattern commands (channel/parameter/value).|
|I have two Launchpads. Can I use them side-by-side ?||
|Is it possible to attach multiple devices of the same kind?| Yes. It's possible to copy an existing device configuration, and make it appear under a different name. In this way, you can run a similar setup on multiple devices that are connected to different ports. Open the relevant device configuration and make a copy of all the desired configuration entries. Then, change the "display_name" in the new configurations to a new name, like "Launchpad (2)". The next you start Renoise, the Duplex browser will contain the new device as a separate entry. Don't forget to assign the correct input/output ports to the new device as well.|
|Can I use the same device to control multiple instances of Renoise?| Using the the same device in two Renoise instances is tricky, but possible. You'd probably want to split the control-map into two sections, each one controlling it's own instance. See the section on how to split a control-map for more details. |
|How do I turn off all devices?| Open the Duplex browser and select "none" in the device list. This will release all currently active devices. Alternatively, use the Duplex menu item “release all devices”|
|When I close Renoise, my controller still have some lights turned on?| Duplex does not actively turn off lights when an application is shut down, but this should not matter as the device is completely reinitialized when starting up the next time.|
|Can I somehow see the communication between Renoise and my MIDI controller? | Yes, go to the Tools > Duplex menu and select "dump MIDI". This will output the MIDI messages in the console |
|Can I change the location of individual buttons and sliders?||
|How can I add more applications to my device?| Yes, see chapter 5: Device configurations for extensive information on how to customize your controller |
|How to enable the scripting console in Renoise|The [Renoise API repository](https://github.com/renoise/xrnx) has instructions for enabling the scripting console|

