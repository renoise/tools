--[[============================================================================
com.renoise.ExampleToolGui.xrnx/main.lua
============================================================================]]--

-- tool registration

-- (see com.renoise.ExampleTool.xrns/main.lua for a description of this 
--  header and tools in general)

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:1. Hello World...",
  invoke = function() hello_world() end 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:2. Pretty Hello World...",
  invoke = function() pretty_hello_world() end 
}
  
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:3. Dynamic Content & Ids...",
  invoke = function() dynamic_content() end 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:4. Batch Building Views (Matrix)...",
  invoke = function() dynamic_building_matrix() end 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:5. Aligning & Auto Sizing...",
  invoke = function() aligners_and_auto_sizing() end 
}
  
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:6. Available Backgrounds & Text...",
  invoke = function() available_backgrounds() end 
}
  
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:7. Available Controls...",
  invoke = function() available_controls() end 
}
  
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:8. Documents & Views...",
  invoke = function() documents_and_views() end 
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Example Tool GUI:9. Keyboard Events...",
  invoke = function() handle_key_events() end
}


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

-- hello_world

function hello_world()

  -- to create views, we do need to create a "viewbuilder object", which
  -- can be instantiated from the class renoise.ViewBuilder:
  local vb = renoise.ViewBuilder()

  -- a viewbuilder constructs views for us, which can then later on be
  -- passed to renoise to be shown - somehow. Right now there are two
  -- ways to show your custom views:
  -- app():show_custom_prompt() -> shows a modal dialog with buttons
  -- app():show_custom_dialog() -> shows a non modal dialog with custom content

  -- lets start with the most simple view/dialog thats possible, by only
  -- creating a prompt with a custom text.

  -- To create & configure views, we do pass a table with properties as
  -- argument to the viewbuilder functions:

  -- vb:text { text = "My text" }

  -- means nothing more than:
  -- 1. create a text view
  -- 2. tell the text view that its text property is "My text"


  -- here is how this looks like in action:

  local dialog_title = "Hello World"

  local dialog_content = vb:text {
    text = "from the Renoise Scripting API"
  }

  local dialog_buttons = {"OK"}

  renoise.app():show_custom_prompt(
    dialog_title, dialog_content, dialog_buttons)

  -- eh voila. Not pretty, but at least something to start with ;) We're going
  -- to make that a bit more pretty and advanced in the next example...

end


--------------------------------------------------------------------------------

-- pretty_hello_world

function pretty_hello_world()

  -- Beside of texts, controls and backgrounds and so on, the viewbuilder also
  -- offers some helper views which will help you to 'align' and stack views.

  -- lets start by creating a view builder again:
  local vb = renoise.ViewBuilder()

  -- now we are going to use a "column" view. a column can do three things:
  -- 1. showing a background (if you don't want your views on the plain dialogs
  --    back)
  -- 2. "stack" other views (its child views) either vertically, or horizontally
  --    vertically = vb:column{}
  --    horizontally = vb:row{}
  -- 3. align child views via "margins" -> borders for nested views

  -- lets use all of this in a bit more complicated hello world view:

  local dialog_title = "Hello World"
  local dialog_buttons = {"OK"};

  -- get some consts to let the dialog look like Renoises default views...
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  -- start with a 'column' to stack other views vertically:
  local dialog_content = vb:column {
    -- set a border of DEFAULT_MARGIN around our main content
    margin = DEFAULT_MARGIN,

    -- and create another column to align our text in a different background
    vb:column {
      -- background that is usually used for "groups"
      style = "group",
      -- add again some "borders" to make it more pretty
      margin = DEFAULT_MARGIN,

      -- now add the first text into the inner column
      vb:text {
        text = "from the Renoise Scripting API\n"..
         "in a vb:column with a background"
      },
    }
  }

  renoise.app():show_custom_prompt(
    dialog_title, dialog_content, dialog_buttons)

  -- lets go on and start to use some real controls (buttons & stuff) now...
end


--------------------------------------------------------------------------------

-- dynamic_content

