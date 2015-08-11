--[[============================================================================
-- NTrapUI
============================================================================]]--

--[[--

### About

This is a supporting class for NTrap, takes care of the user interface. 

--]]



--==============================================================================

local DIALOG_W = 405
local LEFT_COL_W = 66     -- left side
local MIDDLE_W = 180      -- middle (dropdowns)
local RIGHT_W = 80        -- right side
local RIGHT_COL_W = 320   -- full minus left
local CONTENT_W = 390     -- full width
local OPTION_H = 100

local COLOR_PHRASE_NORMAL     = {0x41,0x72,0x29}
local COLOR_PHRASE_SELECTED   = {0XFF,0XEA,0X15}
local COLOR_PHRASE_DIMMED     = {0xA1,0xB2,0x20}
local COLOR_PHRASE_EMPTY      = {0X3F,0X3F,0X3F}
local COLOR_PHRASE_VIRTUAL    = {0XEE,0X1C,0X24}
local COLOR_PHRASE_VIRTUAL_DIMMED  = {0X66,0X0C,0X12}


class 'NTrapUI'

NTrapUI.KEY_REPEAT = 0.05
NTrapUI.KEY_REPEAT_PAUSE = 0.25

NTrapUI.NOTE_ARRAY = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" }

function NTrapUI:__init(ntrap)
  TRACE("NTrapUI:__init()")

  --- (NTrap) instance of main class
  self._ntrap = ntrap

  --- (renoise.ViewBuilder) 
  self._vb = renoise.ViewBuilder()

  --- (renoise.Dialog) reference to the main dialog 
  self._dialog = nil

  --- (renoise.Views.View) 
  self._view = self:build()

  --- (table) currently held keys on the PC keyboard
  -- [key_note] = {
  --  .os_clock
  --  .octave
  -- }
  self._live_keys = {}

  --- (number) whenever a key has been pressed,
  -- it will temporarily halt the output of repeated
  -- keys - we halt our check for this amount of time
  --self._halt_until = nil

  --- (bool)
  self._blink = false

  --- (renoise.Views.View) 
  self._blink_phrase_button = nil

  --- (table<renoise.Views.View>)
  self._phrase_buttons = {}

  --- (number) last time a "phrase bar button" was pressed
  self.last_pressed_time = nil

  --- (int) index of last pressed "phrase bar button" 
  self.last_pressed_idx = nil

  --- (enum = renoise.ApplicationWindow.MIDDLE_FRAME)
  -- remember when we bring focus to the phrase editor
  -- (enable toggling back and forth between layouts)
  self._middle_frame = renoise.app().window.active_middle_frame
  renoise.app().window.active_middle_frame_observable:add_notifier(function()
    local middle_frame = renoise.app().window.active_middle_frame
    if self._middle_frame and
      not (middle_frame == renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR)
    then
      self._middle_frame = renoise.app().window.active_middle_frame
      --print("self._middle_frame via notifier",self._middle_frame)
    end
  end)


end

--------------------------------------------------------------------------------

--- Show the dialog

function NTrapUI:show()
  TRACE("NTrapUI:show()")

  if (not self._dialog or not self._dialog.visible) then
    assert(self._view, "Internal Error. Please report: " .. 
      "no valid content view")

    self._ntrap:apply_settings()
    self._ntrap:attach_to_song()


    -- the keyhandler does not report when keys are released
    -- instead, we maintain a list of triggered notes which are
    -- 'kept alive' for as long as we receive repeated notes...
    local function keyhandler(dialog, key)

      --rprint(key)

      -- @{ built-in shortcuts
      if (key.modifiers == "") then

        -- ignore various completely
        if (key.name == "up") or 
          (key.name == "down") 
        then
          return
        end

        -- select previous/next phrase
        if (key.name == "left") then
          self._ntrap:select_previous_phrase()
          return
        end
        if (key.name == "right") then
          self._ntrap:select_next_phrase()
          return
        end

        if not key.repeated then

          -- prep recording
          if (key.name == "return") then
            self._ntrap:toggle_recording()
            return
          end

          -- delete selected phrase
          if (key.name == "del" 
            and not key.repeated 
            and self._ntrap._phrase_idx) 
          then
            self._ntrap:_delete_selected_phrase()
            return 
          end

          -- (1) cancel recording or (2) toggle edit mode
          if (key.name == "esc") then
            if self._ntrap._record_armed or
              self._ntrap._recording
            then
              self._ntrap:cancel_recording()
            else
              renoise.song().transport.edit_mode = not renoise.song().transport.edit_mode
            end
            return
          end

          -- toggle phrase editor
          if (key.name == "tab") then
            self:_toggle_phrase_editor()
            return
          end
        else

          -- ignore various when repeated
          if (key.name == "up") or 
            (key.name == "down") or
            (key.name == "tab") or
            (key.name == "del")
          then
            return
          end

        end


      end -- @}

      
      -- pass keys without note, or with a modifier 
      if (not key.note) or (key.modifiers ~= "") then
        return key
      end

      local velocity = renoise.song().transport.keyboard_velocity
      local octave = renoise.song().transport.octave

      if not self._live_keys[key.note] then
        
        -- if we pressed multiple buttons, then releasing one
        -- of them - temporarily halting the output - the 
        -- remaining keys will end up here...(ignore)

        if key.repeated then
          return false
        end

        -- add key to live keys
        --print("pressed this key",key.note,os.clock())

        local halt_until = os.clock() + NTrapUI.KEY_REPEAT_PAUSE
        self._live_keys[key.note] = {
          os_clock = os.clock(),
          octave = octave,
          halt_until = halt_until,
        }

        -- any key pressed will temporarily halt keyrepeat
        -- loop through, and apply the halt to all active notes
        for k,v in pairs(self._live_keys) do
          v.halt_until = halt_until
        end

        self._ntrap:input_note(true,key.note,velocity,octave)

      else
        
        -- (rapid key presses...)
        -- if the key is already registered, but arrives
        -- without being repeated, it must have been released
        -- before begin detected as released 

        if not key.repeated then
          --print("quickly repeated key",key.note,os.clock())
          self._ntrap:input_note(true,key.note,velocity,octave,true)

        end

      end
      
      if key.repeated then
        --print("repeated this key",key.note,os.clock())
        self._live_keys[key.note].os_clock = os.clock()
      --else
        --rprint(self._live_keys)
      end
      return key
    end

    self._dialog = renoise.app():show_custom_dialog(
      "Noodletrap", self._view,keyhandler)
  else
    self._dialog:show()
  end

