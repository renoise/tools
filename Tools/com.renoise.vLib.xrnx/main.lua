--[[============================================================================
main.lua
============================================================================]]--

--[[--

Provide a visual demo for the various vlib components, with the ability to test (set/get) all properties and call methods.

--]]

--==============================================================================

_trace_filters = nil
--_trace_filters = {".*"}

_clibroot = "source/cLib/classes/"
_vlibroot = "source/vLib/classes/"
_vlib_img = _vlibroot.."images/"

require (_clibroot.."cLib")
require (_clibroot.."cDebug")
require (_clibroot.."cString")
require (_clibroot.."cColor")

require (_vlibroot.."vLib")
require (_vlibroot.."helpers/vSelection")
require (_vlibroot.."parsers/vXML")
require (_vlibroot.."vArrowButton")
require (_vlibroot.."vButton")
require (_vlibroot.."vDialog")
require (_vlibroot.."vEditField")
require (_vlibroot.."vTextField")
require (_vlibroot.."vSearchField")
require (_vlibroot.."vFileBrowser")
require (_vlibroot.."vGraph")
require (_vlibroot.."vLogView")
require (_vlibroot.."vPathSelector")
require (_vlibroot.."vPopup")
require (_vlibroot.."vTable")
require (_vlibroot.."vTabs")
require (_vlibroot.."vToggleButton")
require (_vlibroot.."vTree")
--require (_vlibroot.."vWaveform")


--------------------------------------------------------------------------------
-- variables etc.
--------------------------------------------------------------------------------

-- workaround for http://goo.gl/UnSDnw
local automatic_start = false

local vbutton,vtogglebutton,varrowbutton,vtabs,vtable,vbrowser,vtree,vlog,vgraph,vpathselector,vpopup,veditfield,vtextfield,vsearchfield --,vwaveform

local vlib_controls = {}
local vlib_controls_ref = {}

local prefs = renoise.Document.create("ScriptingToolPreferences") {
 active_ctrl_idx = 1,
}

local active_ctrl = nil
--local active_ctrl_idx = nil
local suppress_notifier = false

local file_ext = "{'*.wav','*.txt',}"

local vb = renoise.ViewBuilder()
local dialog,dialog_content

--------------------------------------------------------------------------------

local function start()
  TRACE("start()")

  if not dialog or not dialog.visible then
    if not dialog_content then
      dialog_content = build()
      --local select_on_startup = table.find(vlib_controls,"vTable")
      --vb.views.control_chooser.value = select_on_startup
    end

    local function keyhandler(dialog, key)
      --print("key",rprint(key))
    end
      
    dialog = renoise.app():show_custom_dialog("vLib Demo", 
      dialog_content, keyhandler)

  else
    dialog:show()
    
  end


end

--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:vLib Demo...",
  invoke = function() 
    start() 
  end
}

--------------------------------------------------------------------------------
-- keybindings
--------------------------------------------------------------------------------

renoise.tool():add_keybinding{
  name = "Global:Tools:vLib Demo...",
  invoke = function() 
    start() 
  end
}

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_new_document_observable:add_notifier(function()
  if dialog then
    --attach_to_song()
  end
end)

renoise.tool().app_became_active_observable:add_notifier(function()

end)

renoise.tool().app_idle_observable:add_notifier(function()
  --print("main:app_idle_observable fired...")
  if (automatic_start) then
    automatic_start = false
    start() 
  end

end)



--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

_AUTO_RELOAD_DEBUG = function()
  --start()
end

--------------------------------------------------------------------------------
-- build user interface
--------------------------------------------------------------------------------

function build()
  TRACE("build()")

  -- skeleton
  local content = vb:row{
    margin = 6,
    spacing = 4,
    vb:column{
      vb:row{
        spacing = 4,
        vb:column{
          style = "panel",
          vb:text{
            text = "Select widget",
            font = "bold",
          },
          vb:chooser{
            id = "control_chooser",
            notifier = function(idx)
              prefs.active_ctrl_idx.value = idx
            end
          },
        },
        vb:column{
          id = "basic_row",
        
        },
      },
      vb:column{
        vb:row{
          vb:space{
            width = 6,
          },
          vb:button{
            id = "ruler_width",
            color = {0x00,0xFF,0xFF},
            height = 6,
          },
        },
        vb:row{
          vb:button{
            id = "ruler_height",
            color = {0x00,0xFF,0xFF},
            width = 6,
          },
          vb:column{
            id = "controls_col",
            spacing = 6,
            -- controls goes here
          },
        },

      },
      --[[
      vb:column{
        id = "controls_col",
        spacing = 6,
        -- controls goes here
      },
      ]]
    },
    vb:column{
      id = "props_row",
      -- control properties
    }
  }

  build_vview()
  build_vcontrol()

  build_varrowbutton()
  build_vbutton()
  build_veditfield()
  build_vtextfield()
  build_vsearchfield()
  build_vfilebrowser()
  build_vgraph()
  build_vlog()
  build_vpathselector()
  build_vpopup()
  build_vtable()
  build_vtabs()
  build_vtogglebutton()
  build_vtree()
  --build_vwaveform()
  --build_vscroll()

  vb.views.control_chooser.items = vlib_controls
  vb.views.control_chooser.value = prefs.active_ctrl_idx.value
  --local ctrl_idx = vb.views.control_chooser.value
  set_active_ctrl(prefs.active_ctrl_idx.value)
  --set_active_ctrl(prefs.active_ctrl_idx.value)



  return content

end

-------------------------------------------------------------------------------

function set_color_property(key,val)

  val = cColor.hex_string_to_value(val)
  if val then
    set_control_property(key,cColor.value_to_color_table(val))
  else
    renoise.app():show_warning("Not a valid color")
  end

end

-------------------------------------------------------------------------------

function set_ruler_width(val)
  TRACE("set_ruler_width",val)
  if not val then return end
  vb.views["ruler_width"].width = val
end

function set_ruler_height(val)
  TRACE("set_ruler_height",val)
  if not val then return end
  vb.views["ruler_height"].height = val
end

-------------------------------------------------------------------------------

function set_control_property(key,val)
  --print("set_control_property(key,val)",key,val)
  
  if suppress_notifier then
    LOG("set_control_property - suppress_notifier...")
    return
  end

  if active_ctrl then
    --print("setting property(key,val)",key,val)
    active_ctrl[key] = val
  end

end

-------------------------------------------------------------------------------

function set_active_ctrl(idx)
  --print("set_active_ctrl(idx)",idx)

  --vb.views.control_chooser.value = idx

  -- hide all property panels
  for _,elm_id in ipairs(vlib_controls) do
    --print("elm_id",elm_id)
    vb.views[elm_id].visible = false
    vb.views[elm_id.."_properties"].visible = false
  end

  active_ctrl = vlib_controls_ref[idx]

  if not active_ctrl then
    return
  end

  -- show the relevant ones
  local ctrl_name = vlib_controls[idx]
  vb.views[ctrl_name].visible = true
  vb.views[ctrl_name.."_properties"].visible = true

  update_properties()

end


-------------------------------------------------------------------------------