function dynamic_content()

  local vb = renoise.ViewBuilder()

  -- we've used above an inlined style to create view. This is very elegant
  -- when creating only small & simple GUIs, but can also be confusing when the
  -- view hierarchy gets more complex.
  -- you actually can also build views step by step, instead of passing a table
  -- with properties, set the properties of the views manually:

  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN

  -- this:
  local my_column_view = vb:column{}
  my_column_view.margin = DEFAULT_DIALOG_MARGIN
  my_column_view.style = "group"

  local my_text_view = vb:text{}
  my_text_view.text = "My text"

  my_column_view:add_child(my_text_view)

  -- is exactly the same like this:
  local my_column_view = vb:column{
    margin = DEFAULT_DIALOG_MARGIN,
    style = "group",

    vb:text{
      text = "My text"
    }
  }


  -- in practice you should use a combination of the above two notations, but
  -- its recommended to setup & prepare components in separate steps while
  -- still using the inlined / nested notation:

  local my_first_column_view = vb:column {
    -- some content
  }

  local my_second_column_view = vb:column {
    -- some more content
  }

  -- then do the final layout:
  local my_final_layout = vb:row {
    my_first_column_view,
    my_second_column_view
  }

  -- the inlined notation has a problem though: you can not memorize your views
  -- in local variables, in case you want to access them later (for example to
  -- hide/how them, change the text or whatever else). This is what viewbuilder
  -- "id"s are for.

  -- lets build up a simple view that dynamically reacts on a button hit:

  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local dialog_title = "vb IDs"
  local dialog_buttons = {"OK"};

  local dialog_content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,

    vb:text {
      id = "my_text",
      text = "Do what you see"
    },

    vb:button {
      text = "Hit Me!",
      tooltip = "Hit this button to change the above text.",
      notifier = function()
        local my_text_view = vb.views.my_text
        my_text_view.text = "Button was hit."
      end
    }
  }

  -- we are doing two things here:
  -- first we do create a vb:text as usual, but this time we also give it an
  -- id "my_text_view". This id can then at any time be used to resolve this
  -- view. So we can use the inlined notation without having to create lots of
  -- local view refs

  -- There's now also a first control present: a button. Controls may have
  -- notifiers.
  -- The buttons notifier is simply a function without arguments, which is
  -- called as soon as you hit the button. Tf you use other views like a
  -- value box, the notifiers will pass a value along your function...

  -- please note that ids are unique !per viewbuilder object!, so you can
  -- create several viewbuilders (one for each component) to access multiple
  -- sets of ids

  renoise.app():show_custom_prompt(
    dialog_title, dialog_content, dialog_buttons)

end


--------------------------------------------------------------------------------

-- dynamic_building_matrix

function dynamic_building_matrix()

  -- as shown in dynamic_content(), you can build views either in the "nested"
  -- notation, or "by hand". You can of course also combine both ways, for 
  -- example if you want to dynamically build equally behaving view "blocks"

  -- here is a simple example that creates a note-octave-matrix with buttons

  local vb = renoise.ViewBuilder()

  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local BUTTON_WIDTH = 2*renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

  local NUM_OCTAVES = 10
  local NUM_NOTES = 12

  local note_strings = {
    "C-", "C#", "D-", "D#", "E-", "F-", 
    "F#", "G-", "G#", "A-", "A#", "B-"
  }

  -- create the main content column, but don't add any views yet:
  local dialog_content = vb:column {
    margin = CONTENT_MARGIN
  }

  for octave = 1,NUM_OCTAVES do
    -- create a row for each octave
    local octave_row = vb:row {}

    for note = 1,NUM_NOTES do
      local note_button = vb:button {
        width = BUTTON_WIDTH,
        text = note_strings[note]..tostring(octave - 1),

        notifier = function()
          -- functions do memorize all values in the scope they are
          -- nested in (upvalues), so we can simply access the note and 
          -- octave from the loop here:
          renoise.app():show_status(("note_button %s%d got pressed"):format(
            note_strings[note], octave - 1))
        end

      }
      -- add the button by "hand" into the octave_row
      octave_row:add_child(note_button)
    end

    dialog_content:add_child(octave_row)
  end

  renoise.app():show_custom_dialog(
    "Batch Building Views", dialog_content)
end


--------------------------------------------------------------------------------

-- aligners_and_auto_sizing

