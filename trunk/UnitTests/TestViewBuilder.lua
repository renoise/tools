--[[--------------------------------------------------------------------------
TestViewBuilder.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local app = renoise.app()
  local ViewBuilder = renoise.ViewBuilder
  local vb = ViewBuilder()
  
  
  
  ----------------------------------------------------------------------------
  -- notifiers (functions)
  
  local function my_button_notifier() end
  local function my_button_notifier2() end
  local button = vb:button {}
  
  -- add_pressed_notifier
  button:add_pressed_notifier(my_button_notifier)
  button:add_pressed_notifier(my_button_notifier2)
  assert_error(function() 
    button:add_pressed_notifier(my_button_notifier)
  end)
  
  -- add/remove_released_notifier
  button:add_released_notifier(my_button_notifier)
  button:remove_released_notifier(my_button_notifier)
  
  
  -- remove_pressed_notifier
  button:remove_pressed_notifier(my_button_notifier)
  button:remove_pressed_notifier(my_button_notifier2)
  assert_error(function() 
    button:remove_pressed_notifier(my_button_notifier)
  end)
  
  
  -- notifiers (objects)
  
  class "MyClass"
    function MyClass:__init() end
    function MyClass:notifier1(value) end
    function MyClass:notifier2() end
    
  local obj1 = MyClass()
  local obj2 = MyClass()
    
  local mytable = {
    notifier1 = function(value, unused) end,
    notifier2 = function(value) end
  }
  
  myslider = vb:slider{}
  myslider:add_notifier(MyClass.notifier1, obj1)
  myslider:add_notifier({MyClass.notifier2, obj1})
  myslider:add_notifier(obj2, MyClass.notifier1)
  myslider:add_notifier(obj2, MyClass.notifier2)
  assert_error(function() 
    myslider:add_notifier({MyClass.notifier1, obj1})
  end)
  assert_error(function() 
    myslider:add_notifier(MyClass.notifier2, obj2)
  end)
  assert_error(function() 
    myslider:add_notifier({MyClass.notifier1})
  end)
  myslider:remove_notifier(obj2, MyClass.notifier2)
  myslider:remove_notifier(obj1, MyClass.notifier2)
  assert_error(function() 
    myslider:remove_notifier(obj1, MyClass.notifier2)
  end)
  
  myslider:add_notifier(mytable.notifier1, mytable)
  myslider:add_notifier(mytable, mytable.notifier2)
  assert_error(function() 
    myslider:add_notifier({mytable.notifier1, mytable})
  end)
  myslider:remove_notifier(mytable.notifier2, mytable)
  assert_error(function() 
    myslider:add_notifier(mytable, mytable.notifier1)
  end)
  
  
  -- ids
  
  vb:button {
    id = "some_button",
    text = "Button Text"
  }
  
  assert(vb.views.some_button)
  assert(vb.views.some_button.text == "Button Text")
  assert_error(function() 
    vb:button { id = "some_button" }
  end)
  
  
  -- add_remove
  
  local column = vb:column { }
  local column2 = vb:column { }
  local text = vb:text { }
  
  column:add_child(text)
  assert_error(function() 
    column:add_child(text)
  end)
  column:remove_child(text)
  assert_error(function() 
    column:remove_child(text)
  end)
  
  column:add_child(text)
  assert_error(function() 
    column2:add_child(text)
  end)
  
  
  -----------------------------------------------------------------------------
  
  -- consts
  
  local DIALOG_MARGIN = ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DIALOG_SPACING = ViewBuilder.DEFAULT_CONTROL_SPACING
  local DIALOG_BUTTON_HEIGHT = ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DIALOG_MINI_BUTTON_HEIGHT = ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  
  local CONTROL_HEIGHT = ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTENT_MARGIN = ViewBuilder.DEFAULT_CONTROL_MARGIN
  local CONTENT_SPACING = ViewBuilder.DEFAULT_CONTROL_SPACING
  
  local CONTENT_WIDTH = 220
  
  
  -- show_status
  
  local function show_status(message)
    renoise.app():show_status(message)
  end
  
  
  -- dialog content
  
  local dialog_content = vb:row {
    margin = DIALOG_MARGIN,
    spacing = 4*DIALOG_SPACING,
    
    vb:column {
      
      --- text group
      vb:column {
        margin = DIALOG_MARGIN,
        style = "group",
    
        vb:text {
          width = CONTENT_WIDTH,
          text = "vb:text align = 'left'",
          align = "left",
        },
        vb:text {
          width = CONTENT_WIDTH,
          text = "vb:text align = 'right'",
          align = "right",
        },
        vb:text {
          width = CONTENT_WIDTH,
          text = "vb:text align = 'center'",
          align = "center",
        },
      },
    
      --- spacer
      vb:space {
        width = "100%",
        height = DIALOG_SPACING,
      },
    
      --- autosized horizontal_aligner
      vb:column {
        margin = 8,
        spacing = 10,
        width = "100%",
              
        vb:horizontal_aligner {
          mode = "justify",
          vb:text { text = "autosized" },
          vb:text { text = "justified" },
          vb:text { text = "horizontal_aligner" }
        },
        
        vb:horizontal_aligner {
          mode = "left",
          vb:text { text = "autosized left horizontal_aligner"} 
        },
        
        vb:horizontal_aligner {
          mode = "center",
          vb:text { text = "autosized centered horizontal_aligner"} 
        },
        
        vb:horizontal_aligner {
          mode = "right",
          vb:text { text = "autosized right horizontal_aligner"} 
        }
      },
      
      --- horizontal_aligner
      vb:horizontal_aligner {
        margin = CONTENT_MARGIN,
        spacing = CONTENT_SPACING,
        mode = "left",
        
        vb:button {
          width = "10%",
          text = "[",
          color = {0xff, 0xaa, 0x22},
        },
        vb:button {
          id = "test_button",
          width = "20%",
          text = "left",
          color = {0xaa, 0xff, 0x22},
          pressed = function()
            vb.views.test_button.width = 25
          end,
          released = function()
            vb.views.test_button.width = 50
          end
        },
        vb:button {
          width = "40%",
          text = "]",
          color = {0x22, 0xaa, 0xff},
        },
      },
      
      vb:horizontal_aligner {
        margin = CONTENT_MARGIN,
        spacing = CONTENT_SPACING,
        mode = "right",
        
        vb:button {
          width = 20,
          text = "["
        },
        vb:button {
          width = 60,
          text = "right"
        },
        vb:button {
          width = 40,
          text = "]"
        },
      },
      
      vb:horizontal_aligner {
        margin = CONTENT_MARGIN,
        mode = "center",
        
        vb:button {
          width = 20,
          text = "["
        },
        vb:button {
          width = 60,
          text = "center"
        },
        vb:button {
          width = 40,
          text = "]"
        },
      },
      
      vb:horizontal_aligner {
        margin = CONTENT_MARGIN,
        mode = "distribute",
        
        vb:button {
          width = 20,
          text = "["
        },
        vb:button {
          width = 60,
          text = "distribute"
        },
        vb:button {
          width = 40,
          text = "]"
        },
      },
      
      vb:horizontal_aligner {
        margin = CONTENT_MARGIN,
        mode = "justify",
        
        vb:button {
          width = 20,
          text = "["
        },
        vb:button {
          width = 60,
          text = "justify"
        },
        vb:button {
          width = 40,
          text = "]"
        },
      },
      
      --- multiline_text row
      vb:column {
        margin = CONTENT_MARGIN,      
        vb:text {
          width = 80,
          text = "vb:multiline_text:"
        },
        vb:multiline_text {
          width = 200,
          height =3* CONTROL_HEIGHT,
          font = "mono",
          style = "border",
          paragraphs = {
            "This is a long text",
            "with multiple paragraphs...",
            "bla!",
            "foo man schuuuuuuuuuuuuuuuuuuuu"
          }
        },
        vb:multiline_text {
          width = 200,
          height = 3* CONTROL_HEIGHT,
          text = 
            "This also is a long text"..
            "with multiple paragraphs..."..
            "bla!"..
            "foo man schuuuuuuuuuuuuuuuuuuuu"
        },
      },
         
      --- freeze test
      vb:column {
        vb:button { 
          text = "Script Freeze Test",
          notifier = function()
            while true do
              -- loop forever
            end
          end
        }
      }
    },
    
    --- controls column
     
    vb:column {
      uniform = true,
     
      --- bitmap row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
          text = "vb:bitmap"
        },
        vb:bitmap {
          id = "bitmapview",
          mode = "body_color",
          bitmap = "Logos/SmallLogoWithText.bmp",
          notifier = function()
            if (vb.views.bitmapview.bitmap == "Logos/SmallLogoLetters.bmp") then
              vb.views.bitmapview.bitmap = "Logos/SmallLogoWithText.bmp"
            else
              vb.views.bitmapview.bitmap = "Logos/SmallLogoLetters.bmp"
            end
            show_status("bitmapview was pressed")
          end
        },
      },
      
      --- text row
      vb:row {
        margin = CONTENT_MARGIN,
        style = "plain",
        
        vb:text {
          width = 80,
          text = "vb:text"
        },
        vb:text {
          text = "Push the button to hide\n"..
                 "the slider below..."
        },
      },
         
      --- textfield row
      vb:row {
        margin = CONTENT_MARGIN,
        style = "body",
        
        vb:text {
          width = 80,
          text = "vb:textfield"
        },
        vb:textfield {
          value = "Edit me",
          notifier = function(value)
            show_status(("textfield value changed to '%s'"):
              format(value))
          end
        },
      },
        
      --- multiline_textfield row
      vb:row {
        margin = CONTENT_MARGIN,
        style = "border",
        
        vb:text {
          width = 80,
          text = "vb:ml_textfield"
        },
        vb:multiline_textfield {
          height = 80,
          width = 120,
          value = "I am a long text that can be editied.\nParagraphs are separated with "..
            "\\n's.\n\nEdit me",
          notifier = function(value)
            show_status(("multiline_textfield value changed to '%s'"):
              format(value))
          end
        },
      },
      
      --- button row
      vb:row {
        margin = CONTENT_MARGIN,
        style = "panel",
        
        vb:text {
          width = 80,
          text = "vb:button"
        },
        vb:button {
          text = "Hit me",
          width = 60,
          notifier = function()
            local slider_row = vb.views.slider_row
            slider_row.visible = not slider_row.visible
          end,
        },
        vb:button {
          bitmap = "Icons/Browser_RenoiseInstrumentFile.bmp",
          width = 60,
          notifier = function()
            local slider_row = vb.views.slider_row
            slider_row.visible = not slider_row.visible
          end,
        }
      },
      
      --- checkbox row
      vb:row {
        margin = CONTENT_MARGIN,
        style = "border",
        
        
        vb:text {
          width = 80,
          text = "vb:checkbox"
        },
        vb:checkbox {
          value = true,
          notifier = function(value)
            show_status(("checkbox value changed to '%s'"):
              format(tostring(value)))
          end,
        }
      },
      
      --- switch row
      vb:row {
        margin = CONTENT_MARGIN,
        style = "group",
              
        vb:text {
          width = 80,
          text = "vb:switch"
        },
        vb:switch {
          id = "switch",
          width = 100,
          value = 2,
          items = {"A", "B", "C"},
          notifier = function(new_index)
            local switch = vb.views.switch
            show_status(("switchup value changed to '%s'"):
              format(switch.items[new_index]))
          end
        }
      },
      
      --- popup row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
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
      },
    
      --- chooser row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
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
      },
      
      
      --- valuebox row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
          text = "vb:valuebox"
        },
        vb:valuebox {
          min = 0,
          max = 55,
          value = 5,
          notifier = function(value)
            show_status(("valuebox value changed to '%d'"):
              format(value))
          end
        },
        vb:valuebox {
          min = 0,
          max = 120,
          value = 48,
          tostring = function(value) 
            return ("0x%.2X"):format(value)
          end,
          tonumber = function(str) 
            return tonumber(str, 0x10)
          end,
          notifier = function(value)
            show_status(("valuebox value2 changed to '%d'"):
              format(value))
          end
        },
      },
      
      --- value row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
          text = "vb:value"
        },
        vb:value {
          value = 10,
          font = "bold",
          align = "center",
          tostring = function(value) 
            return ("0x%.2X"):format(value)
          end,
          notifier = function(value)
            show_status(("valuefield value changed to '%d'"):
              format(value))
          end
        },
      },
      
      --- valuefield row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
          text = "vb:valuefield"
        },
        vb:valuefield {
          min = 0,
          max = 100,
          value = 10,
          align = "center",
          tostring = function(value) 
            return tostring(value / 100) .. " %"
          end,
          tonumber = function(str) 
            local value = tonumber(str)
            if value ~= nil then
              return value * 100
            end
          end,
          notifier = function(value)
            show_status(("valuefield value changed to '%d'"):
              format(value))
          end
        },
      },
      
      
      -- slider row
      vb:row {
        id = "slider_row",
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
          text = "vb:slider"
        },
        vb:slider {
          min = 1,
          max = 100,
          value = 20,
          notifier = function(value)
            show_status(("slider value changed to '%.1f'"):
              format(value))
          end
        },
      },
    
      --- minislider row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
          text = "vb:minislider"
        },
        vb:minislider {
          height = DIALOG_MINI_BUTTON_HEIGHT,
          min = 0,
          max = 1,
          value = 0.5,
          notifier = function(value)
            show_status(("mini slider value changed to '%.1f'"):
              format(value))
          end
        },
      },
      
      -- rotary row
      vb:row {
        margin = CONTENT_MARGIN,
        
        vb:text {
          width = 80,
          text = "vb:rotary"
        },
        vb:rotary {
          min = 2,
          max = 4,
          value = 3.5,
          width = 18,
          height = 36,
          notifier = function(value)
            show_status(("rotaty encoder value changed to '%.1f'"):
              format(value))
          end
        },
        vb:rotary {
          min = 2,
          max = 4,
          value = 3.5,
          width = 40,
          height = 40,
          notifier = function(value)
            show_status(("rotaty encoder2 value changed to '%.1f'"):
              format(value))
          end
        },
        vb:rotary {
          min = 2,
          max = 4,
          value = 3.5,
          width = 80,
          height = 80,
          notifier = function(value)
            show_status(("rotaty encoder3 value changed to '%.1f'"):
              format(value))
          end
        }
      },
      
      
      --- space
      
      vb:space {
        height = 20
      },
      
      --- close button
      vb:horizontal_aligner {
        mode = "right",
        
        vb:button {
          text = "Close",
          width = 60,
          notifier = function()
            my_dialog:close()
            assert(not my_dialog.visible)
          end,
        }
      }
    },
  }
  
  
  -- dialog key handler
  
  function dialog_key_handler(dialog, mod, key)
    print(("mod:'%s', key:'%s'"):format(mod, key))
      
    if (mod == "" and key == "esc") then 
      dialog:close()
    end
  end
  
  
  -- show_custom_dialog
  
  my_dialog = app:show_custom_dialog("Dialog Title", 
    dialog_content, dialog_key_handler)
    
  assert(my_dialog.visible)

end

    
------------------------------------------------------------------------------
-- test finalizers

collectgarbage()

    
--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
