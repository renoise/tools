# About vLib

The vLib library is a GUI library/framework, modelled after the [Renoise Viewbuilder API](https://github.com/renoise/xrnx/blob/master/Documentation/Renoise.ViewBuilder.API.lua), which specifies additional user-interface widgets that you can use in your Renoise tools. This includes a file browser, a scrollable table and other useful things.

## Requirements

vLib requires an additional library called cLib:  
https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.cLib.xrnx

## How it works

vLib tries to stay as close as possible to the Renoise Viewbuilder API. This is the 'language' that Renoise tools can use for building graphical user interfaces (GUIs). 

If you are not familiar with that API, it's highly recommended to study some [Viewbuilder examples](https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.ExampleToolGui.xrnx) first. However, if you are familiar with the Viewbuilder API, the following syntax should be quite familiar: 

    -- create a viewbuilder 
    local vb = renoise.ViewBuilder()
    
    -- create a vLib toggle button
    local toggle_button = vToggleButton{
      vb = vb,
      text_enabled = "I'm enabled",
      text_disabled = "I'm turned off",
      width = 50,
      height = 20,
      notifier = function(active)
        -- do something when clicked
      end,
    }
    
    local view = vb:row{
      toggle_button.view -- add to view using the 'view' property 
    }

If you look closely, you'll notice a few minor details that are different from how the Viewbuilder API is used. 

First of all, we need to supply our vLib component with a reference to the viewbuilder instance when creating the object (the `vb` argument).  
And secondly, we are keeping a reference to the object and handing over that objects `view` property to the viewbuilder. This is necessary, as vLib components are in fact just plain lua classes and not 'true' viewbuilder views. 


## Documentation

Point your browser to this location to browse the auto-generated luadocs:  
https://renoise.github.io/luadocs/vlib

## Examples 

To see vLib in action, download the tool from github:  
https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.vLib.xrnx