function aligners_and_auto_sizing()

  -- beside of "stacking" views in columns and rows, its sometimes also useful
  -- to align some parts of the views for example centered or right
  -- this is what the view builders "horizontal_aligner" and "vertical_aligner"
  -- building blocks are for.
  
  -- related to this topic, we'll also show how you can auto size views: (size
  -- a view relative to its parents size). This is done by simply specifying
  -- percentage values for the sizes, like: width = "100%"

  local vb = renoise.ViewBuilder()

  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  -- lets create a simple dialog as usual, and align a few totally useless
  -- buttons & texts:
  local dialog_content = vb:column {
    id = "dialog_content",
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    
    -- first center a text. We don't necessarily need aligners for this, 
    -- but simply resize the text to fill the entrire row in the column, 
    -- then tell the text view how it should align its content:
    vb:text {
      text = "horizontal_aligner",
      width = "100%",
      align = "center",
      font = "bold"
    },
    
    -- add a large Textfield (this will be our largest view the other 
    -- views will align to)
    vb:textfield {
      value = "Large Text field",
      width = 300
    },
    
    -- align a text to the right, using 'align_horizontal'
    -- aligners do have margins & spacings, just like columns, rows have, which
    -- we now use to place a text 20 pixels on the right, top, bottom:
    vb:horizontal_aligner {
      mode = "right",
      margin = 20,

      vb:text {
        text = "I'm right and margined",
      },
    },
    
    -- align a set of buttons to the left, using 'align_horizontal'
    -- well, this is actually just what "row" does, but horizontal_aligner 
    -- automatically uses a width of "100%", while you can not use a "row"
    -- with a relative width...
    vb:horizontal_aligner {
      mode = "left",

      vb:button {
        text = "[",
        width = 40
      },
      vb:button {
        text = "Left",
        width = 80
      },
      vb:button {
        text = "]",
        width = 20
      }
    },
    
    -- align a set of buttons to the right, using 'align_horizontal'
    vb:horizontal_aligner {
      mode = "right",

      vb:button {
        text = "[",
        width = 40
      },
      vb:button {
        text = "Right",
        width = 80
      },
      vb:button {
        text = "]",
        width = 20
      }
    },
    
    -- align a set of buttons centered, using 'align_horizontal'
    vb:horizontal_aligner {
      mode = "center",

      vb:button {
        text = "Center",
        width = 80
      }
    },
    
    -- again a set of buttons centered, but with some spacing
    vb:horizontal_aligner {
      mode = "center",
      spacing = 8,

       vb:button {
        text = "[",
        width = 40
      },
      vb:button {
        text = "Spacing = 8",
        width = 80
      },
      vb:button {
        text = "]",
        width = 20
      }
    },
    
    -- show the "justify" align style
    vb:horizontal_aligner {
      mode = "justify",
      spacing = 8,

       vb:button {
        text = "[",
        width = 40
      },
      vb:button {
        text = "Justify",
        width = 80
      },
      vb:button {
        text = "]",
        width = 20
      }
    },
    
    -- show the "distribute" align style
    vb:horizontal_aligner {
      mode = "distribute",
      spacing = 8,

       vb:button {
        text = "[",
        width = 40
      },
      vb:button {
        text = "Distribute",
        width = 80
      },
      vb:button {
        text = "]",
        width = 20
      }
    },
    

    -- add a space before we start with a "new category"
    vb:space {
      height = 20
    },
    
    -- lets use/show relative width, height properties:
    vb:text {
      text = "relative sizes",
      font = "bold",
      width = "100%",
      align = "center"
    },
    
    
    -- create a aligner again, but this time just to stack
    -- some views:
    vb:horizontal_aligner {
      width = "100%",
      
      vb:button {
        text = "20%",
        width = "20%"
      },
      vb:button {
        text = "80%",
        width = "80%"
      },
    },
    

    -- again a space before we start with a "new category"
    vb:space {
      height = 20
    },
    
    -- not lets create a button that toggles another view. when toggling, we 
    -- do update the main racks size which also updates the dialogs size: 
    vb:text {
      text = "resize racks & dialogs",
      width = "100%",
      align = "center",
      font = "bold"
    },
    
    -- add a button that hides the other view:
    vb:button {
      text = "Click me",
      notifier = function()
        -- toggle visibility of the view on each click
        vb.views.hide_me_text.visible = not vb.views.hide_me_text.visible

        -- and update the main content view size and thus also the dialog size
        vb.views.dialog_content:resize()
      end,
    },

    -- the text view that we are going to show/hide
    vb:text {
      id = "hide_me_text",
      text = "Click the button above to hide this view",
    },
  }
  
 renoise.app():show_custom_dialog(
    "Aligning & Auto Sizing", dialog_content)
end


--------------------------------------------------------------------------------

-- available_backgrounds