end

--------------------------------------------------------------------------------

--- Hide the dialog

function NTrapUI:hide()
  TRACE("NTrapUI:hide()")

  if (self._dialog and self._dialog.visible) then
    self._dialog:close()
  end

  self._dialog = nil

end

--------------------------------------------------------------------------------

--- Build

function NTrapUI:build()
  TRACE("NTrapUI:build()")

  local vb = self._vb
  local view = vb:column{
    id = 'ntrap_rootnode',
    width = DIALOG_W,
    vb:column{
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      width = "100%",
      self:_build_phrase_bar(),
      self:_build_tabs(),
      vb:column{
        --style = "group",
        height = OPTION_H,
        vb:column{
          id = 'ntrap_tab_input',
          self:_build_tab_inputs(),
        },
        vb:column{
          id = 'ntrap_tab_recording',
          self:_build_tab_recording(),
        },
        vb:column{
          id = 'ntrap_tab_phrases',
          self:_build_tab_phrases(),
        },
        vb:column{
          id = 'ntrap_tab_log',
          self:_build_log_window(),
        },
        vb:column{
          id = 'ntrap_tab_settings',
          self:_build_tab_settings(),
        },
      },

      vb:row{
        self:_build_record_buttons(),
      }
    }
  }

  self:_switch_option_tab(1)

  return view

end

--------------------------------------------------------------------------------

function NTrapUI:_build_phrase_bar()
  TRACE("NTrapUI:_build_phrase_bar()")

  local vb = self._vb
  local view = vb:row {
    style = "group",
    vb:column{
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      vb:text{
        width = CONTENT_W,
        align = "center",
        id = "ntrap_phrase_bar_target_instr",
        text = "",
        font = "big",
        height = 30,
      },
      vb:row{
        width = CONTENT_W,
        id = "ntrap_phrase_bar",

      },
      vb:text{
        width = CONTENT_W,
        align = "center",
        id = "ntrap_phrase_mapping_info",
        text = "",
        height = 30,

      },

    }
  }

  return view

end

--------------------------------------------------------------------------------

function NTrapUI:_build_tabs()
  TRACE("NTrapUI:_build_tabs()")

  local vb = self._vb
  local view = vb:row{
    --width = CONTENT_W,
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    vb:text{
      width = LEFT_COL_W,
      text = "Options",
      font = "bold",
    },
    vb:switch{
      id = "ntrap_opt_tab_recording",
      items = {"Input","Record","Phrase","Events","Settings"},
      width = RIGHT_COL_W,
      value = 1,
      notifier = function(idx)
        self:_switch_option_tab(idx)
      end,
    },
  }
  return view

end

--------------------------------------------------------------------------------

function NTrapUI:_build_tab_inputs()
  TRACE("NTrapUI:_build_tab_inputs()")

  local vb = self._vb
  local input_devices = self:_create_midi_in_list()

  local quantize_items = {"No quantize", "1 line"}
  for k = 2,32 do
    quantize_items[k+1] = ("%d lines"):format(k)
  end

  local view = vb:column{
    width = CONTENT_W,
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,

    vb:row{
      --visible = false,
      vb:text{
        width = LEFT_COL_W,
        text = "Instrument",
      },
      vb:popup{
        id = "ntrap_target_instr",
        width = MIDDLE_W,
        items = NTrapPrefs.INSTR,
        notifier = function(idx)
          self._ntrap:_save_setting("target_instr",idx)
          self:_apply_instrument_from_option(idx)
        end,
      },
      vb:valuebox{
        id = "ntrap_target_instr_custom",
        value = 1,
        width = RIGHT_W,
        min = 1,
        max = 512,
        tonumber = function(str)
          return math.floor(tonumber(str))
        end,
        tostring = function(num)
          return string.format("%d",num)
        end,
        notifier = function(idx)
          self._ntrap:_save_setting("target_instr_custom",idx)
          self._ntrap:_attach_to_instrument(false,idx)
        end,
      },
      vb:text{
        id = "ntrap_target_instr_warning",
        text = "⚠",
        font = "big",
        tooltip = "Instrument not defined in this song",
      },

    },


    vb:row{
      vb:text{
        text = "MIDI Input",
        width = LEFT_COL_W
      },
      vb:popup{
        id = "ntrap_midi_in_popup",
        items = input_devices,
        width = MIDDLE_W,
        value = 1,
        notifier = function(idx)
          --print("*** ntrap_midi_in_popup.notifier",idx)
          self._ntrap:_close_midi_port()
          local port_name = input_devices[idx]
          if (idx > 1) then
            if port_name then
              self._ntrap:_open_midi_port(port_name)
            end
          end
          self._ntrap:_save_setting("midi_in_port",port_name)
        end,
      }
    },


    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "Quantize",
      },
      vb:popup{
        id = "ntrap_record_quantize",
        --active = false,
        width = MIDDLE_W,
        items = NTrapPrefs.QUANTIZE,
        notifier = function(idx)
          self._ntrap:_save_setting("record_quantize",idx)
          self:_apply_quantize_from_option(idx)
        end,
      },
      --[[
      vb:text{
        text = "TODO",
      },
      ]]
      vb:popup{
        id = "ntrap_record_quantize_custom",
        items = quantize_items,
        width = RIGHT_W,
        value = 1,
        notifier = function(idx)
          self._ntrap:_save_setting("record_quantize_custom",idx)

          local popup_preserve = self._vb.views.ntrap_quantize_preserve_length
          local q_amount = self._ntrap:_get_quant_amount()
          popup_preserve.active = q_amount and true or false

        end,
      }
    },

    vb:row{
      vb:text{
        text = " ",
        width = LEFT_COL_W
      },
      vb:checkbox{
        id = "ntrap_quantize_preserve_length",
        value = true,
        notifier = function(val)
          self._ntrap:_save_setting("quantize_preserve_length",val)
        end,
      },
      vb:text{
        text = "Preserve length of quantized notes",
      },
    },

    vb:row{
      vb:text{
        text = "QWERTY",
        width = LEFT_COL_W
      },
      vb:checkbox{
        id = "ntrap_keyboard_enabled",
        value = true,
        notifier = function(val)
          self._ntrap:_save_setting("keyboard_enabled",val)
        end,
      },
      vb:text{
        text = "Receive key presses while dialog is focused",
      },
    },
  }
  return view


