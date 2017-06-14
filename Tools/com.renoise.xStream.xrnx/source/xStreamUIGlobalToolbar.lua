--[[===============================================================================================
xStreamUIGlobalToolbar
===============================================================================================]]--
--[[

User interface for xStream (global toolbar)

]]

--=================================================================================================

local PANEL_W = xStreamUI.FULL_PANEL_W-8

class 'xStreamUIGlobalToolbar'

--------------------------------------------------------------------------------------------------

function xStreamUIGlobalToolbar:__init(xstream,vb)
  TRACE("xStreamUIGlobalToolbar:__init(xstream,vb)",xstream,vb)

  assert(type(xstream)=="xStream")
  assert(type(vb)=="ViewBuilder")

  self.xstream = xstream 
  self.vb = vb

  self.tool_options_visible = property(self.get_tool_options_visible,self.set_tool_options_visible)
  self.tool_options_visible_observable = renoise.Document.ObservableBoolean(false)

  -- dialogs
  self.options = xStreamUIOptions(self.xstream)

  --== notifiers ==--

  self.tool_options_visible_observable:add_notifier(function()
    TRACE("xStreamUI - self.tool_options_visible_observable fired...")
    self.prefs.tool_options_visible.value = self.tool_options_visible_observable.value
  end)


end

--------------------------------------------------------------------------------------------------

function xStreamUIGlobalToolbar:get_tool_options_visible()
  return self.tool_options_visible_observable.value
end

function xStreamUIGlobalToolbar:set_tool_options_visible(val)
  if val then
    self.options:show()
  else
    self.options:close()
  end
end


---------------------------------------------------------------------------------------------------

function xStreamUIGlobalToolbar:build()
  TRACE("xStreamUIGlobalToolbar:build()")

  local vb = self.vb
  return vb:row{ -- xStreamUpperPanel
    --id = "xStreamUpperPanel",
    margin = 4,
    vb:horizontal_aligner{
      --id = "xStreamTransportAligner",
      mode = "justify",
      width = PANEL_W,
      vb:row{
        --id = "xStreamTransportRow",
        vb:row{
          spacing = xStreamUI.MIN_SPACING,
          vb:column{
            id = "xStreamLogo",
            margin = 2,
            vb:bitmap{
              bitmap = "./source/icons/logo.png",
              width = 100,
              mode = "main_color",
              tooltip = "Read the xStream documentation",
              notifier = function()
                renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.xStream.xrnx")
              end,
            },
          },
          vb:popup{ -- compact mode only: model selector
            items = self.xstream.models:get_available(),
            id = "xStreamCompactModelSelector",
            width = xStreamUI.MODEL_SELECTOR_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            visible = false,
            notifier = function(val)
              self.xstream.selected_model_index = val-1
            end
          },              
          vb:space{
            width = 6,
          },
          vb:button{
            bitmap = "./source/icons/transport_play.bmp",
            tooltip = "Activate streaming and (re-)start playback",
            id = "xStreamStartPlayButton",
            width = xStreamUI.TRANSPORT_BUTTON_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream:start_and_play()
            end,
          },
          vb:button{
            bitmap = "./source/icons/transport_stop.bmp",
            tooltip = "Stop streaming and playback",
            id = "xStreamStopButton",
            width = xStreamUI.TRANSPORT_BUTTON_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              rns.transport:stop()
            end,
          },
          vb:button{
            bitmap = "./source/icons/transport_record.bmp",
            tooltip = "Toggle whether streaming is active",
            id = "xStreamToggleStreaming",
            width = xStreamUI.TRANSPORT_BUTTON_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack.active = not self.xstream.stack.active
            end,
          },
          vb:button{
            text = "M",
            tooltip = "Mute/unmute stream",
            id = "xStreamMuteButton",
            width = xStreamUI.TRANSPORT_BUTTON_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack.muted = not self.xstream.stack.muted
            end,
          },
        },
        vb:space{
          width = 6,
        },
        vb:row{
          spacing = xStreamUI.MIN_SPACING,
          --[[
          vb:button{
            text = "SEQ",
            tooltip = "Apply to the selected patterns in the sequence",
            id = "xStreamApplySequenceButton",
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack:fill_sequence()
            end,
          },
          vb:space{
            width = 6,
          },
          ]]
          vb:button{
            text = "TRK",
            tooltip = "Apply to the selected track",
            id = "xStreamApplyTrackButton",
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack:fill_track()
            end,
          },
          vb:space{
            width = 6,
          },
          vb:button{
            text = "SEL",
            tooltip = "Apply to the selected lines",
            id = "xStreamApplySelectionButton",
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack:fill_selection(true)
            end,
          },
          vb:button{
            text = "↧",
            tooltip = "Apply relative to selection (relative to top of pattern)",
            id = "xStreamApplySelectionLocallyButton",
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack:fill_selection()
            end,
          },       
          vb:space{
            width = 6,
          },
          vb:button{
            text = "LINE",
            tooltip = "Apply to the edited line",
            id = "xStreamApplyLineButton",
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack:fill_line()
            end,
          },
          vb:button{
            text = "↧",
            tooltip = "Apply to the edited line (relative to top of pattern)",
            id = "xStreamApplyLineLocallyButton",
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function()
              self.xstream.stack:fill_line(true)
            end,
          },
        },
      },
      vb:row{       
        vb:button{
          tooltip = "Show favorites",
          text = "★",
          height = xStreamUI.BITMAP_BUTTON_H,
          width = xStreamUI.BITMAP_BUTTON_W,
          notifier = function()
            self.xstream.ui.favorites_ui:show()
          end
        },
        vb:button{
          tooltip = "Show options",
          text = "Options",
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.tool_options_visible = not self.tool_options_visible
          end
        },
        vb:button{
          id = "xStreamToggleCompactMode",
          tooltip = "Toggle between compact and full display",
          text = "-",
          height = xStreamUI.BITMAP_BUTTON_H,
          width = xStreamUI.BITMAP_BUTTON_W,
          notifier = function()
            self.xstream.ui.compact_mode = not self.xstream.ui.compact_mode
          end
        },
      },
    },
  }

end