function available_backgrounds()

  -- lets go on by simply demonstrating the available views, starting with all
  -- background styles:

  local vb = renoise.ViewBuilder()

  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN


  -- columns
  local group_back = vb:column {
    margin = CONTROL_MARGIN,
    style = "group",
    vb:text{
      text = "style = 'group'"
    }
  }

  local plain_back = vb:column {
    margin = CONTROL_MARGIN,
    style = "plain",
    vb:text{
      text = "style = 'plain'"
    }
  }

  local body_back = vb:column {
    margin = CONTROL_MARGIN,
    style = "body",
    vb:text{
      text = "style = 'body'"
    }
  }

  local panel_back = vb:column {
    margin = CONTROL_MARGIN,
    style = "panel",
    vb:text{
      text = "style = 'panel'"
    }
  }
  
  local border_back = vb:column {
    margin = CONTROL_MARGIN,
    style = "border",
    vb:text{
      text = "style = 'border'"
    }
  }
  
  local multiline_text = vb:column {
    margin = CONTROL_MARGIN,
    vb:multiline_text{
      width = 160,
      height = 50, 
      text = [[
multiline_text:
Long texts can be scrolled and/or autoformated with a 'multiline_text'.
]]
    }
  }
        
 -- and also use a non modal dialog this time:
  renoise.app():show_custom_dialog(
    "Backgrounds & Text", 
    vb:column {
      margin = DIALOG_MARGIN,
      spacing = DIALOG_SPACING,
      uniform = true,
      
      group_back,
      plain_back,
      body_back,
      panel_back,
      border_back,
      multiline_text
    }
  )
end


--------------------------------------------------------------------------------

-- available_controls

