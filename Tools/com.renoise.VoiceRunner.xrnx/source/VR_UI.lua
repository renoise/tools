--[[============================================================================
VoiceRunner
============================================================================]]--
--[[

User interface for VoiceRunner

]]

class 'VR_UI' (vDialog)

--------------------------------------------------------------------------------
-- Multiline text
--------------------------------------------------------------------------------

VR_UI.TXT_PITCH_UNIQUE = [[Unique Columns: sort notes 
by unique pitch/note-column

Note: no more than twelve
different notes can be
used in the same track.

]]

-------------------------------------------------------------------------------

VR_UI.TXT_DISTRIBUTE_TO_TRACKS = [[Detect linked tracks 
and redirect output there
when a match is detected.

Linked tracks are created by
naming the track (or part of
it) after an instrument.
To learn more about this 
feature, see README.md
]]

-------------------------------------------------------------------------------

VR_UI.TXT_CAPTURE_ONCE = [[Keep the instrument which is
nearest to the cursor 

This is the recommended mode
for specific sorting 
]]

-------------------------------------------------------------------------------

VR_UI.TXT_CAPTURE_ALL = [[Keep as many instruments
in the track as possible

This is the recommended mode
for general-purpose sorting
]]

-------------------------------------------------------------------------------

VR_UI.TXT_SPLIT_SELECTED = [[Keep only selected instrument

Note: if the instrument is 
not present in the track,
no output will be produced.
]]

-------------------------------------------------------------------------------

VR_UI.TXT_LOW_TO_HIGH = [[Lowest to highest pitch -->

C-4 -- D#5 -- G-5 --
--- -- --- -- --- --
D#5 -- OFF -- G-5 --
--- -- --- -- --- --
OFF -- --- -- OFF --
]]
-------------------------------------------------------------------------------

VR_UI.TXT_HIGH_TO_LOW = [[Highest to lowest pitch -->

G-5 -- D#5 -- C-4 --
--- -- --- -- --- --
D#5 -- OFF -- C-4 --
--- -- --- -- --- --
OFF -- --- -- OFF --
]]

-------------------------------------------------------------------------------
-- vDialog
-------------------------------------------------------------------------------

function VR_UI:create_dialog()
  TRACE("VR_UI:create_dialog()")

  return self.vb:column{
    self.vb_content,
  }

end

-------------------------------------------------------------------------------

function VR_UI:show()
  TRACE("VR_UI:show()")

  vDialog.show(self)

  --[[
  if self.xstream.prefs.favorites_pinned.value then
    self.favorites:show()
  end
  ]]

end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function VR_UI:__init(...)

  local args = xLib.unpack_args(...)
  assert(type(args.owner)=="VR","Expected 'owner' to be a class instance")
  vDialog.__init(self,...)

  -- variables --

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()

  -- VR (main application)
  self.owner = args.owner

  --self.prefs =  TODO

  self.active_tab = renoise.Document.ObservableNumber(2)

  -- notifiers --

  self.dialog_visible_observable:add_notifier(function()
  end)

  self.owner.prefs.remap_instruments:add_notifier(function()
    self:update_remap_instruments()
  end)

  self.owner.prefs.advanced_settings:add_notifier(function()
    self:update_advanced_settings()
  end)

  self.owner.prefs.sort_mode:add_notifier(function()
    self:update_sort_mode()
  end)

  self.owner.prefs.split_at_note:add_notifier(function()
    print("self.owner.prefs.split_at_note fired...",self.owner.prefs.split_at_note.value)
    self.owner.runner.split_at_note = self.owner.prefs.split_at_note.value
  end)

  self.owner.prefs.split_at_instrument:add_notifier(function()
    print("self.owner.prefs.split_at_instrument fired...",self.owner.prefs.split_at_instrument.value)
    self.owner.runner.split_at_instrument = self.owner.prefs.split_at_instrument.value
  end)

  self.owner.prefs.stop_at_note_off:add_notifier(function()
    print("self.owner.prefs.stop_at_note_off fired...",self.owner.prefs.stop_at_note_off.value)
    self.owner.runner.stop_at_note_off = self.owner.prefs.stop_at_note_off.value
  end)

  -- UI

  self.active_tab:add_notifier(function()
    self:update_tabs()
  end)

  -- initialize --

  --self:build()


end

-------------------------------------------------------------------------------

function VR_UI:update_remap_instruments()
  print("VR_UI:update_remap_instruments()")

  local val = self.owner.prefs.remap_instruments.value
  self.vb.views["split_options"].visible = (val == VR.INSTR_REMAP_MODE.CUSTOM)
  self.vb.views["split_distribute"].visible = (val == VR.INSTR_REMAP_MODE.DISTRIBUTE)
  self.vb.views["split_capture_all"].visible = (val == VR.INSTR_REMAP_MODE.CAPTURE_ALL)
  self.vb.views["split_capture_once"].visible = (val == VR.INSTR_REMAP_MODE.CAPTURE_ONCE)
  self.vb.views["split_selected"].visible = (val == VR.INSTR_REMAP_MODE.SELECTED)
  --self.vb.views["split_to_group"].visible = visible

