# Configurations

## What is a configuration? 

Whenever you are using Duplex with a controller, you are in fact running a configuration. For example, the Launchpad has several configurations: a Mixer layout, a StepSequencer layout, and so on. 

Configurations make three important elements come together: 

1. _The Control-map_, which describes the layout of the controller (see below). 
2. _The Device_: whether it communicates over MIDI or OSC, and need any kind of 'special treatment'. 
3. _Mappings_, which tell Duplex what applications to run, and how they are assigned. 

> **The control-map** is a XML file which defines buttons and sliders, how large they are, what values they respond to, etc. Control-maps are an important part of Duplex that you can [read more about here](Controlmaps.md)

### How to customize a configuration

While a configuration is technically written in the [lua language](https://www.lua.org/), it's nothing more than a "table of values" which can be edited in any text editor without prior programming experience. All you really need to know is what values are required, and what those values mean. If a configuration file is invalid or broken, Duplex will (sometimes) be able to offer advice on how to fix the problem.

A couple of tips before creating your own configurations

1. If you base your work on a copy of an existing configuration, make sure it has a unique name - or the Duplex browser will complain.
2. If you choose to re-install/update the tool at a later time, any customizations you have made will be LOST as the entire tool folder will be wiped during installation. Please take a backup of your work somewhere else!

## Anatomy of the configuration file

The rest of this chapter will pick apart and explain the following configuration, bit by bit: 

    -- example_configuration.lua
    -- (note: comments are preceded by two dashes)

    duplex_configurations:insert {

      -- this is the name shown in the Duplex browser
      name = "TrackSelector",
      
      -- whether the configuration is pinned (should launch upon start)
      pinned = true,
      
      -- configure a device for this configuration 
      device = {
        display_name = "R-control", 
        device_port_in = "",
        device_port_out = "",
        control_map = "Controllers/Custombuilt/Controlmaps/R-control.xml",
        thumbnail = "Controllers/Custombuilt/R-control.bmp",
        protocol = DEVICE_PROTOCOL.MIDI
      },

      -- applications to run in this configuration
      applications = {
        TrackSelector = {
          mappings = {
            select_first = {
              group_name = "Switches",
              index = 5,
            },
            select_sends = {
              group_name = "Switches",
              index = 7,
            },
            select_track = {
              group_name = "Master",
            },
          },
        },
      }
    }

### Device configuration

You might notice that two parts are slightly more complex than the others.  
The first one is the "device configuration". Here it is a again, taken out of context:

    -- configure a device for this configuration 
    device = {
      protocol = DEVICE_PROTOCOL.MIDI
      display_name = "R-control", 
      device_port_in = "",
      device_port_out = "",
      control_map = "Controllers/Custombuilt/Controlmaps/R-control.xml",
      thumbnail = "Controllers/Custombuilt/R-control.bmp",
    },

The `protocol` tells Duplex if the device is MIDI or OSC-based. Possible values are DEVICE_PROTOCOL.MIDI and DEVICE_PROTOCOL.OSC.

The `display_name` is the device name shown in the Duplex browser. It's possible to call the controller anything you want - this can help to differentiate between multiple device. This is useful when you own multiple units of identical hardware and want them to appear under different names.

The `class_name` is only needed when the controller has 'special requirements'. The name refers to a lua class which can translate messages going back and forth between the controller and Renoise. 

Next, the `device_port_in` and `device_port_out`. These are MIDI input and output port names. The values provide a default name, and are optional. If the provided name doesn't appear on the user's machine, a different one can be chosen via the Duplex browser. 

The `control_map` property is containing the path to the [control-map](Controlmaps.md) that is used for the configuration, relative to the root of the Duplex tool folder. 

The `thumbnail` property is optional, a miniature graphic that is shown when displaying device options in the Duplex browser (again, the path relative to the root of the Duplex tool folder)


### Applications

The second, "slightly more complex" part of our example configuration files is the "application configuration".  
This is what it looks like:

    -- applications to run in this configuration
    applications = {
      TrackSelector = {
        mappings = {
          select_first = {
            group_name = "Switches",
            index = 5,
          },
          select_sends = {
            group_name = "Switches",
            index = 7,
          },
          select_track = {
            group_name = "Master",
          },
        },
      },
    }          

Starting from the top, we have a table called `applications`. And inside that table, we have defined an entry called `TrackSelector`. Now, TrackSelector happens to be the (class-)name of our application, and everything inside those brackets are instructions specifically for that application. In this case, a bunch of `mappings`. 

### Multiple applications?

Nothing prevents you from adding multiple applications to a configuration - actually, as Duplex is running no more than one configuration per device at any time, in real life this is more the rule than the exception.  

In the example above, you could have inserted additional applications before or after the `TrackSelector`. The syntax is following the same principles, no matter what application you choose. But there is however one detail which is worth knowing about: when you want to run multiple applications _of the same kind_, you will need to call them something unique. So, if you for some reason wanted to run two instances of TrackSelector, you would need to call them something like `TrackSelectorFirst` and `TrackSelectorSecond`, and then define the _actual name_ in the following way:

    applications = {
      TrackSelectorFirst = {
        application = "TrackSelector", -- actual class name
        mappings = {
          -- mappings goes here ..
        },        
      },
      TrackSelectorSecond = {
        application = "TrackSelector", -- actual class name
        mappings = {
          -- mappings goes here ..
        },        
      },
    }  

### Application mappings

A mapping provides the link between a given feature of an application and a specific part of your controller. As you can imagine, this is a pretty important part of any configurations. 

Each mapping is located within the `mappings` branch and named after a feature of the application. In our example above, those features were called `select_first`, `select_sends` and `select_track`. 

> To learn which features in a given application that are available as mappings, [click  here](Applications.md). 

#### Standard and greedy mappings 

Mappings can take on two forms - the **standard mapping**, which indicates a specific position within a [control-map group](Controlmaps.md). For example, if the control-map group contains four available slots, you can choose any number between 1-4 using the `index` property.  
The second type of mapping is the so-called **greedy mapping**. Like the name suggests, it will consume its designated group. This type of mapping is usually used when an application has many identical controls which perform a similar/related function. For example, sliders for a mixing console or the buttons that make up a step sequencer grid. 

> NB: there is currently no clear information on whether a given application mapping is greedy or not. You can study the application itself, or assume that the mapping name carries significance - when it's clearly plural ("sliders" vs. "slider"), this should indicate that the mapping is greedy. On the TODO list.

#### Mapping properties

Here is an mapping which specifies all possible properties:

    select_first = {
      group_name = "Switches",
      index = 5,
      orientation = ORIENTATION.HORIZONTAL,
    },

* `group_name` : refers to the name of the control-map group. Usually, you would enter the literal name of the group (e.g. "FaderGroup"), but sometimes, it's more convenient to assign a group name using _wildcard syntax_ (see below). 
* `index` : a numeric value which refer to a specific position within that group. When a mapping is greedy, the index is usually ignored.  
* `orientation (optional)` : when the application feature you are mapping supports both vertical and horizontal layout, you can define it here. Possible values are ORIENTATION.HORIZONTAL and ORIENTATION.VERTICAL.

> **Wildcard syntax** : This is a special way of entering group names, in which you enter an asterisk as placeholder for something else - e.g. entering `FaderGroup*` will match `FaderGroup1`, `FaderGroup2`, and any other group whose name starts with "FaderGroup".
This feature is also referred to as _distributed groups_, and is mostly used when you need to distribute an application feature across multiple, disparate locations on the controller that doesn't fit into a single group.

### Application options

When Duplex is running a configuration, each application is initialized using its default, in-built options. But, using `options`, you can choose to override these options with custom values. 

    TrackSelector = {
      mappings = {
        -- your mappings here
      },
      options = {
        page_size = 1
      }
    },
  
> To learn which options are available for each application, check the [documentation](Applications.md). 

Note that the user can still modify all these options as he/she pleases, using the Duplex browser. By specifying options in the configuration, you only provide a good "starting point".

### Application palette

The configuration can also be used for overriding the default "palette" for each of our applications. This is useful when you want to tweak the colors or text for a particular controller. Most applications are tuned to the specific controller on which they were developed. As a result, it might look a bit strange on others. 

Let's take a quick look on an actual palette:

    {
      page_prev_on        = { color = {0xFF,0xFF,0xFF}, text = "<", val=true  },
      page_prev_off       = { color = {0x00,0x00,0x00}, text = "<", val=false },
      page_next_on        = { color = {0xFF,0xFF,0xFF}, text = ">", val=true  },
      page_next_off       = { color = {0x00,0x00,0x00}, text = ">", val=false },
    }

A palette, in the Duplex world, is nothing more than a table of values. Each entry contains a `color` (the Red, Green and Blue components), a string (`text`) and a boolean value (`val`). 

Together, these can represent some value/state across a wide range of controllers. For example, if the controller has color LEDs - cool, then we can use the color. If not, hmmm maybe we'll have to do with the boolean value to set a "lit" or "unlit" state. 
And the text is useful too - especially as the virtual recreation of the controller shown in Renoise can contain special, "icon-like" characters. 


#

> < Previous - [Devices & Troubleshooting](Docs/Controllers.md) &nbsp; &nbsp; | &nbsp; &nbsp; Next - [Control-map reference](Docs/Controlmaps.md) >