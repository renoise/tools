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

---------------------------------------------------------------------------------------------------
-- Emulate basic pattern navigation while dialog has focus

function SliceMate_UI:dialog_keyhandler(dialog,key)
  TRACE("SliceMate_UI:dialog_keyhandler(dialog,key)",dialog,key)

  local handled = xCursorPos.handle_key(key)

end 

----------------------------------------------------------------------------------------------------
-- Class methods
----------------------------------------------------------------------------------------------------

function SliceMate_UI:__init(...)

  local args = cLib.unpack_args(...)
  assert(type(args.owner)=="SliceMate","Expected 'owner' to be a class instance")

  vDialog.__init(self,{
    dialog_title = args.dialog_title,    
    waiting_to_show_dialog = args.waiting_to_show_dialog,
    dialog_keyhandler = self.dialog_keyhandler,
  })

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()
  --- SliceMate_Prefs, current settings
  self.prefs = renoise.tool().preferences
  -- VR (main application)
  self.owner = args.owner

  self.dialog_width = 170

  -- vToggleButton
  self.vtoggle_slice = nil

  --- update flags
  self.update_instrument_requested = false
  
  -- notifiers --

  self.owner.instrument_index:add_notifier(function()
    self.update_instrument_requested = true
  end)
  self.owner.instrument_status:add_notifier(function()
    self.update_instrument_requested = true
  end)
  self.owner.slice_index:add_notifier(function()
    self.update_instrument_requested = true
  end)
  self.owner.position_slice:add_notifier(function()
    self.update_instrument_requested = true
  end)
  self.owner.phrase_index:add_notifier(function()
    self.update_instrument_requested = true
  end)
  self.owner.phrase_line:add_notifier(function()
    self.update_instrument_requested = true
  end)
  
  --self.prefs.limit_fill:add_notifier(function()
  --  self:update_slice_button()
  --end)
  self.prefs.quantize_enabled:add_notifier(function()
    self:update_slice_button()
  end)
  self.prefs.show_options:add_notifier(function()
    self:update_options()  
  end)


  renoise.tool().app_idle_observable:add_notifier(self,self.on_idle)
  
end

---------------------------------------------------------------------------------------------------
-- show this prompt when pressing slice in an empty track 

function SliceMate_UI:promp_initial_note_insert()

  local vb = self.vb
  local view = vb:row{
    margin = 10,
    vb:text{    
      text = "The track does not seem to contain any notes,"
        .."\npress 'Insert Note' to insert the basenote of" 
        .."\nthe currently selected instrument."
    }
  }

  local choice = renoise.app():show_custom_prompt("SliceMate",view,{"Insert Note","Cancel"})
  return  (choice == "Insert Note") 

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:update_slice_button()
  TRACE("SliceMate_UI:update_slice_button()")
  
  local ctrl = self.vb.views["insert_slice_button"]
  --local fill_mode = SliceMate_Prefs.LIMIT_FILL_LABELS[self.prefs.limit_fill.value]
  local text = "Slice at Cursor"
  
  ctrl.active = (rns.selected_track.type == renoise.Track.TRACK_TYPE_SEQUENCER)
  ctrl.text = self.prefs.quantize_enabled.value and text .. " [Quant]" or text 

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:update_options()

  local enabled = self.prefs.show_options.value
  self.vtoggle_slice.enabled = enabled
  local ctrl = self.vb.views["options_panel"]
  if ctrl then
    ctrl.visible = enabled
  end

end

---------------------------------------------------------------------------------------------------

