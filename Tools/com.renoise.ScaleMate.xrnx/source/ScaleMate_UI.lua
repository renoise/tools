--[[===============================================================================================
ScaleMate_UI
===============================================================================================]]--
--[[

User interface for ScaleMate

]]

--=================================================================================================

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

function ScaleMate_UI:key_handler(key)
  TRACE("ScaleMate_UI:key_handler(key)",key)

  --print("keyhandler",self,key)
  local handled = xCursorPos.handle_key(key)
  print(">>> handled",handled)

end 

---------------------------------------------------------------------------------------------------

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
  
  local vb = self.vb
  local vb_content = vb:column{
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
    }
    
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
          width = 1,
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
    LOG("Skip update - self.dialog",self.dialog)
    return 
  end 

  self:update_scales()

end

---------------------------------------------------------------------------------------------------

function ScaleMate_UI:update_scales()
  TRACE("ScaleMate_UI:update_scales()")

  local sel_scale_name = xScale.get_selected_scale() or ""

  for k,v in pairs(self.vb_scale_buttons) do 
    v.color = (sel_scale_name == k) and {0xFF,0xFF,0xFF} or {0,0,0}
  end 

  for k,v in pairs(self.vb_scale_labels) do 
    v.font = (sel_scale_name == k) and "bold" or "normal"
  end 

end 

