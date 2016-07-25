--[[============================================================================
VoiceRunner
============================================================================]]--
--[[

User interface for VoiceRunner

]]

class 'VR_UI' (vDialog)

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

  self.owner.prefs.advanced_settings:add_notifier(function()
    self:update_advanced_settings()
  end)

  self.owner.prefs.sort_mode:add_notifier(function()
    self:update_sort_mode()
  end)

  -- UI

  self.active_tab:add_notifier(function()
    self:update_tabs()
  end)

  -- initialize --

  --self:build()


end

-------------------------------------------------------------------------------

function VR_UI:update_sort_mode()
  TRACE("VR_UI:update_sort_mode()")

  local val = self.owner.prefs.sort_mode.value
  local custom = (val == xVoiceSorter.SORT_MODE.CUSTOM)
  --self.vb.views["remap_options"].visible = custom
  --self.vb.views["pitch_unique"].visible = (val == xVoiceSorter.SORT_MODE.UNIQUE)
  --self.vb.views["pitch_high_to_low"].visible = (val == xVoiceSorter.SORT_MODE.HIGH_TO_LOW)
  --self.vb.views["pitch_low_to_high"].visible = (val == xVoiceSorter.SORT_MODE.LOW_TO_HIGH)

  if custom then
    self.owner.prefs.advanced_settings.value = true
    self:update_advanced_settings()
  end

end

-------------------------------------------------------------------------------

function VR_UI:update_advanced_settings()
  TRACE("VR_UI:update_advanced_settings()")

  local val = self.owner.prefs.advanced_settings.value
  self.vb.views["advanced_settings"].visible = val

end

-------------------------------------------------------------------------------
--[[
function VR_UI:update_template_popup()
  TRACE("VR_UI:update_template_popup()")

  local t = self:get_templates()
  self.vb.views["template_popup"].items = t

end
-------------------------------------------------------------------------------

function VR_UI:update_tabs()
  TRACE("VR_UI:update_tabs()")

  local val = self.vb.views["tab_switcher"].value
  self.vb.views["tab_track"].visible = (val == 1)
  self.vb.views["tab_pitch"].visible = (val == 2)

end
]]

--------------------------------------------------------------------------------
-- import templates from the provided folder
-- @return table<string> or nil
--[[
function VR_UI:get_templates()
  TRACE("VR_UI:get_templates()")

  local str_path = self.owner.prefs.user_folder.value .. "templates/"
  --print("*** scan_template_folder - str_path",str_path)

  if not io.exists(str_path) then
    LOG(str_path,"path does not exist, returning")
    return
  end

  local filenames = os.filenames(str_path,"*.lua")
  for k,v in ipairs(filenames) do
    --print("filenames",k,v)
  end

  return filenames

end
]]

-------------------------------------------------------------------------------

function VR_UI:build()
  TRACE("VR_UI:build()")
  
  local vb = self.vb
  --local DIALOG_W = 150
  local MARGIN = 4
  local SPACING = 4
  local LEFT_PANEL_W = 150
  local RIGHT_PANEL_W = 200
  local LARGE_BUTTON_H = 26
  local HALF_BUTTON_W = LEFT_PANEL_W/2
  local QUARTER_BUTTON_W = LEFT_PANEL_W/4 -2
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
            text = "Sort Notes",
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
        --[[
        vb:row{
          width = LEFT_PANEL_W,
          vb:button{
            text = "Clean Notes",
            width = HALF_BUTTON_W,
            height = LARGE_BUTTON_H,
            notifier = function()
              self.owner:process()
            end
          },
          vb:row{
            vb:button{
              text = "Up",
              tooltip = "Nudge the selection",
              width = QUARTER_BUTTON_W,
              height = LARGE_BUTTON_H,
              notifier = function()
                self.owner:select_voice_run()
              end
            },
            vb:button{
              text = "Down",
              tooltip = "Nudge the selection",
              width = QUARTER_BUTTON_W,
              height = LARGE_BUTTON_H,
              notifier = function()
                self.owner:select_voice_run()
              end
            },
          },
        },
        ]]
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
          spacing = 4,
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
                text = "Sorting & Collection",
                font = "bold",
              },
            },
            --[[
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.compact_mode,
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
            ]]
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.split_at_note,
              },
              vb:text{
                text = "Split at note-change",
              },
            },
            --[[
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.split_at_instrument,
              },
              vb:text{
                text = "Split at instr-change",
              },
            },
            ]]
            vb:row{
              vb:checkbox{
                bind = self.owner.prefs.stop_at_note_off,
              },
              vb:text{
                text = "Stop at note-off",
              },
            },
          },

        },
      },
    },
  }

  self.vb_content = vb_content

  self:update_sort_mode()
  --self:update_template_popup()  
  self:update_advanced_settings()
  --self:update_tabs()

end