function SliceMate_UI:update_instrument()
  TRACE("SliceMate_UI:update_instrument()")

  local instr_idx = self.owner.instrument_index.value
  local instr = rns.instruments[instr_idx]
  local instr_status = self.owner.instrument_status.value
  local slice_index = self.owner.slice_index.value
  local phrase_index = self.owner.phrase_index.value
  local phrase_line = self.owner.phrase_line.value
  local frame = self.owner.position_slice.value
  local root_frame = self.owner.position_root.value

  local in_trail = (instr_idx > 0) and true or false 
  local is_phrase = (self.owner.phrase_index.value > 0) and true or false
  
  local ctrl = self.vb.views["instrument_index"]
  if ctrl then
    local instr_name = instr and instr.name or "Instrument N/A"
    if (instr_name == "") then
      instr_name = "Untitled Instrument"
    end
    local subtract = (instr_status ~= "") and 19 or 0
    ctrl.text = instr_name
    ctrl.width = self.dialog_width-subtract-32
  end
  
  local ctrl = self.vb.views["instrument_status"]
  if ctrl then
    ctrl.tooltip = instr_status
    ctrl.visible = (instr_status ~= "")
  end

  local ctrl = self.vb.views["position"]
  if ctrl then
    local str_status = ""
    if not in_trail then
      str_status = "-" 
    elseif (phrase_index > 0) then 
      local phrase = instr.phrases[phrase_index]
      local lpb_factor = self.owner:get_lpb_factor(phrase)
      -- position in phrase 
      --print(">>> phrase_line",phrase_line)
      str_status = ("Offset S%.2X"):format(phrase_line-1)
      local fract = cLib.fraction(phrase_line)
      if (fract > 0) then 
        if (lpb_factor > 1) then 
          str_status = ("%s + %.2f Line"):format(str_status,fract)
        else
          str_status = ("%s - ⚠ N/A"):format(str_status)
        end
      end
    else 
      local sample = self.owner:get_sample() 
      if sample and sample.beat_sync_enabled then 
        -- position in sample (lines)
        local exceed = (self.owner.lines_travelled >= sample.beat_sync_lines)
        str_status = ("%d / %d"):format(self.owner.lines_travelled+1,sample.beat_sync_lines)
        str_status = ("Lines: %s %s"):format(str_status,exceed and "⚠" or "")
      else
        -- position in sample (frames)
        str_status = (frame == -1) and "-" or ("%d / %d"):format(frame,root_frame)
        str_status = ("Pos: %s"):format(str_status)
      end        
    end
    ctrl.tooltip = str_status
    ctrl.text = str_status
  end
  
  local ctrl = self.vb.views["status"]
  if ctrl then
    local str_status = ""
    local rmv_bt = self.vb.views["vb_remove_slice_button"]
    if not in_trail then
      str_status = "-" 
      rmv_bt.visible = false
    else
      if (phrase_index > 0) then 
        -- phrase status
        local phrase_count = instr and #instr.phrases
        if not in_trail or ((phrase_index == 0) and (phrase_count == 0)) then
          str_status = instr and "0" or "-"
        else
          str_status = (phrase_index == -1) and "-" or ("%d / %d"):format(phrase_index,phrase_count)
        end
        str_status = ("Active phrase: %s"):format(str_status)
        rmv_bt.visible = false
      else
        -- slice status
        local slice_count = instr and (#instr.samples > 1) 
          and #instr.samples[1].slice_markers or 0
        if not in_trail or ((slice_index == 0) and (slice_count == 0)) then
          str_status = instr and "0" or "-"
        else
          str_status = (slice_index == -1) and "-" or ("%d / %d"):format(slice_index,slice_count)
        end
        str_status = ("Active slice: %s"):format(str_status)
        rmv_bt.visible = (in_trail and slice_index > 0)
      end 
    end 
    ctrl.tooltip = str_status
    ctrl.text = str_status

  end
  
  -- slice buttons 
  self.vb.views["vb_insert_slice_back"].active = in_trail
  self.vb.views["vb_insert_slice_back_fill"].active = in_trail
  self.vb.views["vb_insert_slice_forward"].active = in_trail
  self.vb.views["vb_insert_slice_forward_fill"].active = in_trail
  self.vb.views["vb_insert_slice_previous"].active = in_trail and not is_phrase
  self.vb.views["vb_insert_slice_next"].active = in_trail and not is_phrase
  

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
    tooltip = "Toggle Options",
    text_enabled = "◂",
    text_disabled = "▸",
    notifier = function(ref)
      self.prefs.show_options.value = ref.enabled
    end,
  }
  return self.vtoggle_slice.view
end


---------------------------------------------------------------------------------------------------