end

-------------------------------------------------------------------------------

function VR_UI:update_sort_mode()
  print("VR_UI:update_sort_mode()")

  local val = self.owner.prefs.sort_mode.value
  local custom = (val == xVoiceSorter.SORT_MODE.CUSTOM)
  self.vb.views["remap_options"].visible = custom
  self.vb.views["pitch_unique"].visible = (val == xVoiceSorter.SORT_MODE.UNIQUE)
  self.vb.views["pitch_high_to_low"].visible = (val == xVoiceSorter.SORT_MODE.HIGH_TO_LOW)
  self.vb.views["pitch_low_to_high"].visible = (val == xVoiceSorter.SORT_MODE.LOW_TO_HIGH)

  if custom then
    self.owner.prefs.advanced_settings.value = true
    self:update_advanced_settings()
  end

end

-------------------------------------------------------------------------------

function VR_UI:update_advanced_settings()
  print("VR_UI:update_advanced_settings()")

  local val = self.owner.prefs.advanced_settings.value
  self.vb.views["advanced_settings"].visible = val

end

-------------------------------------------------------------------------------

function VR_UI:update_template_popup()
  print("VR_UI:update_template_popup()")

  local t = self:get_templates()
  self.vb.views["template_popup"].items = t

end

-------------------------------------------------------------------------------

function VR_UI:update_tabs()
  print("VR_UI:update_tabs()")

  local val = self.vb.views["tab_switcher"].value
  self.vb.views["tab_track"].visible = (val == 1)
  self.vb.views["tab_pitch"].visible = (val == 2)

end

--------------------------------------------------------------------------------
-- import templates from the provided folder
-- @return table<string> or nil

function VR_UI:get_templates()

  local str_path = self.owner.prefs.user_folder.value .. "templates/"
  print("*** scan_template_folder - str_path",str_path)

  if not io.exists(str_path) then
    LOG(str_path,"path does not exist, returning")
    return
  end

  local filenames = os.filenames(str_path,"*.lua")
  for k,v in ipairs(filenames) do
    print("filenames",k,v)
  end

  return filenames

end


-------------------------------------------------------------------------------

