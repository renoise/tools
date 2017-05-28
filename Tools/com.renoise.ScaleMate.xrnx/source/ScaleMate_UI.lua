--[[============================================================================
ScaleMate_UI
============================================================================]]--
--[[

User interface for ScaleMate

]]

class 'ScaleMate_UI'

--------------------------------------------------------------------------------
-- Constructor method

function ScaleMate_UI:__init(...)
  TRACE("ScaleMate_UI:__init(...)")

  local args = cLib.unpack_args(...)

  self.dialog_title = args.dialog_title or ""

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

-------------------------------------------------------------------------------

function ScaleMate_UI:key_handler(self,key)
  TRACE("ScaleMate_UI:key_handler(self,key)",self,key)


end 

-------------------------------------------------------------------------------

function ScaleMate_UI:show()
  TRACE("ScaleMate_UI:show()")

  if not self.vb_content then 
    self:build()
  end 

  if not self.dialog then 
    self.dialog = renoise.app():show_custom_dialog(
      self.dialog_title,
      self.vb_content,
      self.key_handler
    )
  end 

  self.dialog:show()

end

-------------------------------------------------------------------------------
-- Build the UI (executed once)

function ScaleMate_UI:build()
  TRACE("ScaleMate_UI:build()")
  
  local vb = self.vb
  local vb_content = vb:column{
    vb:row{
      style = "plain",
      --[[
      vb:row{
        vb:checkbox{
          bind = renoise.tool().preferences.autostart
        },
        vb:text{
          text = "autostart"
        }
      }
      ]]
      vb:column{
        self:build_n_tones(12,50),
        self:build_n_tones(5,120),
        self:build_n_tones(6,90),
        self:build_n_tones(8,120),
        self:build_n_tones(9,110),
      },
      self:build_n_tones(7,120),
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
          text = "Write to pattern"
        }
      },
      vb:button{
        text = "Clear commands",
        notifier = function()
          self.owner:clear_commands_in_pattern()
        end
      }
    }
    
  }

  self.vb_content = vb_content

end

-------------------------------------------------------------------------------

function ScaleMate_UI:build_n_tones(count,width)
  TRACE("ScaleMate_UI:build_n_tones(count,width)",count,width)

  local vb = self.vb
  local container = vb:column{
    margin = 3,
  }

  local view = vb:column{
    vb:row{
      style = "body",
      width = 200,
      vb:text{
        text = count.."-tone Scales",
        width = 200,
        font = "bold"
      }
    },
    container,
  }

  local scales = xScale.get_scales_with_count(count)
  for k,v in ipairs(scales) do

    local scale_button = vb:button{
      width = 10,
      midi_mapping = "foo",
      notifier = function()
        LOG("got here")
        self.owner:set_scale(v.name)
      end
    }

    local scale_label = vb:text{
      width = width,
      text = v.name,
    }
    
    container:add_child(vb:row{
      scale_button,
      vb:row{
        vb:checkbox{
          width = 1,
          notifier = function()
            LOG("got here")
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

-------------------------------------------------------------------------------
-- When instrument has changed

function ScaleMate_UI:update()

  self:update_scales()

end


-------------------------------------------------------------------------------

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