end

--------------------------------------------------------------------------------

function NTrapUI:_build_tab_recording()
  TRACE("NTrapUI:_build_tab_recording()")

  local vb = self._vb
  local view = vb:column{  
    width = CONTENT_W,
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "Rec. Arm",
      },
      vb:popup{
        id = "ntrap_arm_recording",
        width = MIDDLE_W,
        items = NTrapPrefs.ARM,
        notifier = function(idx)
          self._ntrap:_save_setting("arm_recording",idx)
          self:update_record_status()
        end,
      },
    },
    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "Rec. Start",
      },
      vb:popup{
        id = "ntrap_start_recording",
        width = MIDDLE_W,
        items = NTrapPrefs.START,
        notifier = function(idx)
          self._ntrap:_save_setting("start_recording",idx)
          self:update_record_status()
        end,
      },
    },
    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "Rec. Split",
      },
      vb:popup{
        id = "ntrap_split_recording",
        width = MIDDLE_W,
        items = NTrapPrefs.SPLIT,
        notifier = function(idx)
          self._ntrap:_save_setting("split_recording",idx)
          self:_apply_split_recording_from_option(idx)
          self:update_record_status()
        end,
      },
      vb:valuebox{
        id = "ntrap_split_recording_lines",
        value = 1,
        width = RIGHT_W,
        min = 1,
        max = 512,
        tonumber = function(str)
          return math.floor(tonumber(str))
        end,
        tostring = function(num)
          return string.format("%d",num)
        end,
        notifier = function(idx)
          self._ntrap:_save_setting("split_recording_lines",idx)
        end,
      },

    },
    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "Rec. Stop",
      },
      vb:popup{
        id = "ntrap_stop_recording",
        width = MIDDLE_W,
        items = NTrapPrefs.STOP,
        notifier = function(idx)
          self._ntrap:_save_setting("stop_recording",idx)
          self:_apply_phrase_stop_from_option(idx)
        end,
      },
      vb:valuebox{
        id = "ntrap_stop_recording_beats",
        value = 1,
        width = RIGHT_W,
        min = 1,
        max = 64,
        tonumber = function(str)
          return math.floor(tonumber(str))
        end,
        tostring = function(num)
          return string.format("%d",num)
        end,
        notifier = function(idx)
          self._ntrap:_save_setting("stop_recording_beats",idx)
        end,
      },
      vb:valuebox{
        id = "ntrap_stop_recording_lines",
        value = 1,
        width = RIGHT_W,
        min = 1,
        max = 512,
        tonumber = function(str)
          return math.floor(tonumber(str))
        end,
        tostring = function(num)
          return string.format("%d",num)
        end,
        notifier = function(idx)
          self._ntrap:_save_setting("stop_recording_lines",idx)
        end,
      },

    },
  }
  return view

end

--------------------------------------------------------------------------------

function NTrapUI:_build_tab_phrases()
  TRACE("NTrapUI:_build_tab_phrases()")

  local vb = self._vb
  local view = vb:column{  
    width = CONTENT_W,
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,

    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "Phrase LPB",
      },
      vb:popup{
        id = "ntrap_phrase_lpb",
        width = MIDDLE_W,
        items = NTrapPrefs.PHRASE_LPB,
        notifier = function(idx)
          self._ntrap:_save_setting("phrase_lpb",idx)
          self:_apply_phrase_lpb_from_option(idx)
        end,
      },
      vb:valuebox{
        id = "ntrap_phrase_lpb_custom",
        --value = self._ntrap._settings.phrase_lpb_custom.value,
        width = RIGHT_W,
        min = 1,
        max = 256,
        tonumber = function(str)
          return math.floor(tonumber(str))
        end,
        tostring = function(num)
          return string.format("%d",num)
        end,
        notifier = function(idx)
          self._ntrap:_save_setting("phrase_lpb_custom",idx)
        end,
      },
    },
    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "Looping",
      },
      vb:popup{
        id = "ntrap_phrase_loop",
        width = MIDDLE_W,
        items = NTrapPrefs.LOOP,
        notifier = function(idx)
          self._ntrap:_save_setting("phrase_loop",idx)
          self:_apply_phrase_loop_from_option(idx)
        end,
      },
      vb:checkbox{
        id = "ntrap_phrase_loop_custom",
        --value = self._ntrap._settings.phrase_loop_custom.value,
        notifier = function(val)
          self._ntrap:_save_setting("phrase_loop_custom",val)
          local ui_label = self._vb.views.ntrap_phrase_loop_custom_label
          ui_label.text = (val) and "Enabled" or "Disabled"    
        end,
      },
      vb:text{
        id = "ntrap_phrase_loop_custom_label",
        text = "",
      }

    },
    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "NoteRange",
      },
      vb:popup{
        id = "ntrap_phrase_range",
        width = MIDDLE_W,
        items = NTrapPrefs.PHRASE_RANGE,
        notifier = function(idx)
          self._ntrap:_save_setting("phrase_range",idx)
          self:_apply_phrase_range_from_option(idx)
        end,
      },
      vb:valuebox{
        id = "ntrap_phrase_range_custom",
        --value = self._ntrap._settings.phrase_range_custom.value,
        width = RIGHT_W,
        min = 1,
        max = 120,
        tonumber = function(str)
          return math.floor(tonumber(str))
        end,
        tostring = function(num)
          return string.format("%d",num)
        end,
        notifier = function(idx)
          self._ntrap:_save_setting("phrase_range_custom",idx)
          self:update_phrase_bar()

        end,
      },
    },
    vb:row{
      vb:text{
        width = LEFT_COL_W,
        text = "KeyTrack",
      },
      vb:popup{
        id = "ntrap_phrase_tracking",
        width = MIDDLE_W,
        --value = self._ntrap._settings.phrase_tracking.value,
        items = NTrapPrefs.PHRASE_TRACKING,
        notifier = function(idx)
          self:_apply_phrase_tracking_from_option(idx)

          self._ntrap:_save_setting("phrase_tracking",idx)
        end,
      },
      vb:popup{
        id = "ntrap_phrase_tracking_custom",
        width = RIGHT_W,
        --value = self._ntrap._settings.phrase_tracking_custom.value,
        items = NTrapPrefs.PHRASE_TRACKING_ITEMS,
        notifier = function(idx)
          self._ntrap:_save_setting("phrase_tracking_custom",idx)
        end,
      },

    },


  }
  return view
  