function VR_UI:build()
  
  local vb = self.vb
  --local DIALOG_W = 150
  local MARGIN = 4
  local SPACING = 4
  local LEFT_PANEL_W = 150
  local RIGHT_PANEL_W = 200
  local LARGE_BUTTON_H = 26
  local HALF_BUTTON_W = LEFT_PANEL_W/2
  local PITCH_COLUMN_COL = 48
  local PITCH_NAME_COL = 80
  local PITCH_NOTE_COL = 60
  local PITCH_NOTE_COL = 60

  local vb_content = vb:column{
    margin = MARGIN,
    spacing = SPACING,
    vb:row{
      vb:column{
        --spacing = 4,
        vb:column{
          style = "group",
          margin = MARGIN,
          width = LEFT_PANEL_W,
          vb:chooser{
            width = "100%",
            items = VR.SCOPES,
            bind = self.owner.prefs.selected_scope,
          },
        },
        vb:space{
          height = 4,
        },
        --[[
        vb:column{
          style = "panel",
          margin = MARGIN,
          width = LEFT_PANEL_W,
          vb:row{
            vb:text{
              text = "Record options",
              font = "bold",
            },
          },
          vb:row{
            vb:checkbox{
              bind = self.owner.prefs.monitor_recording,
            },
            vb:text{
              text = "Monitor and sort",
            },
          },
          
        },
        ]]
        vb:column{
          style = "panel",
          margin = MARGIN,
          width = LEFT_PANEL_W,
          vb:row{
            vb:text{
              text = "Sorting",
              font = "bold",
            },
            vb:popup{
              width = LEFT_PANEL_W-56,
              items = xVoiceSorter.SORT_MODES,
              bind = self.owner.prefs.sort_mode,
            },
          },
         
          vb:row{
            vb:checkbox{
              bind = self.owner.prefs.advanced_settings,
            },
            vb:text{
              text = "Advanced settings",
            },
          },
        },
        vb:row{
          width = LEFT_PANEL_W,
          vb:button{
            text = "Sort",
            width = HALF_BUTTON_W,
            height = LARGE_BUTTON_H,
            notifier = function()
              self.owner:process()
            end
          },

          vb:button{
            text = "Select",
            tooltip = "Select the voice-run below the pattern cursor",
            width = HALF_BUTTON_W,
            height = LARGE_BUTTON_H,
            notifier = function()
              self.owner:select_voice_run()
            end
          },
        },
        vb:button{
          text = "Print selection info...",
          width = LEFT_PANEL_W,
          height = LARGE_BUTTON_H,
          notifier = function()
            self.owner:test_list_info()
          end
        },

      },
      vb:column{
        id = "advanced_settings",
        vb:column{
          style = "panel",
          --margin = 6,
          spacing = 4,
          --width = RIGHT_PANEL_W,
          vb:column{
            style = "group",
            width = "100%",
            margin = 4,
            vb:row{
              vb:text{
                text = "Tool Settings",
                font = "bold",
              },
            },
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.autostart,
              },  
              vb:text{
                text = "Display when Renoise starts",
              },
            },
          },
          vb:column{
            style = "group",
            width = "100%",
            margin = 4,
            vb:row{
              vb:text{
                text = "Sorting",
                font = "bold",
              },
            },
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.compact_columns,
              },
              vb:text{
                text = "Compact columns",
              },
            },
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.update_visible_columns,
              },
              vb:text{
                text = "Match visible cols.",
              },
            },
          },
          vb:column{
            style = "group",
            width = "100%",
            margin = 4,
            vb:row{
              vb:text{
                text = "Voice-runs",
                font = "bold",
              },
            },
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.split_at_note,
              },
              vb:text{
                text = "Split at note-change",
              },
            },
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.split_at_instrument,
              },
              vb:text{
                text = "Split at instr-change",
              },
            },
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.stop_at_note_off,
              },
              vb:text{
                text = "Stop at note-off",
              },
            },
          },

          vb:switch{
            visible = false,
            id = "tab_switcher",
            items = {"Instrument & Track","Pitch & Column"},
            width = RIGHT_PANEL_W,
            bind = self.active_tab,
          },
          vb:column{
            id = "tab_track",
            spacing = 4,
            --[[
            vb:text{
              text = "Instruments & Tracks",
              font = "bold",
            },
            ]]
            vb:row{
              vb:text{
                text = "Mode",
              },
              vb:popup{
                bind = self.owner.prefs.remap_instruments,
                items = VR.INSTR_REMAP_MODES,
                width = 150,
              },

            },
            vb:column{
              id = "split_options",
              style = "border",
              width = RIGHT_PANEL_W,
              margin = 6,
              visible = false,
              self.owner.template:build_instrument_table(),
            },
            vb:column{
              id = "split_distribute",
              style = "group",
              margin = 6,
              width = RIGHT_PANEL_W,
              vb:text{
                text = VR_UI.TXT_DISTRIBUTE_TO_TRACKS,
                font = "mono",
              },
            },
            vb:column{
              id = "split_capture_all",
              style = "group",
              margin = 6,
              width = RIGHT_PANEL_W,
              vb:text{
                text = VR_UI.TXT_CAPTURE_ALL,
                font = "mono",
              },
            },
            vb:column{
              id = "split_capture_once",
              style = "group",
              margin = 6,
              width = RIGHT_PANEL_W,
              vb:text{
                text = VR_UI.TXT_CAPTURE_ONCE,
                font = "mono",
              },
            },
            vb:column{
              id = "split_selected",
              style = "group",
              margin = 6,
              width = RIGHT_PANEL_W,
              vb:text{
                text = VR_UI.TXT_SPLIT_SELECTED,
                font = "mono",
              },
            },

          },
          vb:column{
            id = "tab_pitch",
            spacing = 4,
            --[[
            vb:text{
              text = "Pitch & Note Columns",
              font = "bold",
            },
            ]]
            vb:row{
              vb:text{
                text = "Sort mode",
              },
              vb:popup{
                bind = self.owner.prefs.sort_mode,
                items = xVoiceSorter.SORT_MODES_FULL,
                width = RIGHT_PANEL_W-55,
              },

            },
            vb:column{
              id = "pitch_unique",
              style = "group",
              margin = 6,
              width = RIGHT_PANEL_W,
              vb:text{
                text = VR_UI.TXT_PITCH_UNIQUE,
                font = "mono",
              },
            },
            vb:column{
              id = "pitch_high_to_low",
              style = "group",
              margin = 6,
              width = RIGHT_PANEL_W,
              vb:text{
                text = VR_UI.TXT_HIGH_TO_LOW,
                font = "mono",
              },
            },
            vb:column{
              id = "pitch_low_to_high",
              style = "group",
              margin = 6,
              width = RIGHT_PANEL_W,
              vb:text{
                text = VR_UI.TXT_LOW_TO_HIGH,
                font = "mono",
              },
            },

            vb:column{
              id = "remap_options",
              style = "group",
              margin = 6,
              spacing = 4,
              width = RIGHT_PANEL_W,
              vb:row{
                vb:text{
                  text = "Template",
                },
                vb:popup{
                  id = "template_popup",
                  items = {},
                  width = RIGHT_PANEL_W - 62,
                }
              },
              vb:row{
                vb:text{
                  text = "Column",
                  width = PITCH_COLUMN_COL,
                },
                vb:text{
                  text = "Name",
                  width = PITCH_NAME_COL,
                },
                vb:text{
                  text = "Note",
                  width = PITCH_NOTE_COL,
                },
              },
              self.owner.template:build_pitch_table(),
            }
          },
        },
      },
    },
  }

  self.vb_content = vb_content

  self:update_sort_mode()
  self:update_template_popup()  
  self:update_remap_instruments()
  self:update_advanced_settings()
  self:update_tabs()

end
