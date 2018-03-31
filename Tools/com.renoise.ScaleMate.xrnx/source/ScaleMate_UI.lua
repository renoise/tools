--[[===============================================================================================
ScaleMate_UI
===============================================================================================]]--
--[[

User interface for ScaleMate

]]

--=================================================================================================

local WHITE_KEYS = {1,3,5,6,8,10,12}
local PANEL_W = 270
local SCALE_ON = {0xFF,0xFF,0xFF}
local SCALE_OFF = {0,0,0}
local KEY_WHITE       = {0xFA,0xFA,0xFA}
local KEY_WHITE_SCALE = {0xF3,0xC4,0xB1}
local KEY_BLACK       = {0x30,0x30,0x30}
local KEY_BLACK_SCALE = {0x8F,0x4C,0x30}

class 'ScaleMate_UI'

---------------------------------------------------------------------------------------------------
-- Constructor method

function ScaleMate_UI:__init(...)
  TRACE("ScaleMate_UI:__init(...)")

  local args = cLib.unpack_args(...)

  self.dialog_title = args.dialog_title or ""
  self.midi_prefix = args.midi_prefix or ""
  self.owner = args.owner

  self.vb = renoise.ViewBuilder()
  self.prefs = renoise.tool().preferences

  -- renoise.Dialog
  self.dialog = nil
  
  -- renoise.view, dialog content 
  self.vb_content = nil

  -- individual view objects
  self.vb_scale_labels = {}
  self.vb_scale_buttons = {}

end

---------------------------------------------------------------------------------------------------
-- Emulate basic pattern navigation while dialog has focus

function ScaleMate_UI:key_handler(key)
  TRACE("ScaleMate_UI:key_handler(key)",key)

  local handled = xCursorPos.handle_key(key)

end 

---------------------------------------------------------------------------------------------------
-- Show the dialog (build if needed)

function ScaleMate_UI:show()
  TRACE("ScaleMate_UI:show()")

  if not self.dialog or not self.dialog.visible then 
    if not self.vb_content then 
      self:build()
    end 
    self.dialog = renoise.app():show_custom_dialog(
      self.dialog_title,
      self.vb_content,
      self.key_handler
    )
  end 

  self.dialog:show()
  self:update()

end

---------------------------------------------------------------------------------------------------
-- Build the UI (executed once)

function ScaleMate_UI:build()
  TRACE("ScaleMate_UI:build()")
  
  local KEY_W = PANEL_W/12+3
  local KEY_H = 30
  local vb = self.vb

  local vb_keys = vb:row{
      spacing = -3,
  }
  for k = 1,12 do
    vb_keys:add_child(vb:button{
      id = "scalemate_piano_"..k,
      active = false,
      width = KEY_W,
      height = KEY_H,
      notifier = function()
        self.owner:set_key(k)
      end
    })
  end

  local vb_content = vb:column{
    vb:column{
      margin = 3,
      spacing = -3,
      vb_keys,
      vb:switch{
        id = "scalemate_key_switcher",
        width = PANEL_W,
        active = false,
        items = xScale.KEYS,
        notifier = function(idx)
          self.owner:set_key(idx)
        end
      },
    },
    vb:row{
      style = "plain",
      vb:column{
        self:build_n_tones(12,140),
        self:build_n_tones(5,140),
        self:build_n_tones(6,140),
        self:build_n_tones(8,140),
        self:build_n_tones(9,140),
      },
      self:build_n_tones(7,140),
    },
    vb:horizontal_aligner{
      mode = "justify",
      margin = 3,
      vb:row{
        vb:checkbox{
          value = true,
          bind = self.prefs.write_to_pattern
        },
        vb:text{
          text = "Write to Pattern"
        }
      },
      vb:button{
        text = "Clear in Pattern-Track",
        notifier = function()
          self.owner:clear_pattern_track()
        end
      }
    },
  }

  self.vb_content = vb_content

end

---------------------------------------------------------------------------------------------------

function ScaleMate_UI:build_n_tones(count,width)
  TRACE("ScaleMate_UI:build_n_tones(count,width)",count,width)

  local vb = self.vb
  local container = vb:column{
    margin = 3,
  }

  local view = vb:column{
    vb:row{
      style = "body",
      vb:text{
        text = count.."-tone Scales",
        width = width,
        font = "bold"
      }
    },
    container,
  }

  local scales = xScale.get_scales_with_count(count)
  for k,v in ipairs(scales) do

    local str_midi_mapping = ("Set Scale Mode (%s) [Trigger]"):format(v.name)
    local scale_button = vb:button{
      width = 10,
      midi_mapping = self.midi_prefix..str_midi_mapping,
      notifier = function()
        self.owner:set_scale(v.name)
      end
    }

    local scale_label = vb:text{
      text = v.name,
    }
    
    container:add_child(vb:row{
      scale_button,
      vb:row{
        vb:checkbox{
          visible = false,
          notifier = function()
            self.owner:set_scale(v.name)
          end
        },
        scale_label
      },
    })

    self.vb_scale_labels[v.name] = scale_label
    self.vb_scale_buttons[v.name] = scale_button
  end

  return view

end 

---------------------------------------------------------------------------------------------------
-- When instrument has changed

function ScaleMate_UI:update()
  TRACE"ScaleMate_UI:update()"

  if not self.dialog or not self.dialog.visible then 
    return 
  end 

  self:update_scales()
  self:update_keys()

end

---------------------------------------------------------------------------------------------------

function ScaleMate_UI:update_scales()
  TRACE("ScaleMate_UI:update_scales()")

  local sel_scale_name = xScale.get_selected_scale() 

  for k,v in pairs(self.vb_scale_buttons) do 
    v.color = (sel_scale_name == k) and SCALE_ON or SCALE_OFF
  end 

  for k,v in pairs(self.vb_scale_labels) do 
    v.font = (sel_scale_name == k) and "bold" or "normal"
  end 

end 

---------------------------------------------------------------------------------------------------

function ScaleMate_UI:update_keys()
  TRACE("ScaleMate_UI:update_keys()")

  local scale_name = xScale.get_selected_scale() 
  local scale_key = xScale.get_selected_key() 
  local vb = self.vb

  local vb_key_switcher = vb.views["scalemate_key_switcher"]
  if vb_key_switcher then 
    vb_key_switcher.active = (scale_name ~= "None") and true or false
    vb_key_switcher.value = (scale_name == "None") and 1 or scale_key
  end

  local scale = xScale.get_scale_by_name(scale_name)
  local scale_keys = scale.keys 
  if (scale_key ~= "None") then 
    scale_keys = xScale.get_shifted_keys(scale,scale_key)
  end 

  for k = 1,12 do 
    local vb_key = vb.views["scalemate_piano_"..k]
    if vb_key then 
      local is_white = table.find(WHITE_KEYS,k)
      if is_white then 
        vb_key.color = (scale_keys[k]==1) and KEY_WHITE_SCALE or KEY_WHITE
      else 
        vb_key.color = (scale_keys[k]==1) and KEY_BLACK_SCALE or KEY_BLACK
      end 
      vb_key.active = (scale_name ~= "None") and true or false
    end 
  end 

end