end

--------------------------------------------------------------------------------

function NTrapUI:_build_log_window()
  TRACE("NTrapUI:_build_log_window()")

  local vb = self._vb
  local widget_id = "ntrap_log_window"
  local view = vb:column{
    vb:space{
      height = 5,
    },
    vb:row{
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      style = "border",
      vb:multiline_text {
        id = widget_id,
        width = CONTENT_W,
        text = "No events to display",
        font = "mono",
        height = 60,
      },
    },
    vb:space{
      height = 5,
    },

  }

  return view

end

--------------------------------------------------------------------------------

function NTrapUI:_build_tab_settings()
  TRACE("NTrapUI:_build_tab_settings()")

  local vb = self._vb
  local view = vb:column{  
    vb:row{
      width = CONTENT_W,
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      vb:text{
        text = "Process\n#notes",
        width = LEFT_COL_W
      },
      vb:valuebox{
        id = "ntrap_yield_counter",
        value = NTrapPrefs.YIELD_DEFAULT,
        width = RIGHT_W-10,
        height = 30,
        min = 10,
        max = 500,
        tonumber = function(str)
          return math.floor(tonumber(str))
        end,
        tostring = function(num)
          return string.format("%d",num)
        end,
        notifier = function(val)
          self._ntrap:_save_setting("yield_counter",val)
        end,
      },
      vb:space{
        width = 6,
      },
      vb:text{
        text = "Lower = less CPU usage while creating phrases, \nHigher = fewer undo points"
      },
    },
    vb:row{
      width = CONTENT_W,
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      vb:text{
        text = "Octave",
        width = LEFT_COL_W
      },
      vb:checkbox{
        id = "ntrap_align_octaves",
        active = false, -- TODO separate MIDI input to make this happen
        value = NTrapPrefs.ALIGN_OCTAVES,
        notifier = function(val)
          self._ntrap:_save_setting("align_octaves",val)
        end,
      },
      vb:text{
        text = "Align MIDI keyboard with the octave in Renoise",
      },
    },
    vb:row{
      width = CONTENT_W,
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      vb:text{
        text = "Startup",
        width = LEFT_COL_W
      },
      vb:checkbox{
        id = "ntrap_autorun_enabled",
        value = NTrapPrefs.AUTORUN_ENABLED,
        notifier = function(val)
          self._ntrap:_save_setting("autorun_enabled",val)
        end,
      },
      vb:text{
        text = "Launch when Renoise starts",
      },
    },
    vb:row{
      width = CONTENT_W,
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      vb:text{
        text = "Phrases",
        width = LEFT_COL_W
      },
      vb:checkbox{
        id = "ntrap_skip_empty_enabled",
        value = NTrapPrefs.SKIP_EMPTY_DEFAULT,
        notifier = function(val)
          self._ntrap:_save_setting("skip_empty_enabled",val)
        end,
      },
      vb:text{
        text = "Do not create empty phrases",
      },
    },
  }
  return view
  
end

--------------------------------------------------------------------------------

function NTrapUI:_build_record_buttons()
  TRACE("NTrapUI:_build_record_buttons()")

  local vb = self._vb
  local view = vb:row{
    --width = CONTENT_W,
    style = "group",
    margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
    vb:horizontal_aligner{
      mode = "justify",
      width = CONTENT_W,
      vb:row{
        vb:button {
          id = "ntrap_record_button",
          text = "",
          tooltip = "Prepare or Stop recording\n[Return or Esc]",
          midi_mapping = "Global:Tools:Noodletrap:Prepare/Record",
          width = 50,
          height = 35,
          notifier = function()
            self._ntrap:toggle_recording()
          end
        },
        vb:button {
          id = "ntrap_split_button",
          text = "Split",
          tooltip = "Split recording\n[Return or Esc]",
          midi_mapping = "Global:Tools:Noodletrap:Split Recording",
          width = 50,
          height = 35,
          notifier = function()
            if self._ntrap._recording then
              if (self._ntrap._settings.split_recording.value == NTrapPrefs.SPLIT_MANUAL) then
                self._ntrap._split_requested_at = os.clock()
              end
            end
          end
        },
      },
      vb:column{
        vb:text{
          id = "ntrap_record_status",
          text = "",
          align = "center",
        },
        vb:minislider{
          id = "ntrap_record_slider",
          width = 120,
          height = 10,
          active = false,
          visible = false,
        },
      },
      vb:button {
        id = "ntrap_cancel_button",
        midi_mapping = "Global:Tools:Noodletrap:Cancel Recording",
        text = "",
        width = 50,
        height = 35,
        notifier = function()
          if self._ntrap._recording or 
            self._ntrap._record_armed 
          then
            self._ntrap:cancel_recording()
          elseif not self._ntrap._record_armed then
            self:hide()
          end
        end
      },

    },
  }
  return view

end


--------------------------------------------------------------------------------

--- Update the entire UI according to current settings