function available_controls()

  -- now we create a dialog with all available controls (things that let the 
  -- user change "values"), so you get an idea how all the views look like, 
  -- which views to choose from when creating a new custom GUIs.
  --
  -- but one note about controls & "values" in general first: as you'll see 
  -- below, we do attach notifiers to the values of the controls. Notifiers are
  -- callback functions that are called as soon as the user changed the views 
  -- value through the GUI. To maintain something like an external state that
  -- you are going to use outside the view, make sure you do keep the views value
  -- and "your" value in sync.
  --
  -- here is a somple example on how to sync an external value with "your" value:
  --
  -- current_velocity = 0x7f -- used in other places like your processing functions
  --
  -- vb:slider {
  --   value = current_velocity, -- initialize the GUI with your value
  --   notifier = function(slider_value) -- update your value when the GUI changed
  --     current_velocity = slider_value
  --   end,
  --   min = 0,
  --   max = 0x7f
  -- }
  --
  -- there is another way of dealing with "values", which we will describe in the 
  -- next example more in detail. Basically you can also pass over an Observable 
  -- object to the view (not the raw number, boolen), which then will be used by 
  -- the view instead of its onw value. Any changes to this value can then tracked 
  -- outside of this view. This often is very useful to seperate the GUI code from
  -- the controller and data. Here is a simple example:
  --
  -- -- (the controller part of your script)
  -- options.current_velocity = 0x7f
  -- options.current_velocity.add_notifier(current_value_changed_function)
  
  -- -- (and the GUI)
  -- vb:slider {
  --   bind_value = options.current_velocity, -- only gets a reference passed
  --   min = 0,
  --   max = 0x7f
  -- }

  local function show_status(message)
    renoise.app():show_status(message); print(message)
  end
  
  -- we memorize a reference to the dialog this time, to close it
  local control_example_dialog = nil
  
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DEFAULT_MINI_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  
  local TEXT_ROW_WIDTH = 80


  -- CONTROL ROWS
  
  -- textfield
  local textfield_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:textfield"
    },
    vb:textfield {
      text = "Edit me",
      notifier = function(text)
        show_status(("textfield value changed to '%s'"):
          format(text))
      end
    }
  }

  --- multiline_textfield row
  local mltextfield_row = vb:row {
    vb:text {
      width = 80,
      text = "vb:ml_textfield"
    },
    vb:multiline_textfield {
      height = 80,
      width = 120,
      value = "I am a long text that can be edited.\n\nParagraphs are separated with "..
        "\\n's.\n\nEdit me",
      notifier = function(value)
        show_status(("multiline_textfield value changed to '%s'"):
          format(value))
      end
    },
  }
  
  -- bitmapview 
  local bitmapview_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:bitmap"
    },
    vb:bitmap {
      -- recolor to match the GUI theme:
      mode = "body_color",
      -- bitmaps names should be specified with a relative path using
      -- your tool script bundle path as base:
      bitmap = "Bitmaps/RenoiseLua.bmp",
      notifier = function()
        show_status("bitmapview was pressed")
      end
    },
    --[[ TODO vb:bitmap {
      mode = "alpha",
      bitmap = "Bitmaps/RenoiseLua.png",
      notifier = function()
        show_status("bitmapview was pressed")
      end
    } ]]
  }
  
  -- button 
  local button_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:button"
    },
    vb:button {
      text = "Hit me",
      width = 60,
      notifier = function()
        show_status("button was hit")
      end,
    },
    vb:button {
      -- buttons can also use bitmaps as icons:
      bitmap = "Bitmaps/MiniPiano.bmp",
      width = 20,
      notifier = function()
        show_status("button with bitmap was hit")
      end,
    },
    
    vb:button {
      -- buttons can also have custom text/back colors
      text = "Color",
      width = 30,
      color = {0x22, 0xaa, 0xff},
      -- and we also can handle presses, releases separately
      pressed = function()
        show_status("button with custom colors was pressed")
      end,
      released = function()
        show_status("button with custom colors was released")
      end,
    }
  }

  -- checkbox
  local checkbox_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:checkbox"
    },
    vb:checkbox {
      value = true,
      notifier = function(value)
        show_status(("checkbox value changed to '%s'"):
          format(tostring(value)))
      end,
    }
  }

  -- switch 
  local switch_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:switch"
    },
    vb:switch {
      id = "switch",
      width = 100,
      value = 2,
      items = {"A", "B", "C"},
      notifier = function(new_index)
        local switch = vb.views.switch
        show_status(("switch value changed to '%s'"):
          format(switch.items[new_index]))
      end
    }
  }

  -- popup 
  local popup_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:popup"
    },
    vb:popup {
      id = "popup",
      width = 100,
      value = 2,
      items = {"First", "Second", "Third"},
      notifier = function(new_index)
        local popup = vb.views.popup
        show_status(("popup value changed to '%s'"):
          format(popup.items[new_index]))
      end
    }
  }

  -- chooser 
  local chooser_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:chooser"
    },
    vb:chooser {
      id = "chooser",
      value = 4,
      items = {"First", "Second", "Third", "Fourth"},
      notifier = function(new_index)
        local chooser = vb.views.chooser
        show_status(("chooser value changed to '%s'"):
          format(chooser.items[new_index]))
      end
    }
  }


  -- valuebox
  local valuebox_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:valuebox"
    },
    vb:valuebox {
      min = 0,
      max = 55,
      value = 5,
      tostring = function(value) 
        return ("0x%.2X"):format(value)
      end,
      tonumber = function(str) 
        return tonumber(str, 0x10)
      end,
      notifier = function(value)
        show_status(("valuebox value changed to '%d'"):
          format(value))
      end
    }
  }

  -- valuefield 
  local valuefield_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:valuefield"
    },
    vb:valuefield {
      min = 0.0,
      max = math.db2lin(6.0),
      value = 1.0,
      
      tostring = function(value) 
        local db = math.lin2db(value)
        if db > math.infdb then
          return ("%.03f dB"):format(db)
        else
          return "-INF dB"
        end
      end,
      
      tonumber = function(str) 
        if str:lower():find("-inf") then
          return 0.0
        else
          local db = tonumber(str)
          if (db ~= nil) then
            return math.db2lin(db)
          end
        end
      end,
      
      notifier = function(value)
        show_status(("valuefield value changed to '%f'"):
          format(value))
      end
    }
  }
  
  -- slider
  local slider_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:slider"
    },
    vb:slider {
      min = 1.0,
      max = 100,
      value = 20.0,
      notifier = function(value)
        show_status(("slider value changed to '%.1f'"):
          format(value))
      end
    }
  }

  -- minislider
  local minislider_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:minislider"
    },
    vb:minislider {
      min = 0,
      max = 1,
      value = 0.5,
      notifier = function(value)
        show_status(("mini slider value changed to '%.1f'"):
          format(value))
      end
    }
  }
  
      
  -- rotary
  local rotary_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:rotary"
    },
    vb:rotary {
      min = 2,
      max = 4,
      value = 3.5,
      width = 36,
      height = 36,
      notifier = function(value)
        show_status(("rotaty encoder value changed to '%.1f'"):
          format(value))
      end
    }
  }
  
  
  -- v sliders
  local vslider_column = vb:column {
    vb:text {
      text = "vb:(mini)slider - flipped"
    },
    vb:row {
      vb:slider {
        min = 1.0,
        max = 100,
        value = 20.0,
        width = DEFAULT_CONTROL_HEIGHT,
        height = 120,
        notifier = function(value)
          show_status(("v slider value changed to '%.1f'"):
            format(value))
        end
      },
      vb:minislider {
        min = 1.0,
        max = 100,
        value = 20.0,
        width = DEFAULT_MINI_CONTROL_HEIGHT,
        height = 60,
        notifier = function(value)
          show_status(("v mini slider value changed to '%.1f'"):
            format(value))
        end
      }
    }
  }
  
  
  -- CLOSE BUTTON
    
  local close_button_row = vb:horizontal_aligner {
    mode = "right",
    
    vb:button {
      text = "Close",
      width = 60,
      notifier = function()
        control_example_dialog:close()
      end,
    }
  }
    
    
  -- MAIN CONTENT & LAYOUT
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    uniform = true,

    vb:column {
      spacing = CONTENT_SPACING,
      
      textfield_row, 
      mltextfield_row,
      bitmapview_row, 
      button_row, 
      checkbox_row, 
      switch_row, 
      popup_row, 
      chooser_row, 
      valuefield_row, 
      valuebox_row, 
      slider_row,
      minislider_row,
      rotary_row,
      
      vb:space { height = 2*CONTENT_SPACING },
    
      vslider_column
    },
    
    -- close
    close_button_row
  }
  
  
  -- DIALOG
  
  control_example_dialog = renoise.app():show_custom_dialog(
    "Controls", dialog_content
  )

