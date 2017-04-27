--[[===============================================================================================
SliceMate
===============================================================================================]]--
--[[

User interface for SliceMate

]]


class 'SliceMate_UI' (vDialog)

---------------------------------------------------------------------------------------------------
-- vDialog
---------------------------------------------------------------------------------------------------

function SliceMate_UI:create_dialog()
  TRACE("SliceMate_UI:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:show()
  TRACE("SliceMate_UI:show()")

  vDialog.show(self)

end

----------------------------------------------------------------------------------------------------
-- Class methods
----------------------------------------------------------------------------------------------------

function SliceMate_UI:__init(...)

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="SliceMate","Expected 'owner' to be a class instance")

  vDialog.__init(self,...)

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()
  --- SliceMate_Prefs, current settings
  self.prefs = renoise.tool().preferences
  -- VR (main application)
  self.owner = args.owner

  self.dialog_width = 170

  -- vToggleButton
  self.vtoggle_slice = nil
  self.vtoggle_options = nil

  -- notifiers --

  self.owner.instrument_index:add_notifier(function()
    self:update_instrument()
  end)

  self.owner.instrument_status:add_notifier(function()
    self:update_instrument()
  end)

  self.owner.slice_index:add_notifier(function()
    self:update_instrument()
  end)

  self.owner.position_slice:add_notifier(function()
    self:update_instrument()
  end)

  self.prefs.show_slice_options:add_notifier(function()
    self:update_slice_options()  
  end)

  self.prefs.show_tool_options:add_notifier(function()
    self:update_tool_options()  
  end)
  

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:update_slice_options()

  local enabled = self.prefs.show_slice_options.value
  self.vtoggle_slice.enabled = enabled
  local ctrl = self.vb.views["slice_panel"]
  if ctrl then
    ctrl.visible = enabled
  end

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:update_tool_options()

  local enabled = self.prefs.show_tool_options.value
  self.vtoggle_options.enabled = enabled
  local ctrl = self.vb.views["options_panel"]
  if ctrl then
    ctrl.visible = enabled
  end

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:update_instrument()
  TRACE("SliceMate_UI:update_instrument()")

  local instr_status = self.owner.instrument_status.value
  local instr_idx = self.owner.instrument_index.value
  local instr = rns.instruments[instr_idx]
  local slice_index = self.owner.slice_index.value
  local frame = self.owner.position_slice.value
  local root_frame = self.owner.position_root.value

  local ctrl = self.vb.views["instrument_index"]
  if ctrl then
    local instr_name = instr and instr.name or "Instrument N/A"
    if (instr_name == "") then
      instr_name = "Untitled Instrument"
    end
    local subtract = (instr_status ~= "") and 19 or 0
    ctrl.text = instr_name
    ctrl.width = self.dialog_width-subtract-30
  end
  
  local ctrl = self.vb.views["instrument_status"]
  if ctrl then
    ctrl.tooltip = instr_status
    ctrl.visible = (instr_status ~= "")
  end

  local ctrl = self.vb.views["position_slice"]
  if ctrl then
    local str_status = ""
    if (instr_idx == 0) then
      str_status = "-" 
    else
      str_status = (frame == -1) and "-" or ("%d / %d"):format(frame,root_frame)
    end
    str_status = ("Pos: %s"):format(str_status)
    ctrl.tooltip = str_status
    ctrl.text = str_status
  end
  
  local ctrl = self.vb.views["slice_status"]
  if ctrl then
    local slice_count = instr and (#instr.samples > 1) 
      and #instr.samples[1].slice_markers or 0
    local str_status = ""
    if (instr_idx == 0) then
      str_status = instr and "0 (not sliced)" or "-"
    else
      str_status = (slice_index == -1) and "-" or ("%d / %d"):format(slice_index,slice_count)
    end
    str_status = ("Active slice: %s"):format(str_status)
    ctrl.tooltip = str_status
    ctrl.text = str_status
  end

end

---------------------------------------------------------------------------------------------------
-- @param name (string)
-- @return Renoise.View

function SliceMate_UI:build_mask_checkbox(name)
  TRACE("SliceMate_UI:build_mask_checkbox - self",self)

  local vb = self.vb
  return vb:row{
    vb:checkbox{
      bind = self.prefs[name]
    },
    vb:text{
      text = name
    }
  }

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:build_vtoggle_slice()
  self.vtoggle_slice = vToggleButton{
    vb = self.vb,
    text_enabled = "≡",
    text_disabled = "≡",
    notifier = function(ref)
      self.prefs.show_slice_options.value = ref.enabled
    end,
  }
  return self.vtoggle_slice.view
end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:build_vtoggle_options()
  self.vtoggle_options = vToggleButton{
    vb = self.vb,
    text_enabled = "⚙",
    text_disabled = "⚙",
    notifier = function(ref)
      self.prefs.show_tool_options.value = ref.enabled
    end,
  }
  return self.vtoggle_options.view
end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:build()
  TRACE("SliceMate_UI:build()")
  
  local vb = self.vb

  local vb_content = 
    vb:row{
      margin = 4,
      spacing = 4,
      
      vb:column{
        spacing = 4,
        -- instrument stats
        vb:column{
          style = "group",
          margin = 4,
          vb:row{
            width = self.dialog_width-12,
            vb:text{
              id = "instrument_index",
              text = "",
              font = "bold"
            },
            vb:column{
              vb:space{
                height = 3,
              },
              vb:bitmap{
                id = "instrument_status",
                bitmap = "./source/icons/warning.bmp",
                mode = "transparent",
                width = 20,
                notifier = function()
                  renoise.app():show_message(self.owner.instrument_status.value)
                end
              }
            },
            vb:button{
              bitmap = "./source/icons/detach.bmp",
              midi_mapping = "Tools:SliceMate:Detach Sampler... [Trigger]",
              notifier = function()
                self.owner:detach_sampler()
              end
            },
            
          },
          vb:row{
            vb:text{
              id = "slice_status",
              text = "",
              width = self.dialog_width-31,
            },
          },
          vb:row{
            vb:text{
              id = "position_slice",
              text = "",
              width = self.dialog_width-31,
            },
            self:build_vtoggle_options(),
          },
            vb:space{
              height = 3
            },
          
          vb:column{
            id = "options_panel",    
            vb:row{
              vb:checkbox{
                bind = self.prefs.autostart
              },
              vb:text{
                text = "Auto-start tool"
              }
            },
            vb:row{
              vb:checkbox{
                bind = self.prefs.show_on_launch
              },
              vb:text{
                text = "Show UI on auto-start"
              }
            },            
          }
        },
        -- navigation panel 
        vb:column{
          style = "group",
          margin = 4,
          width = self.dialog_width-4,
          vb:row{
            vb:button{
              height = 36,
              text = "◀",
              midi_mapping = "Tools:SliceMate:Previous Column [Trigger]",
              notifier = function()
                self.owner:previous_column()
              end
            },
            vb:column{
              vb:button{
                width = self.dialog_width-52,
                midi_mapping = "Tools:SliceMate:Previous Note [Trigger]",
                text = "Previous note",
                notifier = function()
                  self.owner:previous_note()
                end
              },
              vb:button{
                width = self.dialog_width-52,
                midi_mapping = "Tools:SliceMate:Next Note [Trigger]",
                text = "Next note",
                notifier = function()
                  self.owner:next_note()
                end
              },
            },
            vb:button{
              height = 36,
              text = "▶",
              midi_mapping = "Tools:SliceMate:Next Column [Trigger]",
              notifier = function()
                self.owner:next_column()
              end
            },              
          },
        },
        -- slice panel 
        vb:column{
          style = "group",
          margin = 4,
          width = self.dialog_width,
          vb:row{
            vb:button{
              width = self.dialog_width - 32,
              text = "Slice at Cursor",
              midi_mapping = "Tools:SliceMate:Insert Slice [Trigger]",
              notifier = function()
                local success,err = self.owner:insert_slice()
                if not success and err then
                  renoise.app():show_error(err)
                else
                  self.owner.select_requested = true
                end
              end
            },  
            self:build_vtoggle_slice(),
          },   
          vb:column{       
            id = "slice_panel",
            vb:column{
              vb:row{
                vb:checkbox{
                  bind = self.prefs.quantize_enabled
                },
                vb:text{
                  text = "Quantize to "
                },
                vb:popup{
                  items = SliceMate_Prefs.QUANTIZE_LABELS,
                  bind = self.prefs.quantize_amount,
                  width = 76,
                }
              },
              vb:row{
                vb:checkbox{
                  bind = self.prefs.insert_note
                },
                vb:text{
                  text = "Insert note"
                }
              },            
              vb:row{
                vb:checkbox{
                  bind = self.prefs.propagate_vol_pan
                },
                vb:text{
                  text = "Propagate VOL/PAN"
                }
              }, 
              vb:row{
                vb:checkbox{
                  bind = self.prefs.autoselect_instr
                },
                vb:text{
                  text = "Auto-select instrument"
                }
              },
              vb:row{
                vb:checkbox{
                  bind = self.prefs.autoselect_in_list
                },
                vb:text{
                  text = "Auto-select in sample-list"
                }
              },
              vb:row{
                vb:checkbox{
                  bind = self.prefs.autoselect_in_wave
                },
                vb:text{
                  text = "Auto-select in waveform"
                }
              },             
            }
          },
        },
      },      
    }

  self.vb_content = vb_content

  self:update_instrument()
  self:update_slice_options()
  self:update_tool_options()

end