function NTrapUI:update()
  TRACE("NTrapUI:update()")

  if not self._ntrap._active then
    --print("skip update...")
    return
  end

  local settings = self._ntrap._settings
  --print("settings",settings)

  -- midi input port
  local node = settings:property("midi_in_port")
  local ui_widget = self._vb.views.ntrap_midi_in_popup
  local items = self:_create_midi_in_list()
  for k,v in ipairs(items) do
    if (v == node.value) and
      (#ui_widget.items >= k)
    then
      ui_widget.value = k
      break
    end
  end
  

  -- keyboard enabled
  local node = settings:property("keyboard_enabled")
  local ui_widget = self._vb.views.ntrap_keyboard_enabled
  ui_widget.value = node.value


  -- follow instrument / specific instrument
  local node = settings:property("target_instr_custom")
  local ui_widget = self._vb.views.ntrap_target_instr_custom
  ui_widget.value = node.value

  local node = settings:property("target_instr")
  local ui_widget = self._vb.views.ntrap_target_instr
  ui_widget.value = node.value

  self:_apply_instrument_from_option(node.value)

  -- quantize input
  local node = settings:property("record_quantize_custom")
  local ui_widget = self._vb.views.ntrap_record_quantize_custom
  ui_widget.value = node.value

  local node = settings:property("record_quantize")
  local ui_widget = self._vb.views.ntrap_record_quantize
  ui_widget.value = node.value

  self:_apply_quantize_from_option(node.value)


  -- arm recording
  local node = settings:property("arm_recording")
  local ui_widget = self._vb.views.ntrap_arm_recording
  ui_widget.value = node.value
  

  -- start recording
  local node = settings:property("start_recording")
  local ui_widget = self._vb.views.ntrap_start_recording
  ui_widget.value = node.value
  
  -- split recording
  local node = settings:property("split_recording_lines")
  local ui_widget = self._vb.views.ntrap_split_recording_lines
  ui_widget.value = node.value
  
  local node = settings:property("split_recording")
  local ui_widget = self._vb.views.ntrap_split_recording
  ui_widget.value = node.value
  
  self:_apply_split_recording_from_option(node.value)


  -- stop recording
  local node = settings:property("stop_recording_lines")
  local ui_widget = self._vb.views.ntrap_stop_recording_lines
  ui_widget.value = node.value
  
  local node = settings:property("stop_recording_beats")
  local ui_widget = self._vb.views.ntrap_stop_recording_beats
  ui_widget.value = node.value
  
  local node = settings:property("stop_recording")
  local ui_widget = self._vb.views.ntrap_stop_recording
  ui_widget.value = node.value
  
  self:_apply_phrase_stop_from_option(node.value)


  -- phrase lpb
  local node = settings:property("phrase_lpb_custom")
  local ui_widget = self._vb.views.ntrap_phrase_lpb_custom
  ui_widget.value = node.value

  local node = settings:property("phrase_lpb")
  local ui_widget = self._vb.views.ntrap_phrase_lpb
  ui_widget.value = node.value

  self:_apply_phrase_lpb_from_option(node.value)

  -- phrase loop
  local node = settings:property("phrase_loop_custom")
  local ui_widget = self._vb.views.ntrap_phrase_loop_custom
  ui_widget.value = node.value

  local node = settings:property("phrase_loop")
  local ui_widget = self._vb.views.ntrap_phrase_loop
  ui_widget.value = node.value

  self:_apply_phrase_loop_from_option(node.value)


  -- phrase range
  local node = settings:property("phrase_range_custom")
  local ui_widget = self._vb.views.ntrap_phrase_range_custom
  ui_widget.value = node.value

  local node = settings:property("phrase_range")
  local ui_widget = self._vb.views.ntrap_phrase_range
  ui_widget.value = node.value

  self:_apply_phrase_range_from_option(node.value)


  -- phrase tracking
  local node = settings:property("phrase_tracking_custom")
  local ui_widget = self._vb.views.ntrap_phrase_tracking_custom
  ui_widget.value = node.value

  local node = settings:property("phrase_tracking")
  local ui_widget = self._vb.views.ntrap_phrase_tracking
  ui_widget.value = node.value

  self:_apply_phrase_tracking_from_option(node.value)

  -- settings
  local node = settings:property("autorun_enabled")
  local ui_widget = self._vb.views.ntrap_autorun_enabled
  ui_widget.value = node.value

  local node = settings:property("skip_empty_enabled")
  local ui_widget = self._vb.views.ntrap_skip_empty_enabled
  ui_widget.value = node.value

  local node = settings:property("yield_counter")
  local ui_widget = self._vb.views.ntrap_yield_counter
  ui_widget.value = node.value


  -- dedicated updates
  self:update_phrase_bar()
  self:update_record_status()

end


--------------------------------------------------------------------------------

--- Provide some feedback on the current recording status

function NTrapUI:update_record_status()
  --TRACE("NTrapUI:update_record_status()")

  local settings = self._ntrap._settings
  local ui_record_status = self._vb.views.ntrap_record_status
  local ui_record_slider = self._vb.views.ntrap_record_slider
  local ui_record_button = self._vb.views.ntrap_record_button
  local ui_cancel_button = self._vb.views.ntrap_cancel_button
  local ui_split_button  = self._vb.views.ntrap_split_button
  
  local manual_split = 
    (self._ntrap._settings.split_recording.value == NTrapPrefs.SPLIT_MANUAL) 
  ui_split_button.visible = manual_split and true or false
  ui_split_button.active = false 

  if self._ntrap._record_armed then

    local node = settings:property("start_recording")

    if (node.value == NTrapPrefs.START_NOTE) then
      ui_record_status.text = "Waiting for first note to arrive" 
      ui_record_slider.visible = false

    elseif (node.value == NTrapPrefs.START_PLAYBACK) then
      ui_record_status.text = "Waiting for playback to start"
                            --.."\n(phrases are disabled during recording)"
      ui_record_slider.visible = false

    elseif (node.value == NTrapPrefs.START_PATTERN) then
      if not renoise.song().transport.playing then
        ui_record_status.text = "Waiting for playback to start" 
                            --.."\n(phrases are disabled during recording)"
        ui_record_slider.visible = false
      else
        local remaining,total = self._ntrap:_get_pattern_lines_remaining()
        ui_record_slider.visible = true
        ui_record_slider.value = math.abs(remaining-total)/total
        ui_record_status.text = string.format(
                                "Recording will start in %d lines",
                                remaining)
      end
    end
    ui_record_button.text = "Stop"
    ui_record_button.color = {0xff,0xff,0xff}
    ui_cancel_button.text = "Cancel"

  elseif self._ntrap._recording then

    ui_record_button.text = "Stop"
    ui_record_button.color = {0xff,0xff,0xff}
    ui_split_button.active = true
    ui_cancel_button.text = "Cancel"

    local node = settings:property("stop_recording")

    local str_split = ""
    local rec_lines = self._ntrap:_get_recorded_lines()

    if (rec_lines > renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES) then
      str_split = " (ignored > 512)"
    elseif self._ntrap._split_requested_at then      
      str_split = string.format(" (split in %d lines)",
        self._ntrap:_get_split_lines_remaining())
    end


    if (node.value == NTrapPrefs.STOP_NOTE) then
      local slider_value = 0
      --print("self._ntrap._live_voices",self._ntrap._live_voices)
      if (self._ntrap._live_voices == 0) then
        local beats_passed = 0
        local most_recent = self._ntrap:_get_most_recent_event() 
        if most_recent then
          beats_passed = (os.clock() - most_recent.timestamp)
        end
        slider_value = beats_passed/settings.stop_recording_beats.value
      end
      ui_record_slider.visible = true
      ui_record_slider.value = slider_value
      ui_record_status.text = string.format(
                              "Recording %d lines - stop in %d beats %s",
                              rec_lines,
                              settings.stop_recording_beats.value,
                              str_split)

    elseif (node.value == NTrapPrefs.STOP_PATTERN) then
      if self._ntrap._stop_requested then
        local remaining,total = self._ntrap:_get_pattern_lines_remaining()
        ui_record_slider.visible = true
        ui_record_slider.value = math.abs(remaining-total)/total
        ui_record_status.text = string.format(
                                "Recording will stop in %d lines",
                                remaining)
      else
        local recorded_lines = rec_lines
        ui_record_slider.visible = false
        ui_record_status.text = string.format(
                                "Recording %d lines %s",
                                rec_lines,
                                str_split)

      end

    elseif (node.value == NTrapPrefs.STOP_LINES) then
      local remaining,total = self._ntrap:_get_phrase_lines_remaining()
      ui_record_slider.visible = true
      ui_record_slider.value = math.abs(remaining-total)/total
      ui_record_status.text = string.format(
                              "Recording will stop in %d lines",
                              remaining)

    end

  else
    ui_record_status.text = "Hit start to begin recording..." 
    ui_record_button.text = "Start"
    ui_record_button.color = {0x00,0x00,0x00}
    ui_cancel_button.text = "Done"
    ui_record_slider.visible = false

  end


end

--------------------------------------------------------------------------------

--- Provide some feedback on the current recording status

function NTrapUI:update_record_slider(val)
  TRACE("NTrapUI:update_record_slider()")

  val = math.max(0,math.min(1,val))
  self._vb.views.ntrap_record_slider.value = val

end 


--------------------------------------------------------------------------------

--- Update the phrase preview...

function NTrapUI:update_phrase_bar()
  TRACE("NTrapUI:update_phrase_bar()")

  local settings = self._ntrap._settings

  local ui_target_instr = self._vb.views.ntrap_phrase_bar_target_instr
  local ui_mapping_info = self._vb.views.ntrap_phrase_mapping_info
  local ui_phrase_bar   = self._vb.views.ntrap_phrase_bar

  local vphrase = self._ntrap:_get_virtual_phrase()
  local instr = self._ntrap:_get_instrument()
  local instr_name = (instr and instr.name ~= "") and instr.name or "(empty)"
  ui_target_instr.text = string.format(
    "Target instrument: %02d - %.30s", 
    self._ntrap._instr_idx-1,instr_name)

  if vphrase then
    ui_mapping_info.text = string.format(
      "The next recording will be mapped to %s - %s",
      self:_pitch_to_string(vphrase.mapping.note_range[1]),
      self:_pitch_to_string(vphrase.mapping.note_range[2]))
  else
    ui_mapping_info.text = 
        "⚠ There is not enough room for a new recording."
      .."\nPlease select a phrase with free space after it"
  end

  local obtain_button_id_by_index = function(idx)
    return string.format('ntrap_phrase_bar_button_%d',idx)
  end

  -- remove existing buttons
  self._blink_phrase_button = nil
  for k,v in ipairs(self._phrase_buttons) do
    local button_id = obtain_button_id_by_index(k)
    local ui_button = self._vb.views[button_id]
    if ui_button then
      ui_phrase_bar:remove_child(ui_button)
      self._vb.views[button_id] = nil
    end
  end

  -- build the buttons in the bar
  local aspect = CONTENT_W/120

  local build_button = function(from,to,color,tooltip,active,phrase_idx)
    local button = {}
    button.width = (to-from)*aspect
    button.id = obtain_button_id_by_index(#self._phrase_buttons+1)
    button.color = color
    button.active = active
    button.phrase_idx = phrase_idx
    button.tooltip = tooltip
    return button
  end


  local function build_empty_or_virtual(from,to)
    --print("build_empty_or_virtual(from,to)",from,to)

    if vphrase and (from == vphrase.mapping.note_range[1]) then
      -- virtual phrase first
      local vrange = vphrase.mapping.note_range
      local button = build_button(vrange[1],vrange[2],COLOR_PHRASE_VIRTUAL,"New phrase mapping",false)
      self._phrase_buttons:insert(button)
      self._blink_phrase_button = obtain_button_id_by_index(#self._phrase_buttons)

      -- trailing empty space 
      if (vrange[2]+1 < to) then
        local button = build_button(vrange[2]+1,to,COLOR_PHRASE_EMPTY,nil,false)
        self._phrase_buttons:insert(button)
      end

    else

      local button = build_button(from,to,COLOR_PHRASE_EMPTY,nil,false)
      self._phrase_buttons:insert(button)

    end

  end

  self._phrase_buttons = table.create()
  local prev_end
  for k,v in ipairs(instr.phrase_mappings) do

    -- room before mappings
    if (k == 1) and (v.note_range[1] > 0) then
      build_empty_or_virtual(0,v.note_range[1]-1)
    end

    -- room inbetween mappings?
    if prev_end and (prev_end+1 < v.note_range[1]) then
      build_empty_or_virtual(prev_end+1,v.note_range[1]-1)
    end

    -- real, actual phrase (clickable)
    local is_selected = (k == self._ntrap._phrase_idx)

    local is_disabled = nil
    if (RNS_BETA) then
      is_disabled = 
        (instr.phrase_playback_mode == renoise.Instrument.PHRASES_OFF)
    else
      is_disabled = not instr.phrase_playback_enabled 
    end

    local button_color = nil
    if is_selected then
      button_color = is_disabled and COLOR_PHRASE_DIMMED or COLOR_PHRASE_SELECTED
    else
      button_color = COLOR_PHRASE_NORMAL
    end
    local tooltip = string.format("Phrase: %s",v.phrase.name)
                  .."\n[Click] - select this phrase"
                  .."\n[Tab or Double-click] - toggle phrase editor"
                  .."\n[Delete] - remove phrase from instrument"
                  .."\n[Left/Right] - select prev/next phrase"
    local button = build_button(v.note_range[1],v.note_range[2],button_color,tooltip,true,k)
    self._phrase_buttons:insert(button)

    prev_end = v.note_range[2]

  end

  if not prev_end then
    prev_end = -1
  end

  -- trailing space
  if (prev_end < 119) then
    build_empty_or_virtual(prev_end+1,119)
  end

  for k,v in ipairs(self._phrase_buttons) do

    -- what happens when pressed
    local notifier = (v.phrase_idx) and function()
      local sel_instr_idx = renoise.song().selected_instrument_index
      if (self._ntrap._instr_idx == sel_instr_idx) then
        -- check if phrase is still present (another instrument
        -- might have been loaded, phrase becoming invalid...)
        local instr = renoise.song().instruments[sel_instr_idx]
        if (instr and instr.phrases[v.phrase_idx]) then
          renoise.song().selected_phrase_index = v.phrase_idx
        else
          self:update_phrase_bar()
        end
      else
        self._ntrap:_attach_to_phrase(false,v.phrase_idx)
      end
      -- reset click time when a different
      -- phrase button has been clicked 
      if self.last_pressed_idx 
        and (self.last_pressed_idx ~= v.phrase_idx) 
      then
        self.last_pressed_time = nil
        self.last_pressed_idx = nil
      end
      -- check if the phrase button has been
      -- pressed two times within given period
      if self.last_pressed_time then
        if (self.last_pressed_time > (os.clock() - 0.3)) 
        then
          self.last_pressed_time = nil
          self:_toggle_phrase_editor()
        end
      end
      self.last_pressed_time = os.clock()
      self.last_pressed_idx = v.phrase_idx
    end or nil

    local ui_button = self._vb:button{
      id = v.id,
      width = math.max(5,v.width),
      tooltip = v.tooltip,
      color = v.color,
      active = v.active,
      notifier = notifier
    }

    ui_phrase_bar:add_child(ui_button)

  end



end

--------------------------------------------------------------------------------

--- Update blinking elements...

function NTrapUI:update_blinks()
  --TRACE("NTrapUI:update_blinks()")

  local blink = (math.floor(os.clock()%2) == 0) and true or false
  if (blink ~= self._blink) then
    local ui_blink_phrase_button = self._vb.views[self._blink_phrase_button]
    if ui_blink_phrase_button then
      ui_blink_phrase_button.color = (blink) and 
        COLOR_PHRASE_VIRTUAL or COLOR_PHRASE_VIRTUAL_DIMMED
    end
    self._blink = blink

  end

end

--------------------------------------------------------------------------------

function NTrapUI:update_quantize_popup()

  local rns = renoise.song()
  local popup = self._vb.views.ntrap_record_quantize_custom
  if not rns.transport.record_quantize_enabled then
    popup.value = 1
  else
    popup.value = rns.transport.record_quantize_lines+1
  end

end


--------------------------------------------------------------------------------

--- Show warning for missing instrument
-- @param val (bool), false to hide warning

function NTrapUI:show_instrument_warning(val)

  local ui_widget = self._vb.views.ntrap_target_instr_warning
  ui_widget.visible = val

end

--------------------------------------------------------------------------------

--- Add string to the log window

function NTrapUI:log_string(str)
  TRACE("NTrapUI:log_string(str)",str)

  local ui_widget = self._vb.views.ntrap_log_window
  ui_widget:add_line(str)
  ui_widget:scroll_to_last_line()

end

--------------------------------------------------------------------------------

--- Add note to the log window

function NTrapUI:dump_note_info(note)
  TRACE("NTrapUI:dump_note_info(note)",note)

  local str_pitch = self:_pitch_to_string(note.pitch)
  local str = string.format("%-9s : %s Vel:%2X Oct:%1d",
    note.timestamp, (note.is_note_on and str_pitch or "OFF"),
    note.velocity,note.octave)
  
  self:log_string(str)

end

--==============================================================================
-- Private methods
--==============================================================================

--- Periodically purge the list of active keys 

function NTrapUI:_purge_live_keys()
  --TRACE("NTrapUI:_purge_live_keys()")

  if table.is_empty(self._live_keys) then
    return
  end

  local str_status = ""
  for k,v in pairs(self._live_keys) do
    if v.halt_until then
      if (os.clock() > v.halt_until) then
        self._live_keys[k].halt_until = nil
      else
        return
      end
    end
    if (os.clock() > v.os_clock+NTrapUI.KEY_REPEAT) then
      --print("released this key",k,v)
      self._ntrap:input_note(false,k,0,v.octave)
      self._live_keys[k] = nil
    else
      str_status = string.format("%s,%s",str_status,k)
    end
  end

  --renoise.app():show_status(str_status)

end

--------------------------------------------------------------------------------

--- Convert note-column pitch number into Renoise string value
-- @param val - NoteColumn note-value, e.g. 120
-- @return nil or NoteColumn note-string, e.g. "OFF"

function NTrapUI:_pitch_to_string(val)
  TRACE("NTrapUI:_pitch_to_string()")

  if not val then
    return nil
  elseif (val==120) then
    return "OFF"
  elseif(val==121) then
    return "---"
  elseif(val==0) then
    return "C-0"
  else
    local oct = math.floor(val/12)
    local note = NTrapUI.NOTE_ARRAY[(val%12)+1]
    return string.format("%s%s",note,oct)
  end
end

--------------------------------------------------------------------------------

-- @return table

function NTrapUI:_create_midi_in_list()
  TRACE("NTrapUI:_create_midi_in_list()")

  local rslt = {NTrapPrefs.NO_INPUT}
  for k,v in ipairs(renoise.Midi.available_input_devices()) do
    rslt[#rslt+1] = v
  end
  return rslt

end

--------------------------------------------------------------------------------

--- Display the options tab 

function NTrapUI:_switch_option_tab(idx)
  TRACE("NTrapUI:_switch_option_tab(idx)",idx)

  local tabs = {
    self._vb.views.ntrap_tab_input,
    self._vb.views.ntrap_tab_recording,
    self._vb.views.ntrap_tab_phrases,
    self._vb.views.ntrap_tab_log,
    self._vb.views.ntrap_tab_settings,
  }

  for k,v in ipairs(tabs) do
    v.visible = (k == idx) and true or false
  end

end

--------------------------------------------------------------------------------

--- Show the phrase editor UI

function NTrapUI:_toggle_phrase_editor()
  TRACE("NTrapUI:_toggle_phrase_editor()")

  local instr = self._ntrap:_get_instrument()
  if not renoise.app().window.instrument_editor_is_detached then
    local sampler_visible = (renoise.app().window.active_middle_frame == 3) and true or false
    if instr.phrase_editor_visible and sampler_visible then
      self:_hide_phrase_editor()
    else
      self:_show_phrase_editor()
    end
  else
    instr.phrase_editor_visible = true
  end
  
end


--------------------------------------------------------------------------------

function NTrapUI:_show_phrase_editor()

  -- remember middle frame, so we can bring it back
  self._middle_frame = renoise.app().window.active_middle_frame

  local instr = self._ntrap:_get_instrument()
  local middle_frame_const = renoise.ApplicationWindow.MIDDLE_FRAME_INSTRUMENT_SAMPLE_EDITOR
  renoise.app().window.active_middle_frame = middle_frame_const
  instr.phrase_editor_visible = true

end

--------------------------------------------------------------------------------

function NTrapUI:_hide_phrase_editor()

  -- bring back previously store middle frame
  renoise.app().window.active_middle_frame = self._middle_frame

  local instr = self._ntrap:_get_instrument()
  instr.phrase_editor_visible = false

end


--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_instrument_from_option(idx)
  TRACE("NTrapUI:_apply_instrument_from_option(idx)",idx)

  local popup_custom = self._vb.views.ntrap_target_instr_custom
  local val_custom = nil
  if (idx == NTrapPrefs.INSTR_FOLLOW) then
    popup_custom.active = false
    val_custom = renoise.song().selected_instrument_index
  else 
    popup_custom.active = true
    val_custom = popup_custom.value
  end
  popup_custom.value = val_custom

end


--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_quantize_from_option(idx)
  TRACE("NTrapUI:_apply_quantize_from_option(idx)",idx)

  local popup_custom = self._vb.views.ntrap_record_quantize_custom
  popup_custom.active = (idx == NTrapPrefs.QUANTIZE_CUSTOM) and true or false

  local val_custom = nil
  if (idx == NTrapPrefs.QUANTIZE_RENOISE) then
    local quant_enabled = renoise.song().transport.record_quantize_enabled
    if quant_enabled then
      val_custom = renoise.song().transport.record_quantize_lines+1
    else
      val_custom = 1
    end
    
  elseif (idx == NTrapPrefs.QUANTIZE_NONE) then
    val_custom = 1
  elseif (idx == NTrapPrefs.QUANTIZE_CUSTOM) then
    val_custom = popup_custom.value
  else
    error("Unsupported quantize method")
  end
  popup_custom.value = val_custom


end



--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_phrase_lpb_from_option(idx)
  TRACE("NTrapUI:_apply_phrase_lpb_from_option(idx)",idx)

  local popup_custom = self._vb.views.ntrap_phrase_lpb_custom
  local val_custom = nil
  if (idx == NTrapPrefs.LPB_FROM_PHRASE) then
    popup_custom.active = false
    val_custom = self._ntrap:_get_phrase_lpb()
    -- this can fail when no instrument is present...
    -- in such a case, we revert to the custom size 
    if not val_custom then
      val_custom = popup_custom.value or 1
    end
  elseif (idx == NTrapPrefs.LPB_FROM_SONG) then
    popup_custom.active = false
    val_custom = renoise.song().transport.lpb
    -- TODO complain when using old timing model
  elseif (idx == NTrapPrefs.LPB_CUSTOM) then
    popup_custom.active = true
    val_custom = popup_custom.value
  end
  popup_custom.value = val_custom

end

--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_phrase_loop_from_option(idx)
  TRACE("NTrapUI:_apply_phrase_loop_from_option(idx)",idx)

  local popup_custom = self._vb.views.ntrap_phrase_loop_custom
  local val_custom = nil
  if (idx == NTrapPrefs.LOOP_FROM_PHRASE) then
    popup_custom.active = false
    val_custom = self._ntrap:_get_phrase_loop()
  elseif (idx == NTrapPrefs.LOOP_CUSTOM) then
    popup_custom.active = true
    val_custom = popup_custom.value
  end
  popup_custom.value = val_custom


end

--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_split_recording_from_option(idx)
  TRACE("NTrapUI:_apply_split_recording_from_option(idx)",idx)

  local popup_custom = self._vb.views.ntrap_split_recording_lines
  local val_custom = nil
  if (idx == NTrapPrefs.SPLIT_LINES) then
    popup_custom.visible = true
    val_custom = self._ntrap._settings.split_recording_lines.value
  else
    popup_custom.visible = false
    val_custom = renoise.InstrumentPhrase.MAX_NUMBER_OF_LINES
  end
  popup_custom.value = val_custom

end

--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_phrase_range_from_option(idx)
  TRACE("NTrapUI:_apply_phrase_range_from_option(idx)",idx)

  local popup_custom = self._vb.views.ntrap_phrase_range_custom
  local val_custom = nil
  if (idx == NTrapPrefs.PHRASE_RANGE_COPY) then
    popup_custom.active = false
    val_custom = self._ntrap:_get_phrase_range()
  elseif (idx == NTrapPrefs.PHRASE_RANGE_CUSTOM) then
    popup_custom.active = true
    val_custom = popup_custom.value
  end
  popup_custom.value = val_custom

end

--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_phrase_tracking_from_option(idx)
  TRACE("NTrapUI:_apply_phrase_tracking_from_option(idx)",idx)

  local popup_custom = self._vb.views.ntrap_phrase_tracking_custom
  local val_custom = nil
  if (idx == NTrapPrefs.PHRASE_TRACKING_COPY) then
    popup_custom.active = false
    val_custom = self._ntrap:_get_phrase_tracking()
  elseif (idx == NTrapPrefs.PHRASE_TRACKING_CUSTOM) then
    popup_custom.active = true
    val_custom = popup_custom.value
  end
  popup_custom.value = val_custom

end


--------------------------------------------------------------------------------

--- Determine, based on the chosen option

function NTrapUI:_apply_phrase_stop_from_option(idx)
  TRACE("NTrapUI:_apply_phrase_stop_from_option(idx)",idx)

  local ui_beats  = self._vb.views.ntrap_stop_recording_beats
  local ui_lines = self._vb.views.ntrap_stop_recording_lines
  local val_custom = nil
  if (idx == NTrapPrefs.STOP_NOTE) then
    ui_beats.visible = true
    ui_lines.visible = false
  elseif (idx == NTrapPrefs.STOP_PATTERN) then
    ui_beats.visible = false
    ui_lines.visible = false
  elseif (idx == NTrapPrefs.STOP_LINES) then
    ui_beats.visible = false
    ui_lines.visible = true
    self._ntrap:_save_setting("stop_recording_lines",ui_lines.value)
  end

end