function build_vview()

  vb.views.basic_row:add_child(vb:column{
    style = "panel",
    vb:row{
      vb:text{
        text = "vView",
        font = "bold",
      },
    },
    vb:row{
      vb:text{
        text = "visible"
      },
      vb:checkbox{
        id = "vView_visible",
        value = true,
        notifier = function(val)
          set_control_property("visible",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "width"
      },
      vb:valuebox{
        id = "vView_width",
        value = 100,
        min = 1,
        max = 1000,
        notifier = function(val)
          set_control_property("width",val)
          set_ruler_width(val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "height"
      },
      vb:valuebox{
        id = "vView_height",
        value = 100,
        min = 1,
        max = 1000,
        notifier = function(val)
          set_control_property("height",val)
          set_ruler_height(val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "tooltip"
      },
      vb:textfield{
        id = "vView_tooltip",
        text = "",
        notifier = function(val)
          set_control_property("tooltip",val)
        end
      },
    },
  })

end

-------------------------------------------------------------------------------

function build_vcontrol()
  TRACE("build_vcontrol()")

  vb.views.basic_row:add_child(vb:column{
    style = "panel",
    vb:row{
      vb:text{
        text = "vControl",
        font = "bold",
      },
    },
    vb:row{
      vb:text{
        text = "active"
      },
      vb:checkbox{
        id = "vControl_active",
        value = true,
        notifier = function(val)
          set_control_property("active",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "midi_mapping"
      },
      vb:textfield{
        id = "vControl_midi_mapping",
        text = "",
        notifier = function(val)
          set_control_property("midi_mapping",val)
        end
      },
    },
  })

end

-------------------------------------------------------------------------------

function build_vbutton()
  TRACE("build_vbutton()")

  vb.views.props_row:add_child(vb:column{
    id = "vButton_properties",
    style = "panel",
    vb:text{
      text = "vButton",
      font = "bold",
    },
    vb:text{
      text = [[
The button component is the most basic button in vLib,
functionally similar to the renoise Viewbuilder version]],
      font = "italic",
    },

    vb:row{
      vb:text{
        text = "text"
      },
      vb:textfield{
        id = "vButton_text",
        width = 120,
        --text = "",
        notifier = function(str_val)
          set_control_property("text",str_val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "color"
      },
      vb:textfield{
        id = "vButton_color",
        width = 120,
        --text = "0xFF00FF",
        notifier = function(val)
          set_color_property("color",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "bitmap"
      },
      vb:textfield{
        id = "vButton_bitmap",
        width = 120,
        --text = "",
        notifier = function()
          local str_path = vb.views.vButton_bitmap.text
          set_control_property("bitmap",str_path)
        end
      },
    },
    vb:row{
      vb:text{
        text = "-- Methods ---------"
      },
    },
    vb:row{
      vb:button{
        text = "press()",
        notifier = function()
          vbutton:press()
        end
      }
    },
    vb:row{
      vb:button{
        text = "release()",
        notifier = function()
          vbutton:release()
        end
      }
    },

  })

  vbutton = vButton{
    vb = vb,
    id = "vButton",
    tooltip = "vButton",
    text = "Some text",
    midi_mapping = "Global:vButton:vLib_demo",
    bitmap = "./icons/AdvancedEdit.bmp",
    color = {0xFF,0x00,0xFF},
    width = 100,
    --height = 25,
    notifier = function()
      --print("vbutton.notifier()")
    end,
    pressed = function()
      --print("vbutton.pressed()")
    end,
    released = function()
      --print("vbutton.released()")
    end,
    on_resize = function()
      --print("vbutton.on_resize()")
    end,
  }
  vb.views.controls_col:add_child(vbutton.view)
  table.insert(vlib_controls_ref,vbutton)
  table.insert(vlib_controls,vbutton.id)

end



-------------------------------------------------------------------------------

function build_vtogglebutton()
  TRACE("build_vtogglebutton()")

  vb.views.props_row:add_child(vb:column{
    id = "vToggleButton_properties",
    style = "panel",
    vb:text{
      text = "vToggleButton",
      font = "bold",
    },
    vb:text{
      text = [[
The toggle button is a simple state-switching button
with independant settings for the on/off state]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "enabled"
      },
      vb:checkbox{
        id = "vToggleButton_enabled",
        notifier = function(val)
          set_control_property("enabled",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "text_enabled"
      },
      vb:textfield{
        id = "vToggleButton_text_enabled",
        width = 120,
        notifier = function(str_val)
          set_control_property("text_enabled",str_val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "text_disabled"
      },
      vb:textfield{
        id = "vToggleButton_text_disabled",
        width = 120,
        notifier = function(str_val)
          set_control_property("text_disabled",str_val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "color_enabled"
      },
      vb:textfield{
        id = "vToggleButton_color_enabled",
        width = 120,
        notifier = function(val)
          set_color_property("color_enabled",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "color_disabled"
      },
      vb:textfield{
        id = "vToggleButton_color_disabled",
        width = 120,
        notifier = function(val)
          set_color_property("color_disabled",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "bitmap_enabled"
      },
      vb:textfield{
        id = "vToggleButton_bitmap_enabled",
        width = 120,
        notifier = function(val)
          set_control_property("bitmap_enabled",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "bitmap_disabled"
      },
      vb:textfield{
        id = "vToggleButton_bitmap_disabled",
        width = 120,
        notifier = function(val)
          set_control_property("bitmap_disabled",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "-- Methods ---------"
      },
    },
    vb:row{
      vb:button{
        text = "toggle()",
        notifier = function()
          vtogglebutton:toggle()
        end
      }
    },

  })

  vtogglebutton = vToggleButton{
    vb = vb,
    id = "vToggleButton",
    tooltip = "vToggleButton",
    midi_mapping = "Global:vToggleButton:vLib_demo",
    text_enabled = "Foo",
    text_disabled = "Bar",
    color_enabled = {0xFF,0xFF,0xFF},
    color_disabled = {0x11,0x11,0x11},
    bitmap_enabled = "./icons/AdvancedEdit.bmp",
    width = 50,
    height = 20,
    notifier = function(active)
      --print("vtogglebutton.notifier - active",active)
    end,
    on_resize = function()
      --print("vtogglebutton.on_resize")
    end,
  }
  vtogglebutton.enabled_observable:add_notifier(function()
    --print(">>> vtogglebutton.enabled_observable fired")
    vb.views["vToggleButton_enabled"].value = vtogglebutton.enabled
  end)

  vb.views.controls_col:add_child(vtogglebutton.view)
  table.insert(vlib_controls_ref,vtogglebutton)
  table.insert(vlib_controls,vtogglebutton.id)

end


-------------------------------------------------------------------------------

function build_varrowbutton()
  TRACE("build_varrowbutton()")

  vb.views.props_row:add_child(vb:column{
    id = "vArrowButton_properties",
    style = "panel",
    vb:text{
      text = "vArrowButton",
      font = "bold",
    },
    vb:text{
      text = [[
The arrow-button is a toggle button which has been  
modified to look like this common UI element]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "enabled"
      },
      vb:checkbox{
        id = "vArrowButton_enabled",
        --value = true,
        notifier = function(val)
          set_control_property("enabled",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "flipped"
      },
      vb:checkbox{
        id = "vArrowButton_flipped",
        --value = true,
        notifier = function(val)
          set_control_property("flipped",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "orientation"
      },
      vb:popup{
        id = "vArrowButton_orientation",
        value = 1,
        items = {"HORIZONTAL","VERTICAL"},
        notifier = function(val)
          set_control_property("orientation",val)
        end
      },
    },

  })

  varrowbutton = vArrowButton{
    vb = vb,
    id = "vArrowButton",
    tooltip = "vArrowButton",
    midi_mapping = "Global:vArrowButton:vLib_demo",
    --width = 50,
    --height = 20,
    notifier = function(active)
      --print("varrowbutton.notifier - active",active)
    end,
    on_resize = function()
      --print("varrowbutton.on_resize")
    end,
  }
  varrowbutton.enabled_observable:add_notifier(function()
    --print(">>> varrowbutton.enabled_observable fired")
    vb.views["vArrowButton_enabled"].value = varrowbutton.enabled
  end)

  vb.views.controls_col:add_child(varrowbutton.view)
  table.insert(vlib_controls_ref,varrowbutton)
  table.insert(vlib_controls,varrowbutton.id)

end


-------------------------------------------------------------------------------

function build_vtabs()
  TRACE("build_vtabs()")

  --[[
  vb.views.props_row:add_child(vb:column{
    style = "plain",
    width = 300,
    vb:horizontal_aligner{
      mode = "center",
      vb:button{
        width = 100,
      },
    },
  })
  ]]


  vb.views.props_row:add_child(vb:column{
    id = "vTabs_properties",
    style = "panel",
    vb:text{
      text = "vTabs",
      font = "bold",
    },
    vb:text{
      text = [[
This component allows you to toggle between views,
using the familiar tabbed interface]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "index"
      },
      vb:valuebox{
        id = "vTabs_index",
        value = 1,
        notifier = function(val)
          set_control_property("index",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "layout"
      },
      vb:popup{
        id = "vTabs_layout",
        value = 1,
        items = {"ABOVE","BELOW"},
        notifier = function(val)
          set_control_property("layout",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "switcher_width"
      },
      vb:valuebox{
        id = "vTabs_switcher_width",
        value = 100,
        min = 1,
        max = 1000,
        notifier = function(val)
          set_control_property("switcher_width",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "switcher_height"
      },
      vb:valuebox{
        id = "vTabs_switcher_height",
        value = 100,
        min = 1,
        max = 1000,
        notifier = function(val)
          set_control_property("switcher_height",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "switcher_align"
      },
      vb:popup{
        id = "vTabs_switcher_align",
        value = 1,
        items = {"LEFT","CENTER","RIGHT"},
        notifier = function(val)
          set_control_property("switcher_align",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "size_method"
      },
      vb:popup{
        id = "vTabs_size_method",
        value = vTabs.SIZE_METHOD.CURRENT,
        items = {"FIXED","CURRENT","LARGEST"},
        notifier = function(val)
          set_control_property("size_method",val)
        end
      },
    },
  })

  vtabs = vTabs{
    vb = vb,
    id = "vTabs",
    tooltip = "vTabs",
    index = 1,
    midi_mapping = "Global:vTabs:vLib_demo",
    labels = {"1","2","3","4"},
    width = 390,
    height = 175,
    layout = vTabs.LAYOUT.BELOW,
    size_method = vTabs.SIZE_METHOD.FIXED,
    switcher_align = vTabs.SWITCHER_ALIGN.LEFT,
    switcher_width = 150,
    switcher_height = 24,
    tabs = {
      vb:column{
        width = 390,
        height = 390,
        style = "panel",
        vb:row{
          vb:multiline_text {
            text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut ornare suscipit felis, sed porttitor est scelerisque id. Curabitur sit amet quam mi. Nunc vel purus a orci rhoncus gravida vel vel nibh. Curabitur lorem felis, pharetra vel ex eget, fermentum porttitor eros. Integer efficitur diam id urna sollicitudin posuere. Morbi nisi neque, finibus ut nunc luctus, pellentesque maximus diam. Morbi et fermentum felis. Donec tempus mollis mattis. Integer eget eros in felis vehicula accumsan sed ac elit. Donec rhoncus lorem sed justo faucibus rhoncus. Aliquam tempor, orci vitae vulputate ullamcorper, enim nunc auctor purus, quis varius neque risus porttitor quam. Sed in elit augue. \n\nUt non purus nec orci molestie accumsan. Quisque eget blandit felis. Aliquam laoreet lectus sit amet quam blandit maximus. Fusce vitae lectus sit amet neque dictum elementum. Suspendisse blandit a dolor vitae euismod. Integer condimentum neque velit, vel ornare sapien porta eu. Curabitur porta dui et nisi laoreet, vitae dictum mi pulvinar. Morbi finibus orci et massa imperdiet semper. Pellentesque sed metus vitae ante pulvinar feugiat. Nulla eu ultricies sapien, vitae placerat enim. Sed ligula dui, lacinia ac enim in, condimentum vestibulum elit. Nulla ullamcorper magna sit amet tortor posuere, maximus aliquet nibh posuere. Aliquam rutrum lorem in ex hendrerit, at cursus mauris rhoncus. Phasellus condimentum, nisl sed rhoncus consectetur, lacus metus sodales erat, vel pharetra lorem urna eget sapien. Aliquam lorem tortor, sodales vel semper vitae, vulputate in orci.",
            width = 190,
            height = 150,
          },
          vb:multiline_text {
            text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Ut ornare suscipit felis, sed porttitor est scelerisque id. Curabitur sit amet quam mi. Nunc vel purus a orci rhoncus gravida vel vel nibh. Curabitur lorem felis, pharetra vel ex eget, fermentum porttitor eros. Integer efficitur diam id urna sollicitudin posuere. Morbi nisi neque, finibus ut nunc luctus, pellentesque maximus diam. Morbi et fermentum felis. Donec tempus mollis mattis. Integer eget eros in felis vehicula accumsan sed ac elit. Donec rhoncus lorem sed justo faucibus rhoncus. Aliquam tempor, orci vitae vulputate ullamcorper, enim nunc auctor purus, quis varius neque risus porttitor quam. Sed in elit augue. \n\nUt non purus nec orci molestie accumsan. Quisque eget blandit felis. Aliquam laoreet lectus sit amet quam blandit maximus. Fusce vitae lectus sit amet neque dictum elementum. Suspendisse blandit a dolor vitae euismod. Integer condimentum neque velit, vel ornare sapien porta eu. Curabitur porta dui et nisi laoreet, vitae dictum mi pulvinar. Morbi finibus orci et massa imperdiet semper. Pellentesque sed metus vitae ante pulvinar feugiat. Nulla eu ultricies sapien, vitae placerat enim. Sed ligula dui, lacinia ac enim in, condimentum vestibulum elit. Nulla ullamcorper magna sit amet tortor posuere, maximus aliquet nibh posuere. Aliquam rutrum lorem in ex hendrerit, at cursus mauris rhoncus. Phasellus condimentum, nisl sed rhoncus consectetur, lacus metus sodales erat, vel pharetra lorem urna eget sapien. Aliquam lorem tortor, sodales vel semper vitae, vulputate in orci.",
            width = 190,
            height = 150,
          },
        }
      },


      vb:column{
        style = "plain",
        vb:text {
          text = "Two"
        }
      },
      vb:column{
        style = "group",
        vb:text {
          text = "Three"
        }
      },
      vb:column{
        style = "body",
        vb:text {
          text = "Four"
        }
      },
    },
    notifier = function(idx)
      --print("vtabs.notifier - idx",idx)
    end,
    on_resize = function()
      --print("vtabs.on_resize")
      suppress_notifier = true
      vb.views.vView_width.value = vtabs.width
      vb.views.vView_height.value = vtabs.height
      suppress_notifier = false
    end,
  }
  vb.views.controls_col:add_child(vtabs.view)
  table.insert(vlib_controls_ref,vtabs)
  table.insert(vlib_controls,vtabs.id)

end

-------------------------------------------------------------------------------

function build_vtable()
  TRACE(">>> build_vtable()")


  vb.views.props_row:add_child(vb:column{
    id = "vTable_properties",
    style = "panel",
    vb:text{
      text = "vTable",
      font = "bold",
    },
    vb:text{
      text = [[
A highly configurable table class that supports all the basic
components (text, number, checkbox etc.)]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "autosize"
      },
      vb:checkbox{
        id = "vTable_autosize",
        value = true,
        notifier = function(val)
          set_control_property("autosize",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "num_rows"
      },
      vb:valuebox{
        id = "vTable_num_rows",
        value = 1,
        notifier = function(val)
          set_control_property("num_rows",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "row_height"
      },
      vb:valuebox{
        id = "vTable_row_height",
        value = 24,
        min = 1,
        max = 100,
        notifier = function(val)
          set_control_property("row_height",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "row_offset"
      },
      vb:valuebox{
        id = "vTable_row_offset",
        value = 0,
        min = 0,
        max = 100,
        notifier = function(val)
          set_control_property("row_offset",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "header_height"
      },
      vb:valuebox{
        id = "vTable_header_height",
        value = 24,
        min = 1,
        max = 100,
        notifier = function(val)
          set_control_property("header_height",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "scrollbar_width"
      },
      vb:valuebox{
        id = "vTable_scrollbar_width",
        value = 20,
        min = 1,
        max = 100,
        notifier = function(val)
          set_control_property("scrollbar_width",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "show_header"
      },
      vb:checkbox{
        id = "vTable_show_header",
        value = true,
        notifier = function(val)
          set_control_property("show_header",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "data"
      },
      vb:multiline_textfield{
        id = "vTable_data",
        width = 450,
        height = 200,
        text = "",
      },
    },
    vb:row{
      vb:button{
        text = "set data",
        width = 50,
        notifier = function()
          local str_data = vb.views.vTable_data.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            set_control_property("data",t)
          end
        end
      },
      vb:button{
        text = "call set_data() - preserve pos",
        width = 50,
        notifier = function()
          local str_data = vb.views.vTable_data.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            --set_control_property("data",t)
            --vtable:set_data(t,true)
            vtable.data = t
          end
        end

      },
    },

    vb:row{
      vb:text{
        text = "-- Methods ---------"
      },
    },

    vb:row{
      vb:button{
        text = "set_column_def() - TEXT:col_width='auto'",
        width = 50,
        notifier = function()
          vtable:set_column_def("TEXT","col_width","auto")
          vtable:update()
        end
      },
      vb:button{
        text = "set_column_def() - TEXT:col_width=100",
        width = 50,
        notifier = function()
          vtable:set_column_def("TEXT","col_width",100)
          vtable:update()
        end

      },
    },

    vb:row{
      vb:button{
        text = "set_header_def() - CHECKBOX:active=true",
        width = 50,
        notifier = function()
          vtable:set_header_def("CHECKBOX","active",true)
          vtable:update()
        end
      },
      vb:button{
        text = "set_header_def() - CHECKBOX:active=false",
        width = 50,
        notifier = function()
          vtable:set_header_def("CHECKBOX","active",false)
          vtable:update()
        end

      },
    },
    vb:row{
      vb:button{
        text = "set_header_def() - CHECKBOX:value=true",
        width = 50,
        notifier = function()
          vtable:set_header_def("CHECKBOX","value",true)
          vtable:update()
        end
      },
      vb:button{
        text = "set_header_def() - CHECKBOX:value=false",
        width = 50,
        notifier = function()
          vtable:set_header_def("CHECKBOX","value",false)
          vtable:update()
        end

      },
    },

  })

  local handle_header_checked = function(elm,checked)
    --print("handle_header_checked(elm,checked)",elm,checked)
    vtable.header_defs.CHECKBOX.data = checked
    for k,v in ipairs(vtable.data) do
      v.CHECKBOX = checked
    end
    vtable:request_update()
  end

  local handle_table_checked = function(elm,checked)
    --print("handle_table_checked(elm,checked)",elm,checked)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.CHECKBOX = checked
      vb.views.vTable_data.text = cString.table_to_string(elm.owner.data)
    end
  end

  local handle_table_button = function(elm)
    --print("handle_table_button",elm)
  end

  local handle_table_popup = function(elm,val)
    --print("handle_table_popup",elm,val)
    --local item = vVector.match_by_key_value(elm.owner.data,"item_id",elm.item_id)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.POPUP = val
      vb.views.vTable_data.text = cString.table_to_string(elm.owner.data)
    end
  end

  local handle_table_valuebox = function(elm,val)
    --print("handle_table_valuebox",elm,val)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      --elm.owner.data[elm.item_id].VALUEBOX = val
      item.VALUEBOX = val
      vb.views.vTable_data.text = cString.table_to_string(elm.owner.data)
    end
  end

  vtable = vTable{
    id = "vTable",
    vb = vb,
    --width = 400,
    --height = 300,
    --scrollbar_width = 30,
    --row_height = 24,
    --header_height = 30,
    --show_header = true,
    --num_rows = 8,
    column_defs = {
      {key = "BITMAP",    col_width=25, col_type=vTable.CELLTYPE.BITMAP, tooltip="This is a bitmap"},
      {key = "TEXT",    col_width="auto", tooltip="This is some text"},
      {key = "CHECKBOX", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, tooltip="This is a checkbox", notifier=handle_table_checked},
      {key = "BUTTON", col_width="15%", col_type=vTable.CELLTYPE.BUTTON, tooltip="This is a button", pressed=handle_table_button},
      {key = "POPUP", col_width=90, col_type=vTable.CELLTYPE.POPUP, tooltip="This is a popup", items={"One","Two","Three"}, notifier=handle_table_popup},
      {key = "VALUEBOX", col_width=60, col_type=vTable.CELLTYPE.VALUEBOX, tooltip="This is a valuebox", notifier=handle_table_valuebox},
    },
    header_defs = {
      CHECKBOX = {col_type=vTable.CELLTYPE.CHECKBOX, active=true, notifier=handle_header_checked},
    },
    data = {
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = '1b',  CHECKBOX=true,  BUTTON='1d',  POPUP = 1,    VALUEBOX = 1.5},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = '2b',  CHECKBOX=true,  BUTTON='2c',  POPUP = nil,  VALUEBOX = nil},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = '3b',  CHECKBOX=true,  BUTTON='3c'},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = '4b',  CHECKBOX=false, BUTTON=nil},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = 'Here is a long line which should be readable only by its tooltip (how are you reading this?)',  CHECKBOX=false, BUTTON=nil},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = nil,   CHECKBOX=false, BUTTON='6c'},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = nil,   CHECKBOX=true,  BUTTON='7c'},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = '8b',  CHECKBOX=nil,   BUTTON='8c'},
      {BITMAP = "Icons/Browser_TextFile.bmp", TEXT = '9b',  CHECKBOX=nil,   BUTTON='9c'},
    },
    on_scroll = function()
      --print("on_scroll()")
      
    end,
    on_resize = function(elm)
      --print("on_resize() - vtable.height",vtable.height)
      suppress_notifier = true
      vb.views.vView_width.value = elm.width
      vb.views.vView_height.value = elm.height
      suppress_notifier = false
    end,
  }
  vb.views.controls_col:add_child(vtable.view)
  --print(">>> vtable.data",rprint(vtable.data))
  --vtable:update()
  table.insert(vlib_controls_ref,vtable)
  table.insert(vlib_controls,vtable.id)

end

-------------------------------------------------------------------------------

function build_vfilebrowser()
  TRACE("build_vfilebrowser()")

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vFileBrowser_properties",
    style = "panel",
    vb:text{
      text = "vFileBrowser",
      font = "bold",
    },
    vb:text{
      text = [[
The file-browser looks and works much like the native counterpart,
but is based around the vTable component]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },

    vb:row{
      vb:text{
        text = "num_rows"
      },
      vb:valuebox{
        id = "vFileBrowser_num_rows",
        value = 1,
        notifier = function(val)
          set_control_property("num_rows",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "show_header"
      },
      vb:checkbox{
        id = "vFileBrowser_show_header",
        value = true,
        notifier = function(val)
          set_control_property("show_header",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "path"
      },
      vb:textfield{
        id = "vFileBrowser_path",
        width = 150,
        text = "",
      },
      vb:button{
        text = "set",
        width = 40,
        notifier = function()
          local str_path = vb.views.vFileBrowser_path.text
          set_control_property("path",str_path)
        end
      },

    },

    vb:row{
      vb:text{
        text = "file_types"
      },
      vb:multiline_textfield{
        id = "vFileBrowser_file_types",
        width = 450,
        height = 100,
        text = "",
      },
      vb:button{
        text = "set ",
        width = 50,
        notifier = function()
          local str_data = vb.views.vFileBrowser_file_types.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            set_control_property("file_types",t)
          end
        end
      },

    },

    vb:row{
      vb:text{
        text = "file_ext"
      },
      vb:textfield{
        id = "vFileBrowser_file_ext",
        width = 120,
        text = file_ext,
      },
      vb:button{
        text = "set ",
        width = 50,
        notifier = function()
          local str_data = vb.views.vFileBrowser_file_ext.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            set_control_property("file_ext",t)
          end
        end
      },
    },
    vb:row{
      vb:text{
        text = "-- Methods ------------"
      },
    },
    vb:row{
      vb:text{
        text = "browse_path()"
      },
      vb:button{
        text = "browse...",
        width = 60,
        notifier = function()
          vbrowser:browse_path()
        end
      },
    },
    vb:row{
      vb:text{
        text = "create_folder"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function()
          vbrowser:create_directory()
        end
      },

    },
    vb:row{
      vb:text{
        text = "parent_directory()"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function()
          vbrowser:parent_directory()
        end
      },

    },
    vb:row{
      vb:text{
        text = "delete_files()"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function()
          vbrowser:delete_files()
        end
      },

    },
    vb:row{
      vb:text{
        text = "rename_file()"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function()
          vbrowser:rename_file()
        end
      },

    },

  })

  -- class callbacks
  local press_handler = function()

  end

  -- class definition
  vbrowser = vFileBrowser{
    vb = vb,
    id = "vFileBrowser",
    width = 340,
    height = 300,
    num_rows = 12,
    --path = "/",
    --file_ext = {'*.wav', '*.txt'},
    file_types = {
      {name = "xrnt", icon = "Icons/Browser_RenoiseDeviceChainFile.bmp"},
      {name = "xrni", icon = "Icons/Browser_RenoiseInstrumentFile.bmp"},
      {name = "xrno", icon = "Icons/Browser_RenoiseModulationSetFile.bmp"},
      {name = "sfz", icon = "Icons/Browser_RenoiseInstrumentFile.bmp",on_press=press_handler},
      {name = "xrnz", icon = "Icons/Browser_RenoisePhraseFile.bmp"},
      {name = "flac", icon = "Icons/Browser_AudioFile.bmp"},
    },
    on_checked = function()
      
    end,
    on_changed_path = function()
      suppress_notifier = true
      vb.views.vFileBrowser_path.text = vbrowser.path
      suppress_notifier = false
    end,
    on_resize = function()
      --print("vbrowser.on_resize")
      suppress_notifier = true
      vb.views.vView_width.value = vbrowser.width
      vb.views.vView_height.value = vbrowser.height
      suppress_notifier = false
    end,

  }
  vb.views.controls_col:add_child(vbrowser.view)
  table.insert(vlib_controls_ref,vbrowser)
  table.insert(vlib_controls,vbrowser.id)

  vbrowser:refresh()

end

-------------------------------------------------------------------------------

function build_vtree()

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vTree_properties",
    style = "panel",
    vb:text{
      text = "vTree",
      font = "bold",
    },
    vb:text{
      text = [[
The tree component can display hierarchical structures,
can load/parse XML documents and lua tables]],
      font = "italic",
    },

    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },
    vb:row{
      vb:text{
        text = "autosize"
      },
      vb:checkbox{
        id = "vTree_autosize",
        value = true,
        notifier = function(val)
          set_control_property("autosize",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "num_rows"
      },
      vb:valuebox{
        id = "vTree_num_rows",
        value = 1,
        notifier = function(val)
          set_control_property("num_rows",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "row_height"
      },
      vb:valuebox{
        id = "vTree_row_height",
        value = 20,
        min = 1,
        max = 100,
        notifier = function(val)
          set_control_property("row_height",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "indent"
      },
      vb:valuebox{
        id = "vTree_indent",
        value = 20,
        min = 0,
        max = 100,
        notifier = function(val)
          set_control_property("indent",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "-- Methods ---------"
      },
    },
    vb:row{
      vb:text{
        text = "load_file"
      },
      vb:button{
        id = "vTree_load_file",
        text = "browse...",
        notifier = function(val)
          vtree:load_file()
        end
      },

    },


  })

  -- class callbacks

  local vtree_toggle_node = function(elm,item)
    local choice = renoise.app():show_prompt("Toggle node","Do you want to toggle this node?\n\nThis event was triggered from the vTree node you just clicked",{"Ok","Cancel"})
    if (choice == "Ok") then
      item.expanded = not item.expanded
      vtree:update()
    end
  end

  local vtree_select_node = function(elm,item)
    local choice = renoise.app():show_message("You triggered the select event for a node")
  end

  -- class definition

  vtree = vTree{
    vb = vb,
    id = "vTree",
    width = 340,
    height = 200,
    num_rows = 12,
    data = {
      name = "Root",
      {
        name = "Node",
        expanded = true,
        {
          name = "Item #1",
        },
        {
          name = "Item #2",
        }
      },
      {
        name = "Node with toggle event",
        expanded = false,
        on_toggle = vtree_toggle_node,
        {
          name = "Item #1",
        },
        {
          name = "Item #2",
        },
      },
      {
        name = "Node with select event",
        expanded = false,
        on_select = vtree_select_node,
        {
          name = "Item #1",
        },
        {
          name = "Item #2",
        },
      },
      {
        name = "Node",
        {
          name = "Item #1",
        },
        {
          name = "Item #2",
        },
        {
          name = "Item #3",
        },
        {
          name = "Item #4",
        },
        {
          name = "Item #5",
        },
        {
          name = "Item #6",
        },
        {
          name = "Item #7",
        },
        {
          name = "Item #8",
        },
        {
          name = "Item #9",
        },
      },
    },
    on_resize = function()
      --print("vtree.on_resize")
      suppress_notifier = true
      vb.views.vView_width.value = vtree.width
      vb.views.vView_height.value = vtree.height
      suppress_notifier = false
    end,

  }

  vb.views.controls_col:add_child(vtree.view)
  table.insert(vlib_controls_ref,vtree)
  table.insert(vlib_controls,vtree.id)

end

-------------------------------------------------------------------------------

function build_vlog()

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vLogView_properties",
    style = "panel",

    vb:row{
      vb:text{
        text = "vLogView",
        font = "bold",
      },
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },
    vb:row{
      vb:text{
        text = "text"
      },
      vb:multiline_textfield{
        id = "vLogView_text",
        width = 450,
        height = 200,
      },
      vb:button{
        text = "set ",
        width = 50,
        notifier = function()
          set_control_property("text",vb.views.vLogView_text.text)
        end
      },
    },

    vb:row{
      vb:text{
        text = "autoscroll"
      },
      vb:checkbox{
        id = "vLogView_autoscroll",
        value = true,
        notifier = function(val)
          set_control_property("autoscroll",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "-- Methods ------------"
      },
    },
    vb:row{
      vb:text{
        text = "add()"
      },
      vb:multiline_textfield{
        id = "vLogView_add",
        width = 350,
        height = 60,
      },
      vb:button{
        text = "set",
        notifier = function(val)
          local str_text = vb.views.vLogView_add.text
          vlog:add(str_text)
        end
      },
    },
    vb:row{
      vb:text{
        text = "replace()"
      },
      vb:textfield{
        id = "vLogView_replace",
        width = 350,
      },
      vb:button{
        text = "set",
        notifier = function(val)
          local str_text = vb.views.vLogView_replace.text
          vlog:replace(str_text)
        end
      },
    },

    vb:row{
      vb:text{
        text = "clear()"
      },
      vb:textfield{
        id = "vLogView_clear",
        width = 350,
      },
      vb:button{
        text = "clear",
        notifier = function(val)
          vlog:clear()
        end
      },
    },

  })


  -- class definition
  vlog = vLogView{
    vb = vb,
    id = "vLogView",
    width = 340,
    height = 300,
    autoscroll = true,
    text = "Hello World!",
  }

  vb.views.controls_col:add_child(vlog.view)
  table.insert(vlib_controls_ref,vlog)
  table.insert(vlib_controls,vlog.id)


end

-------------------------------------------------------------------------------

function build_vgraph()

  -- class definition
  vgraph = vGraph{
    vb = vb,
    id = "vGraph",
    width = 340,
    height = 100,
    draw_mode = vGraph.DRAW_MODE.BIPOLAR,
    value_min = -2,
    value_max = 2,
    require_selection = false,
    select_mode = vSelection.SELECT_MODE.MULTIPLE,
    style_normal = "body_color",
    style_selected = "plain",
    data = {
      0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0,
      --0.6224997,0.7980488,0.2683922,0.2288316,0.5307403,0.3161451,0.0802400,0.3541377,0.7341269,0.2672030,0.0456188,0.3612416,0.9044369,0.4855384,0.0348798,0.3559853,0.8462828,0.7415555,0.7684338,0.0889788,0.3666197,0.8304925,0.5524690,0.9613370,0.4626106,0.3623380,0.4424030,0.6534640,0.4216029,0.9716702,0.1778191,0.8456344,0.9269630,0.1661676,0.7326378,0.9991209,0.7635204,0.5325416,0.8242715,0.666619,0.216371,0.518641,0.225514,0.300719,0.756794,0.510478,0.222916,0.029176,0.109016,0.422928,0.065392,0.365721,0.291602,0.522847,0.746813,0.325178,0.727191,0.703367,0.966333,0.911621,0.014349,0.928105,0.610205,0.610205,
      --0.6224997,0.7980488,0.2683922,0.2288316,0.5307403,0.3161451,0.0802400,0.3541377,0.7341269,0.2672030,0.0456188,0.3612416,0.9044369,0.4855384,0.0348798,0.3559853,0.8462828,0.7415555,0.7684338,0.0889788,0.3666197,0.8304925,0.5524690,0.9613370,0.4626106,0.3623380,0.4424030,0.6534640,0.4216029,0.9716702,0.1778191,0.8456344,0.9269630,0.1661676,0.7326378,0.9991209,0.7635204,0.5325416,0.8242715,0.666619,0.216371,0.518641,0.225514,0.300719,0.756794,0.510478,0.222916,0.029176,0.109016,0.422928,0.065392,0.365721,0.291602,0.522847,0.746813,0.325178,0.727191,0.703367,0.966333,0.911621,0.014349,0.928105,0.610205,0.610205,
    },
    click_notifier = function(elm,idx)
      --print("vgraph.click_notifier - elm,index",elm,index)
      if (elm.select_mode == vSelection.SELECT_MODE.SINGLE) then
        if elm.require_selection then
          elm.selected_index = idx
        else
          -- toggle selection
          if (idx == elm.selected_index) then
            elm.selected_index = (elm.selected_index == 0) and idx or 0
          else
            elm.selected_index = idx
          end
        end
      else
        --local changed,added,removed = elm.selection:toggle_index(idx)
        --elm:selection_handler(changed,added,removed)
        elm:toggle_index(idx)
      end

    end,
    selection_notifier = function(elm)
      suppress_notifier = true
      vb.views.vGraph_selected_index.value = elm.selected_index
      vb.views.vGraph_selected_indices.value = cString.table_to_string(active_ctrl.selected_indices,{number_format = "%.0f"})

      -- update the "set value" slider
      local data_item = elm:get_selected_item()
      if data_item then
        local scaled_val = cLib.scale_value(data_item,vgraph.value_min,vgraph.value_max,0,1)
        vb.views.vGraph_selected_value.value = scaled_val
        vb.views.vGraph_selected_value_readout.value = scaled_val
      end

      suppress_notifier = false
    end,
  }

  vb.views.controls_col:add_child(vgraph.view)
  table.insert(vlib_controls_ref,vgraph)
  table.insert(vlib_controls,vgraph.id)

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vGraph_properties",
    style = "panel",

    vb:row{
      vb:text{
        text = "vGraph",
        font = "bold",
      },
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },
    vb:row{
      vb:text{
        text = "selected_index"
      },
      vb:valuebox{
        id = "vGraph_selected_index",
        value = -1,
        min = -1,
        max = 100000,
        notifier = function(val)
          --print("vGraph_selected_index.notifier...",val)
          set_control_property("selected_index",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "selected_indices"
      },
      vb:textfield{
        id = "vGraph_selected_indices",
        width = 150,
        --height = 200,
        text = "",
      },
      vb:button{
        text = "set",
        width = 50,
        notifier = function()
          local str_data = vb.views.vGraph_selected_indices.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            set_control_property("selected_indices",t)
          end
        end
      },
    },
    vb:row{
      vb:text{
        text = "require_selection"
      },
      vb:checkbox{
        id = "vGraph_require_selection",
        value = vgraph.require_selection,
        notifier = function(val)
          set_control_property("require_selection",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "draw_mode"
      },
      vb:popup{
        id = "vGraph_draw_mode",
        items = {"UNIPOLAR","UNIPOLAR2 (mirrored)","BIPOLAR"},
        width = 150,
        notifier = function(val)
          set_control_property("draw_mode",val)
        end
      },
    }, 
    vb:row{
      vb:text{
        text = "select_mode"
      },
      vb:popup{
        id = "vGraph_select_mode",
        items = table.keys(vSelection.SELECT_MODE),
        value = vgraph.select_mode,
        width = 150,
        notifier = function(val)
          set_control_property("select_mode",val)
        end
      },
    }, 

    vb:row{
      vb:text{
        text = "value_min"
      },
      vb:valuebox{
        id = "vGraph_value_min",
        width = 100,
        value = vgraph.value_min,
        min = -1000,
        max = 1000,
        notifier = function(val)
          set_control_property("value_min",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "value_max"
      },
      vb:valuebox{
        id = "vGraph_value_max",
        width = 100,
        value = vgraph.value_max,
        min = -1000,
        max = 1000,
        notifier = function(val)
          set_control_property("value_max",val)
        end
      },
    },
    --[[
    vb:row{
      vb:text{
        text = "normalized"
      },
      vb:checkbox{
        id = "vGraph_normalized",
        value = vgraph.normalized,
        notifier = function(val)
          set_control_property("normalized",val)
        end
      },
    },
    ]]
    vb:row{
      vb:text{
        text = "style_normal"
      },
      vb:popup{
        id = "vGraph_style_normal",
        items = vLib.BITMAP_STYLES,
        width = 50,
        notifier = function(idx)
          local style = table.values(vLib.BITMAP_STYLES)[idx]
          set_control_property("style_normal",style)
        end
      },
    },    
    vb:row{
      vb:text{
        text = "style_selected"
      },
      vb:popup{
        id = "vGraph_style_selected",
        items = vLib.BITMAP_STYLES,
        width = 50,
        notifier = function(idx)
          local style = table.values(vLib.BITMAP_STYLES)[idx]
          set_control_property("style_selected",style)
        end
      },
    },    
    vb:row{
      vb:text{
        text = "data"
      },
      vb:multiline_textfield{
        id = "vGraph_data",
        width = 450,
        height = 200,
        text = "",
      },
    },
    vb:row{
      vb:button{
        text = "set data",
        width = 50,
        notifier = function()
          local str_data = vb.views.vGraph_data.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            set_control_property("data",t)
          end
        end
      },
      vb:button{
        text = "clear data",
        width = 50,
        notifier = function()
          set_control_property("data",{})
        end

      },
    },
    

    vb:row{
      vb:text{
        text = "-- Methods ------------"
      },
    },

    vb:row{
      vb:text{
        text = "set_value(min-max)"
      },
      vb:minislider{
        id = "vGraph_selected_value",
        width = 100,
        value = 0,
        min = 0,
        max = 1,
        notifier = function(val)
          --print("vGraph_selected_value.notifier",val)
          local scaled_val = cLib.scale_value(val,0,1,vgraph.value_min,vgraph.value_max)
          local idx = vgraph.selected_index
          vgraph:set_value(idx,scaled_val)
          vb.views.vGraph_selected_value_readout.value = scaled_val
        end
      },
      vb:value{
        id = "vGraph_selected_value_readout",
        width = 50,
        value = 0,
      },
    },

    vb:row{
      vb:text{
        text = "clear_selection()"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function(val)
          vgraph:clear_selection()
        end
      },
    },

    vb:row{
      vb:text{
        text = "select_all()"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function(val)
          vgraph:select_all()
        end
      },
    },


  })



end

-------------------------------------------------------------------------------

function build_vpathselector()

  -- class definition
  vpathselector = vPathSelector{
    vb = vb,
    id = "vPathSelector",
    width = 240,
    --height = 30,
  }

  vb.views.controls_col:add_child(vpathselector.view)
  table.insert(vlib_controls_ref,vpathselector)
  table.insert(vlib_controls,vpathselector.id)

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vPathSelector_properties",
    style = "panel",
    vb:row{
      vb:text{
        text = "vPathSelector",
        font = "bold",
      },
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },
    vb:row{
      vb:text{
        text = "editable"
      },
      vb:checkbox{
        id = "vPathSelector_editable",
        notifier = function(val)
          --print("vPathSelector_editable.notifier...",val)
          set_control_property("editable",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "mode"
      },
      vb:popup{
        id = "vPathSelector_mode",
        items = {
          "File",
          "Folder",
        },
        notifier = function(val)
          set_control_property("mode",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "path"
      },
      vb:textfield{
        id = "vPathSelector_path",
        notifier = function(val)
          set_control_property("path",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "placeholder"
      },
      vb:textfield{
        id = "vPathSelector_placeholder",
        notifier = function(val)
          set_control_property("placeholder",val)
        end
      },
    },
  })

end

-------------------------------------------------------------------------------

function build_vpopup()

  -- class definition
  vpopup = vPopup{
    vb = vb,
    id = "vPopup",
    width = 120,
    height = 20,
    items = {
      "Testing for long items (visible on popup?)",
      "Followed by some empty lines",
      "",
      "",
      "",
    }
  }

  vb.views.controls_col:add_child(vpopup.view)
  table.insert(vlib_controls_ref,vpopup)
  table.insert(vlib_controls,vpopup.id)

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vPopup_properties",
    style = "panel",
    vb:text{
      text = "vPopup",
      font = "bold",
    },
    vb:text{
      text = [[
The vPopup is functionally close to the Renoise API version,
but you can control the message shown when no items are presents]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },

    vb:row{
      vb:text{
        text = "value"
      },
      vb:valuebox{
        id = "vPopup_value",
        notifier = function(val)
          --print("vPopup_value.notifier...",val)
          set_control_property("value",val)
        end
      },
    },

    --[[
    vb:row{
      vb:text{
        text = "editable"
      },
      vb:checkbox{
        id = "vPopup_editable",
        notifier = function(val)
          --print("vPopup_editable.notifier...",val)
          set_control_property("editable",val)
        end
      },
    },
    ]]
  })

end

-------------------------------------------------------------------------------

function build_veditfield()

  -- class definition
  veditfield = vEditField{
    vb = vb,
    id = "vEditField",
    width = 120,
    height = 24,
  }

  vb.views.controls_col:add_child(veditfield.view)
  table.insert(vlib_controls_ref,veditfield)
  table.insert(vlib_controls,veditfield.id)

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vEditField_properties",
    style = "panel",
    vb:text{
      text = "vEditField",
      font = "bold",
    },
    vb:text{
      text = [[
vEditField is a general-purpose value-editing field, 
inspired by 'modify' in the Advanced-Edit panel]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },

    -- TODO

    vb:row{
      vb:text{
        text = "-- Methods ---------"
      },
    },
    vb:button{
      text = "set_value() - float between 0 and 1",
      notifier = function()
        local cval = cNumber{
          value = 0.5,
          value_type = "number",
          value_min = 0,
          value_max = 1,
          value_quantum = nil,
        }
        veditfield:set_value(cval)
      end
    },
    vb:button{
      text = "set_value() - integer between -50 and 50",
      notifier = function()
        local cval = cNumber{
          value = 10,
          value_type = "number",
          value_min = -50,
          value_max = 50,
          value_quantum = 1,
        }
        veditfield:set_value(cval)
      end
    },
    vb:button{
      text = "set_value() - string ",
      notifier = function()
        local cval = cValue{
          value = "hello world!",
          value_type = "string",
        }
        veditfield:set_value(cval)
      end
    },
    vb:button{
      text = "set_value() - boolean ",
      notifier = function()
        local cval = cValue{
          value = true,
          value_type = "boolean",
        }
        veditfield:set_value(cval)
      end
    },

  })

end

-------------------------------------------------------------------------------

function build_vtextfield()

  -- class definition
  vtextfield = vTextField{
    vb = vb,
    id = "vTextField",
    --width = 120,
    --height = 20,
    --items = {"foo","bar","baz"},
    placeholder = "Your text here...",
    --popup = true,
    auto_size = true,
    --font = "normal",
    style = "strong",
  }
  vtextfield.edit_mode_observable:add_notifier(function()
    --print("vtextfield.edit_mode_observable fired...")
    update_properties()
  end)
  vtextfield.text_observable:add_notifier(function()
    --print("vtextfield.text_observable fired...")
    --update_properties()
  end)

  vb.views.controls_col:add_child(vtextfield.view)
  table.insert(vlib_controls_ref,vtextfield)
  table.insert(vlib_controls,vtextfield.id)

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vTextField_properties",
    style = "panel",
    vb:text{
      text = "vTextField",
      font = "bold",
    },
    vb:text{
      text = [[
vTextField is a text-input with support for 'placeholder' text,
and the ability to resize/fit to the contained text]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },

    --vb:row{
      --vb:text{
        --text = "align"
      --},
      --vb:popup{
        --id = "vTextField_align",
        --width = 120,
        ----text = "",
        --items = vTextField.ALIGN,
        --notifier = function(idx)
          --local align = vTextField.ALIGN[idx]
          --set_control_property("align",align)
        --end
      --},
    --},

    vb:row{
      vb:text{
        text = "font"
      },
      vb:popup{
        id = "vTextField_font",
        width = 120,
        --text = "",
        items = vTextField.FONT,
        notifier = function(idx)
          local font = vTextField.FONT[idx]
          set_control_property("font",font)
        end
      },
    },

    vb:row{
      vb:text{
        text = "style"
      },
      vb:popup{
        id = "vTextField_style",
        width = 120,
        --text = "",
        items = vTextField.STYLE,
        notifier = function(idx)
          local font = vTextField.STYLE[idx]
          set_control_property("style",font)
        end
      },
    },

    vb:row{
      vb:text{
        text = "text"
      },
      vb:textfield{
        id = "vTextField_text",
        width = 120,
        notifier = function(str_val)
          set_control_property("text",str_val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "placeholder"
      },
      vb:textfield{
        id = "vTextField_placeholder",
        width = 120,
        --text = "",
        notifier = function(str_val)
          set_control_property("placeholder",str_val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "edit_mode"
      },
      vb:checkbox{
        id = "vTextField_edit_mode",
        value = true,
        notifier = function(val)
          set_control_property("edit_mode",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "auto_size"
      },
      vb:checkbox{
        id = "vTextField_auto_size",
        value = true,
        notifier = function(val)
          set_control_property("auto_size",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "-- Methods ---------"
      },
    },


  })

end



-------------------------------------------------------------------------------

function build_vsearchfield()

  -- class definition
  vsearchfield = vSearchField{
    vb = vb,
    id = "vSearchField",
    width = 120,
    --height = 20,
    --items = {"foo","bar","baz"},
    placeholder = "Search...",
    --popup = true,
    --edit_mode = false,
  }
  vsearchfield.edit_mode_observable:add_notifier(function()
    --print("vsearchfield.edit_mode_observable fired...")
  end)
  vsearchfield.text_observable:add_notifier(function()
    --print("vsearchfield.text_observable fired...")
    suppress_notifier = true
    vb.views["vSearchField_text"].text = vsearchfield.text
    suppress_notifier = false
  end)
  vsearchfield.selected_index_observable:add_notifier(function()
    --print("vsearchfield.selected_index_observable fired...")
    --update_properties()
    suppress_notifier = true
    vb.views["vSearchField_selected_index"].value = vsearchfield.selected_index
    suppress_notifier = false

  end)

  vb.views.controls_col:add_child(vsearchfield.view)
  table.insert(vlib_controls_ref,vsearchfield)
  table.insert(vlib_controls,vsearchfield.id)

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vSearchField_properties",
    style = "panel",
    vb:text{
      text = "vSearchField",
      font = "bold",
    },
    vb:text{
      text = [[
vSearchField is a text-input that allows you to search 
among a number of pre-defined entries]],
      font = "italic",
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },

    vb:button{
      text = 'items = {}',
      notifier = function()
        vsearchfield.items = {}
      end
    },

    vb:button{
      text = 'items = {"foo","bar","baz"}',
      notifier = function()
        vsearchfield.items = {"foo","bar","baz"}
      end
    },

    vb:button{
      text = 'items = {"fooA","fooB","fooC","barA","barB","baz 1","baz 2"}',
      notifier = function()
        vsearchfield.items = {"fooA","fooB","fooC","barA","barB","baz 1","baz 2"}
      end
    },

    vb:row{
      vb:text{
        text = "text"
      },
      vb:textfield{
        id = "vSearchField_text",
        width = 120,
        notifier = function(str_val)
          set_control_property("text",str_val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "placeholder"
      },
      vb:textfield{
        id = "vSearchField_placeholder",
        width = 120,
        --text = "",
        notifier = function(str_val)
          set_control_property("placeholder",str_val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "selected_index"
      },
      vb:valuebox{
        id = "vSearchField_selected_index",
        notifier = function(val)
          set_control_property("selected_index",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "popup"
      },
      vb:checkbox{
        id = "vSearchField_popup",
        value = true,
        notifier = function(val)
          set_control_property("popup",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "edit_mode"
      },
      vb:checkbox{
        id = "vSearchField_edit_mode",
        value = true,
        notifier = function(val)
          set_control_property("edit_mode",val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "-- Methods ---------"
      },
    },


  })

end


-------------------------------------------------------------------------------
--[[
function build_vwaveform()

  -- class definition
  vwaveform = vWaveform{
    vb = vb,
    id = "vWaveform",
    width = 340,
    height = 100,
    --draw_mode = vWaveform.DRAW_MODE.UNIPOLAR,
    style_normal = "button_color",
    style_selected = "plain",
    data = {},
    click_notifier = function(elm,index)
      --print("vwaveform.click_notifier - elm,index",elm,index)

    end,
    selection_notifier = function(elm)
      suppress_notifier = true
      --print("vwaveform.selection_notifier - elm",elm)
      vb.views.vWaveform_selected_index.value = active_ctrl.selected_index
      --print("selected_indices",rprint(active_ctrl.selected_indices))
      vb.views.vWaveform_selected_indices.value = cString.table_to_string(active_ctrl.selected_indices,{number_format = "%.0f"})
      suppress_notifier = false
    end,
  }

  vb.views.controls_col:add_child(vwaveform.view)
  table.insert(vlib_controls_ref,vwaveform)
  --print("vlib_controls_ref (vwaveform)...",rprint(vlib_controls_ref))

  -- class properties and methods
  vb.views.props_row:add_child(vb:column{
    id = "vWaveform_properties",
    style = "panel",

    vb:row{
      vb:text{
        text = "vWaveform",
        font = "bold",
      },
    },
    vb:row{
      vb:text{
        text = "-- Properties ---------"
      },
    },
    vb:row{
      vb:text{
        text = "instrument_index"
      },
      vb:valuebox{
        id = "vWaveform_instrument_index",
        value = 1,
        min = 0,
        max = 100000,
        notifier = function(val)
          set_control_property("instrument_index",val)
        end
      },
      vb:button{
        text = "set to selected",
        notifier = function()
          set_control_property("instrument_index",renoise.song().selected_instrument_index)
        end
      }
    },
    vb:row{
      vb:text{
        text = "sample_index"
      },
      vb:valuebox{
        id = "vWaveform_sample_index",
        value = 1,
        min = 0,
        max = 100000,
        notifier = function(val)
          set_control_property("sample_index",val)
        end
      },
      vb:button{
        text = "set to selected",
        notifier = function()
          set_control_property("instrument_index",renoise.song().selected_instrument_index)
          set_control_property("sample_index",renoise.song().selected_sample_index)
        end
      }
    },

    vb:row{
      vb:text{
        text = "selected_index"
      },
      vb:valuebox{
        id = "vWaveform_selected_index",
        value = 20,
        min = 0,
        max = 100000,
        notifier = function(val)
          set_control_property("selected_index",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "selected_indices"
      },
      vb:textfield{
        id = "vWaveform_selected_indices",
        width = 150,
        --height = 200,
        text = "",
      },
      vb:button{
        text = "set",
        width = 50,
        notifier = function()
          local str_data = vb.views.vWaveform_selected_indices.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            set_control_property("selected_indices",t)
          end
        end
      },
    },
    vb:row{
      vb:text{
        text = "require_selection"
      },
      vb:checkbox{
        id = "vWaveform_require_selection",
        value = true,
        notifier = function(val)
          set_control_property("require_selection",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "draw_mode"
      },
      vb:popup{
        id = "vWaveform_draw_mode",
        items = table.keys(vWaveform.DRAW_MODE),
        width = 150,
        notifier = function(val)
          set_control_property("draw_mode",val)
        end
      },
    }, 
    vb:row{
      vb:text{
        text = "select_mode"
      },
      vb:popup{
        id = "vWaveform_select_mode",
        items = table.keys(vSelection.SELECT_MODE),
        width = 150,
        notifier = function(val)
          set_control_property("select_mode",val)
        end
      },
    }, 

    vb:row{
      vb:text{
        text = "peak (0-1)"
      },
      vb:minislider{
        id = "vWaveform_peak",
        width = 100,
        value = 1,
        min = 1,
        max = 10,
        notifier = function(val)
          set_control_property("peak",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "normalized"
      },
      vb:checkbox{
        id = "vWaveform_normalized",
        value = true,
        notifier = function(val)
          set_control_property("normalized",val)
        end
      },
    },
    vb:row{
      vb:text{
        text = "style_normal"
      },
      vb:popup{
        id = "vWaveform_style_normal",
        --value = 3,
        items = vLib.BITMAP_STYLES,
        width = 50,
        notifier = function(idx)
          local style = table.values(vLib.BITMAP_STYLES)[idx]
          set_control_property("style_normal",style)
        end
      },
    },    
    vb:row{
      vb:text{
        text = "style_selected"
      },
      vb:popup{
        id = "vWaveform_style_selected",
        items = vLib.BITMAP_STYLES,
        --value = 1,
        width = 50,
        notifier = function(idx)
          local style = table.values(vLib.BITMAP_STYLES)[idx]
          set_control_property("style_selected",style)
        end
      },
    },    
    vb:row{
      vb:text{
        text = "data"
      },
      vb:multiline_textfield{
        id = "vWaveform_data",
        width = 450,
        height = 200,
        text = "",
      },
    },
    vb:row{
      vb:button{
        text = "set data",
        width = 50,
        notifier = function()
          local str_data = vb.views.vWaveform_data.text
          local t,err = string_to_lua(str_data)
          if err then
            --print("Error while parsing data:",err)
          else
            set_control_property("data",t)
          end
        end
      },
      vb:button{
        text = "clear data",
        width = 50,
        notifier = function()
          set_control_property("data",{})
        end

      },
    },
    

    vb:row{
      vb:text{
        text = "-- Methods ------------"
      },
    },

    
    vb:row{
      vb:text{
        text = "set_value(selected index)"
      },
      vb:minislider{
        id = "vWaveform_selected_value",
        width = 100,
        value = 0,
        min = 0,
        max = 1,
        notifier = function(val)
          local idx = vwaveform.selected_index
          vwaveform:set_value(idx,val)
        end
      },
    },

    vb:row{
      vb:text{
        text = "clear_selection()"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function(val)
          vwaveform:clear_selection()
        end
      },
    },

    vb:row{
      vb:text{
        text = "select_all()"
      },
      vb:button{
        text = "call",
        width = 40,
        notifier = function(val)
          vwaveform:select_all()
        end
      },
    },


  })



end
]]
-------------------------------------------------------------------------------
--[[
function build_vscroll()

  local vscroll = vScrollbar{
    vb = vb,
    --view = vb.views.controls_col,
    width = 24,
    height = 300,
    button_height = 10,
    --spacing = 20,
    --margin = 10,
    orientation = vScrollbar.ORIENTATION.VERTICAL,
  }

  vb.views.controls_col:add_child(vscroll.view)
  table.insert(vlib_controls_ref,vscroll)

end
]]
-------------------------------------------------------------------------------

function string_to_lua(str)

  local str = ("return %s"):format(str)
  local fn,err = loadstring(str)
  if err then
    return false,err
  else
    return fn()
  end

end


-------------------------------------------------------------------------------
-- display properties as they are applied. This will also test whether the
-- widgets can handle values being set without causing feedbacks

function update_properties()
  TRACE("update_properties()")

  local ctrl_name = vlib_controls[prefs.active_ctrl_idx.value]
  --print("*** update_properties - ctrl_name",ctrl_name)
  --print("active_ctrl.width",active_ctrl.width)
  --print("active_ctrl.height",active_ctrl.height)

  -- vView ----------------------------

  vb.views.vView_visible.value = active_ctrl.visible
  
  if active_ctrl.width then 
    vb.views.vView_width.value = active_ctrl.width 
    set_ruler_width(active_ctrl.width)
  end
  
  if active_ctrl.height then 
    vb.views.vView_height.value = active_ctrl.height 
    set_ruler_height(active_ctrl.height)
  end
  
  vb.views.vView_tooltip.value = active_ctrl.tooltip or ""

  -- vControl -------------------------

  vb.views.vControl_active.value = active_ctrl.active
  vb.views.vControl_midi_mapping.text = active_ctrl.midi_mapping or ""

  if (ctrl_name == "vTabs") then

    vb.views.vTabs_index.value = active_ctrl.index
    vb.views.vTabs_layout.value = active_ctrl.layout
    vb.views.vTabs_switcher_width.value = active_ctrl.switcher_width
    vb.views.vTabs_switcher_height.value = active_ctrl.switcher_height
    vb.views.vTabs_switcher_align.value = active_ctrl.switcher_align
    vb.views.vTabs_size_method.value = active_ctrl.size_method

  elseif (ctrl_name == "vButton") then

    vb.views.vButton_text.text = active_ctrl.text
    vb.views.vButton_color.text = cColor.color_table_to_hex_string(active_ctrl.color)
    vb.views.vButton_bitmap.text = active_ctrl.bitmap

  elseif (ctrl_name == "vToggleButton") then

    vb.views.vToggleButton_enabled.value = active_ctrl.enabled
    vb.views.vToggleButton_text_enabled.text = active_ctrl.text_enabled
    vb.views.vToggleButton_text_disabled.text = active_ctrl.text_disabled
    vb.views.vToggleButton_color_enabled.text = cColor.color_table_to_hex_string(active_ctrl.color_enabled)
    vb.views.vToggleButton_color_disabled.text = cColor.color_table_to_hex_string(active_ctrl.color_disabled)

  elseif (ctrl_name == "vArrowButton") then

    vb.views.vArrowButton_enabled.value = active_ctrl.enabled
    vb.views.vArrowButton_flipped.value = active_ctrl.flipped
    vb.views.vArrowButton_orientation.value = active_ctrl.orientation


  elseif (ctrl_name == "vTable") then

    vb.views.vTable_autosize.value = active_ctrl.autosize
    vb.views.vTable_num_rows.value = active_ctrl.num_rows
    vb.views.vTable_row_height.value = active_ctrl.row_height
    vb.views.vTable_row_offset.value = active_ctrl.row_offset
    vb.views.vTable_header_height.value = active_ctrl.header_height
    vb.views.vTable_scrollbar_width.value = active_ctrl.scrollbar_width
    vb.views.vTable_show_header.value = active_ctrl.show_header
    vb.views.vTable_data.text = cString.table_to_string(active_ctrl.data,{multiline = true})

  elseif (ctrl_name == "vFileBrowser") then

    vb.views.vFileBrowser_num_rows.value = active_ctrl.num_rows
    vb.views.vFileBrowser_path.text = active_ctrl.path
    vb.views.vFileBrowser_file_ext.text = cString.table_to_string(active_ctrl.file_ext)
    vb.views.vFileBrowser_file_types.text = cString.table_to_string(active_ctrl.file_types,{multiline = true})

  elseif (ctrl_name == "vTree") then

    vb.views.vTree_autosize.value = active_ctrl.autosize
    vb.views.vTree_num_rows.value = active_ctrl.num_rows
    vb.views.vTree_row_height.value = active_ctrl.row_height
    vb.views.vTree_indent.value = active_ctrl.indent

  elseif (ctrl_name == "vGraph") then

    vb.views.vGraph_require_selection.value = active_ctrl.require_selection
    vb.views.vGraph_selected_index.value = active_ctrl.selected_index
    vb.views.vGraph_selected_indices.value = cString.table_to_string(active_ctrl.selected_indices,{number_format = "%.0f"})
    vb.views.vGraph_draw_mode.value = active_ctrl.draw_mode
    vb.views.vGraph_style_normal.value = table.find(vLib.BITMAP_STYLES,active_ctrl.style_normal)
    vb.views.vGraph_style_selected.value = table.find(vLib.BITMAP_STYLES,active_ctrl.style_selected)
    vb.views.vGraph_data.text = cString.table_to_string(active_ctrl.data,{multiline = true})
  
  elseif (ctrl_name == "vPathSelector") then

    vb.views.vPathSelector_editable.value = active_ctrl.editable
    vb.views.vPathSelector_mode.value = active_ctrl.mode
    vb.views.vPathSelector_path.value = active_ctrl.path
    vb.views.vPathSelector_placeholder.value = active_ctrl.placeholder

  elseif (ctrl_name == "vPopup") then

    vb.views.vPopup_value.value = active_ctrl.value

  elseif (ctrl_name == "vEditField") then

    -- TODO

  elseif (ctrl_name == "vTextField") then

    vb.views.vTextField_text.value = active_ctrl.text
    vb.views.vTextField_placeholder.text = active_ctrl.placeholder
    vb.views.vTextField_edit_mode.value = active_ctrl.edit_mode
    vb.views.vTextField_auto_size.value = active_ctrl.auto_size
    vb.views.vTextField_font.value = table.find(vTextField.FONT,active_ctrl.font)
    vb.views.vTextField_style.value = table.find(vTextField.STYLE,active_ctrl.style)

  elseif (ctrl_name == "vSearchField") then

    vb.views.vSearchField_text.value = active_ctrl.text
    vb.views.vSearchField_selected_index.value = active_ctrl.selected_index
    vb.views.vSearchField_placeholder.text = active_ctrl.placeholder
    vb.views.vSearchField_edit_mode.value = active_ctrl.edit_mode
    --vb.views.vSearchField_auto_size.value = active_ctrl.auto_size
    --vb.views.vSearchField_font.value = table.find(vTextField.FONT,active_ctrl.font)
    --vb.views.vSearchField_style.value = table.find(vTextField.STYLE,active_ctrl.style)
    vb.views.vSearchField_popup.value = active_ctrl.popup


  elseif (ctrl_name == "vWaveform") then
    
    --[[
    vb.views.vWaveform_require_selection.value = active_ctrl.require_selection
    vb.views.vWaveform_selected_index.value = active_ctrl.selected_index
    vb.views.vWaveform_selected_indices.value = cString.table_to_string(active_ctrl.selected_indices)
    vb.views.vWaveform_draw_mode.value = active_ctrl.draw_mode
    vb.views.vWaveform_style_normal.value = table.find(vLib.BITMAP_STYLES,active_ctrl.style_normal)
    vb.views.vWaveform_style_selected.value = table.find(vLib.BITMAP_STYLES,active_ctrl.style_selected)
    vb.views.vWaveform_data.text = cString.table_to_string(active_ctrl.data,true)
    ]]

  end

end

--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

prefs.active_ctrl_idx:add_notifier(function()
  set_active_ctrl(prefs.active_ctrl_idx.value)
end)

renoise.tool().preferences = prefs