function SliceMate_UI:build()
  TRACE("SliceMate_UI:build()")
  
  local vb = self.vb
  
  local prev_next_bt_w = (self.dialog_width-52)/2
  --local slice_half_bt_w = (self.dialog_width-12)/2
  
  local options_checkbox_w = 20
  local options_label_w = 60
  local column_button_h = 33
  
  local slice_sub_label_w = 60
  local slice_sub_button_w = 58
  local slice_sub_fill_button_w = 40
  
  -- derived
  local slice_sub_popup_w = slice_sub_button_w + slice_sub_fill_button_w
  
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
                width = options_checkbox_w,
                notifier = function()
                  renoise.app():show_message(self.owner.instrument_status.value)
                end
              }
            },
            vb:button{
              bitmap = "./source/icons/detach.bmp",
              width = options_checkbox_w,
              midi_mapping = "Tools:SliceMate:Detach Sampler... [Trigger]",
              notifier = function()
                self.owner:detach_sampler()
              end
            },
            
          },
          vb:row{
            --mode = "justify",
            vb:text{
              id = "status",
              text = "",
              width = self.dialog_width-31,
            },
            vb:button{
              id = "vb_remove_slice_button",
              text = "⨯",
              tooltip = "Remove this slice",
              width = options_checkbox_w,
              notifier = function()
                local removed,err = self.owner:remove_active_slice()
                if not removed and err then 
                  renoise.app():show_error(err)
                else
                  self.owner.select_requested = true
                end 
              end,
            }
          },
          vb:row{
            vb:text{
              id = "position",
              text = "",
              width = self.dialog_width-31,
            },
            --self:build_vtoggle_options(),
          },
            vb:space{
              height = 3
            },
          

        },
        -- navigation panel 
        vb:column{
          style = "group",
          margin = 4,
          width = self.dialog_width-4,
          vb:row{
            vb:button{
              tooltip = "Go to previous note-column",
              height = column_button_h,
              width = options_checkbox_w,
              text = "◀",
              midi_mapping = "Tools:SliceMate:Previous Column [Trigger]",
              notifier = function()
                self.owner:previous_column()
              end
            },
            vb:column{
              spacing = -3,
              vb:row{
                vb:button{
                  tooltip = "Go to previous note",
                  width = prev_next_bt_w,
                  midi_mapping = "Tools:SliceMate:Previous Note [Trigger]",
                  text = "▴ Note",
                  notifier = function()
                    self.owner:previous_note()
                  end
                },
                vb:button{
                  tooltip = "Go to previous line",
                  width = prev_next_bt_w,
                  midi_mapping = "Tools:SliceMate:Previous Line [Trigger]",
                  text = "▴ Line",
                  notifier = function()
                    self.owner:previous_line()
                  end
                },
              },
              vb:row{
                vb:button{
                  tooltip = "Go to next note",
                  width = prev_next_bt_w,
                  midi_mapping = "Tools:SliceMate:Next Note [Trigger]",
                  text = "▾ Note",
                  notifier = function()
                    self.owner:next_note()
                  end
                },
                vb:button{
                  tooltip = "Go to next line",
                  width = prev_next_bt_w,
                  midi_mapping = "Tools:SliceMate:Next Line [Trigger]",
                  text = "▾ Line",
                  notifier = function()
                    self.owner:next_line()
                  end
                },
              },
            },
            vb:button{
              tooltip = "Go to next note-column",
              height = column_button_h,
              width = options_checkbox_w,
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
          vb:button{
            id = "insert_slice_button",
            width = self.dialog_width-12,
            text = "Slice at Cursor",
            tooltip = "Slice sample/phrase at this cursor position",
            midi_mapping = "Tools:SliceMate:Insert Slice [Trigger]",
            notifier = function()
              local success,err = self.owner:insert_slice()
              if err then
                renoise.app():show_error(err)
              else
                self.owner.select_requested = true
              end
            end
          },
          -- quantization 
          vb:row{
            vb:text{
              text = "Quantize",
              width = slice_sub_label_w,
            },
            vb:popup{
              items = SliceMate_Prefs.QUANTIZE_LABELS,
              bind = self.prefs.quantize_amount,
              width = slice_sub_popup_w,
            }
          },
          
          -- scope select 
          vb:row{
            vb:text{
              text = "Limit Fill",
              width = slice_sub_label_w,
            },
            vb:popup{
              width = slice_sub_popup_w,
              bind = self.prefs.limit_fill,
              items = SliceMate_Prefs.LIMIT_FILL_LABELS
            }
          },          
          -- slice forward/back 
          vb:column{
            --style = "group",
            --margin = 4,
            spacing = -3,
            vb:row{
              vb:text{
                text = "Slice Back",
                width = slice_sub_label_w,
              },
              vb:button{
                text = "▴ Slice",
                width = slice_sub_button_w,
                id = "vb_insert_slice_back",
                tooltip = "Slice backward using Quantize",
                midi_mapping = "Tools:SliceMate:Backward Slice [Trigger]",
                notifier = function()
                  local success,err = self.owner:insert_backward_slice(SliceMate_Prefs.SLICE_NAV_MODE.QUANTIZE)
                  if not success and err then
                    renoise.app():show_error(err)
                  else
                    self.owner.select_requested = true
                  end
                end
              },
              vb:button{
                text = "▴ Fill",
                width = slice_sub_fill_button_w,
                id = "vb_insert_slice_back_fill",
                tooltip = "Slice backward using Quantize until reaching the start",
                midi_mapping = "Tools:SliceMate:Backward Slice - Fill [Trigger]",
                notifier = function()
                  local success,err = self.owner:insert_backward_slice(SliceMate_Prefs.SLICE_NAV_MODE.QUANTIZE,true)
                  if not success and err then
                    renoise.app():show_error(err)
                  else
                    self.owner.select_requested = true
                  end                                
                end
              },
            },
            vb:row{
              vb:text{
                text = "Slice Forw",
                width = slice_sub_label_w,
              },
              vb:button{
                text = "▾ Slice",
                width = slice_sub_button_w,
                id = "vb_insert_slice_forward",
                tooltip = "Slice forward using Quantize",
                midi_mapping = "Tools:SliceMate:Forward Slice [Trigger]",
                notifier = function()
                  local success,err = self.owner:insert_forward_slice(SliceMate_Prefs.SLICE_NAV_MODE.QUANTIZE)
                  if not success and err then
                    renoise.app():show_error(err)
                  else
                    self.owner.select_requested = true
                  end                
                end               
              },
              vb:button{
                text = "▾ Fill",
                width = slice_sub_fill_button_w,
                id = "vb_insert_slice_forward_fill",
                tooltip = "Slice forward using Quantize until reaching the end",
                midi_mapping = "Tools:SliceMate:Forward Slice - Fill [Trigger]",
                notifier = function()
                  local success,err = self.owner:insert_forward_slice(SliceMate_Prefs.SLICE_NAV_MODE.QUANTIZE,true)
                  if not success and err then
                    renoise.app():show_error(err)
                  else
                    self.owner.select_requested = true
                  end                
                end              
              },
            },
          },
          -- insert slice 
          vb:column{
            --style = "group",
            --margin = 4,
            spacing = -3,
            vb:column{
              spacing = -3,
              vb:row{
                vb:text{
                  text = "Ins. Prev",
                  width = slice_sub_label_w,
                },
                vb:button{
                  text = "▴ Insert",
                  width = slice_sub_button_w,
                  id = "vb_insert_slice_previous",
                  tooltip = "Insert the previous slice",
                  midi_mapping = "Tools:SliceMate:Insert Previous Slice [Trigger]",
                  notifier = function()
                    local success,err = self.owner:insert_backward_slice(SliceMate_Prefs.SLICE_NAV_MODE.INSERT)
                    if not success and err then
                      renoise.app():show_error(err)
                    else
                      self.owner.select_requested = true
                    end
                  end              
                },
                vb:button{
                  text = "▴ Fill",
                  width = slice_sub_fill_button_w,
                  id = "vb_insert_slice_previous_fill",
                  midi_mapping = "Tools:SliceMate:Insert Previous Slice - Fill [Trigger]",
                  active = false,
                },
              },
              vb:row{
                vb:text{
                  text = "Ins. Next",
                  width = slice_sub_label_w,
                },
                vb:button{
                  text = "▾ Insert",
                  width = slice_sub_button_w,
                  id = "vb_insert_slice_next",
                  tooltip = "Insert the next slice",
                  midi_mapping = "Tools:SliceMate:Insert Next Slice [Trigger]",
                  notifier = function()
                    local success,err = self.owner:insert_forward_slice(SliceMate_Prefs.SLICE_NAV_MODE.INSERT)
                    if not success and err then
                      renoise.app():show_error(err)
                    else
                      self.owner.select_requested = true
                    end
                  end               
                  
                },
                vb:button{
                  id = "vb_insert_slice_next_fill",
                  text = "▾ Fill",
                  midi_mapping = "Tools:SliceMate:Insert Next Slice - Fill [Trigger]",
                  width = slice_sub_fill_button_w,
                  active = false,
                },
              },      
            },    
          },

          
        },

        -- footer
        vb:column{        
          style = "group",
          margin = 4,
          width = self.dialog_width,                   
          vb:horizontal_aligner{
            mode="justify",
            vb:button{
              text = "About",
              notifier = function() 
                renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.SliceMate.xrnx")
              end,
            },
            vb:row{
              vb:text{
                text = "Options",   
                align = "right",
              },
              self:build_vtoggle_slice(),        
            }
          },      
        },
      }, 
      vb:column{       
        id = "options_panel",
        spacing = 4,
        vb:column{
          margin = 4,
          style = "group",
          width = self.dialog_width,
          vb:text{
            text = "General",
            font = "bold",
          },
          vb:row{
            vb:checkbox{
              bind = self.prefs.autostart
            },
            vb:text{
              text = "Show GUI on startup"
            }
          },
          vb:row{
            tooltip = "Suspend visual updates while tool GUI is hidden",                  
            vb:checkbox{
              bind = self.prefs.suspend_while_hidden,
            },
            vb:text{
              text = "Suspend while hidden"
            }
          },
        },        
        vb:column{
          margin = 4,
          style = "group",
          width = self.dialog_width,
          vb:text{
            text = "Slicing",
            font = "bold",
          },            
          vb:row{
            tooltip = "Decide if slices are quantized",
            vb:checkbox{
              bind = self.prefs.quantize_enabled
            },
            vb:text{
              text = "Force Quantization"
            }
          },
          vb:row{
            tooltip = "Support slicing of instrument phrases",
            vb:checkbox{
              bind = self.prefs.support_phrases
            },
            vb:text{
              text = "Support phrase slicing"
            }
          },                         
          vb:row{
            tooltip = "Insert a note into the pattern when slicing sample",
            vb:checkbox{
              bind = self.prefs.insert_note
            },
            vb:text{
              text = "Insert note when slicing"
            }
          },            
          vb:row{
            tooltip = "Carry over VOL/PAN from previous note when inserting new notes",
            vb:checkbox{
              bind = self.prefs.propagate_vol_pan
            },
            vb:text{
              text = "Propagate VOL/PAN"
            }
          }, 
          vb:row{
            tooltip = "Attempt to correct issues with instruments as they are sliced",
            vb:checkbox{
              bind = self.prefs.autofix_instr
            },
            vb:text{
              text = "Auto-fix instrument"
            }
          },              
        },
        vb:column{
          margin = 4,
          style = "group",
          width = self.dialog_width,
          vb:text{
            text = "Selection",
            font = "bold",
          },                      
          vb:row{
            tooltip = "Automatically select instrument underneath cursor",
            vb:checkbox{
              bind = self.prefs.autoselect_instr
            },
            vb:text{
              text = "Auto-select instrument"
            }
          },
          vb:row{
            tooltip = "Automatically select sample in instr. sample-list",
            vb:checkbox{
              bind = self.prefs.autoselect_in_list
            },
            vb:text{
              text = "Auto-select in sample-list"
            }
          },
          vb:row{
            tooltip = "Visualize the computed playback position in the waveform editor",
            vb:checkbox{
              bind = self.prefs.autoselect_in_wave
            },
            vb:text{
              text = "Auto-select in waveform"
            }
          },       
        },        
        
      },
       
    }

  self.vb_content = vb_content

  self:update_instrument()
  self:update_slice_button()
  self:update_options()
  --self:update_tool_options()

end

---------------------------------------------------------------------------------------------------
--- handle idle notifications

function SliceMate_UI:on_idle()

  if self.update_instrument_requested then
    self.update_instrument_requested = false
    self:update_instrument()
  end
  
end