end


--------------------------------------------------------------------------------

-- documents_and_views

-- as already noted in 'available_controls'. views can also be attached to 
-- external document values, in order to seperate the controller code from the 
-- view code. We're going to do this tight now and do start by create a very 
-- simple example document. Please have a look at Renoise.Document.API for more 
-- detail about such documents


-- DOCUMENT

-- create a simple document with two values
local example_document = renoise.Document.create {
  my_flag = false,
  some_velocity = 127
}

-- we do place our notifications (if needed now outside of the GUI code)
example_document.my_flag:add_notifier(function()
  local new_value = example_document.my_flag.value
  
  print(("'my_flag' changed to '%s' by either the GUI "
    .. "or something else..."):format(new_value and "True" or "False"))
end)


-- GUI

function documents_and_views()

  local vb = renoise.ViewBuilder()

  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

 
  -- now we pass over the document struct to the views
  local checkbox_row = vb:row {
    vb:text { 
      text = "my_flag", width = 80 
    },
    vb:checkbox { 
      bind = example_document.my_flag -- bind
    }
  }
  
  local valuebox_row = vb:row {
    vb:text { 
      text = "some_velocity", width = 80 
    },
    vb:valuebox{
      bind = example_document.some_velocity, -- bind
      min = 0, 
      max = 0x7f
    }
  }
  
  renoise.app():show_custom_dialog("Documents & Views", 
    vb:column {
      margin = DIALOG_MARGIN,
      uniform = true,
 
      vb:column {
        spacing = CONTENT_SPACING,
        checkbox_row,
        valuebox_row
      }
    }
  )
end


--------------------------------------------------------------------------------

-- handle_key_events

function handle_key_events()

  -- dialogs also allow you to handle keyboard events by your own. by default
  -- only the escape key is used to close the dialog when focused. If you want
  -- to do more fancy stuff, then simply pass a key_hander_func to the custom
  -- dialog. Here is a simply example how this can be done:

  local vb = renoise.ViewBuilder()

  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local TEXT_ROW_WIDTH = 240
  
  local content_view =  vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,

    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "Press some keyboard keys:"
    },
    
    vb:row {
      style = "group",
      
      vb:multiline_text {
        id = "key_text",
        width = TEXT_ROW_WIDTH,
        height = 60,
        paragraphs = {"key.name:", "key.modifiers:", "key.character:", "key.note:"},
        font = "mono",
      }
    }
  }
    
  local function key_handler(dialog, key)
  
    -- update key_text to show what we got
    vb.views.key_text.paragraphs = {
      ("key.name: '%s'"):format(key.name), 
      ("key.modifiers: '%s'"):format(key.modifiers), 
      ("key.character: '%s'"):format(key.character or "nil"), 
      ("key.note: '%s'"):format(tostring(key.note) or "nil")
    }

    -- close on escape...
    if (key.modifiers == "" and key.name == "esc") then
      dialog:close()
    end
  end
  
  -- show a dialog as usual, but this time also pass a keyboard handler ref
  renoise.app():show_custom_dialog(
    "Handling Keyboard Events", content_view, key_handler)
        
end

   
--------------------------------------------------------------------------------

-- thats it - basically ;) Please have a look at the ViewBuilderAPI.txt for a
-- complete list of properties & functions for all views...


