--[[===============================================================================================
xStreamUIGlobalToolbar
===============================================================================================]]--
--[[

User interface for xStream (global toolbar)

]]

--=================================================================================================

local PANEL_W = xStreamUI.FULL_PANEL_W-8

class 'xStreamUIGlobalToolbar'

xStreamUIGlobalToolbar.RENDER_MODE = {
  TRACK_IN_PATTERN = 1,
  SELECTION_IN_TRACK = 2,
  SELECTION_IN_TRACK_REL = 3,
  SELECTED_LINE = 4,
  SELECTED_LINE_REL = 5,
}

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

function xStreamUIGlobalToolbar:update()
  
  local val = self.xstream.ui.compact_mode
  
  local toggle_bt = self.vb.views["xStreamToggleCompactMode"]
  toggle_bt.text = val and "▾" or "▴"

  local selector = self.vb.views["xStreamCompactModelSelector"]
  selector.visible = val

  local logo = self.vb.views["xStreamLogo"] 
  logo.visible = not val
    
  local render_mode_popup = self.vb.views["xStreamRenderModePopup"] 
  render_mode_popup.width = val and 110 or 151
  
end

---------------------------------------------------------------------------------------------------

function xStreamUIGlobalToolbar:build()
  TRACE("xStreamUIGlobalToolbar:build()")

  local vb = self.vb
  return vb:row{ -- xStreamUpperPanel
    margin = 4,
    vb:row{
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
          items = self.xstream.process.models:get_names(),
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
            self.xstream.active = not self.xstream.active
            --[[
            if self.xstream.active then
              self.xstream:stop()
            else
              self.xstream:start()
            end
            ]]
          end,
        },
        vb:button{
          text = "M",
          tooltip = "Mute/unmute stream",
          id = "xStreamMuteButton",
          width = xStreamUI.TRANSPORT_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.xstream.process.muted = not self.xstream.process.muted
          end,
        },
      },
    },
    vb:row{
      spacing = xStreamUI.MIN_SPACING,
      vb:popup{
        id = "xStreamRenderModePopup",
        height = xStreamUI.BITMAP_BUTTON_H,
        items = {
          "Track in pattern",
          "Selection in track",
          "Selection in track (relative)",
          "Line in track",
          "Line in track (relative)",
        }
      },
      vb:button{
        text = "Render",
        id = "xStreamRenderApply",
        height = xStreamUI.BITMAP_BUTTON_H,        
        notifier = function()
          local choices = {
            [xStreamUIGlobalToolbar.RENDER_MODE.TRACK_IN_PATTERN] = function()
              self.xstream.process:fill_track()
            end,
            [xStreamUIGlobalToolbar.RENDER_MODE.SELECTION_IN_TRACK] = function()
              self.xstream.process:fill_selection()
            end,
            [xStreamUIGlobalToolbar.RENDER_MODE.SELECTION_IN_TRACK_REL] = function()
              self.xstream.process:fill_selection(true)
            end,
            [xStreamUIGlobalToolbar.RENDER_MODE.SELECTED_LINE] = function()
              self.xstream.process:fill_line()
            end,
            [xStreamUIGlobalToolbar.RENDER_MODE.SELECTED_LINE_REL] = function()
              self.xstream.process:fill_line(true)
            end,
          }
          local vb_popup = vb.views['xStreamRenderModePopup']
          if (choices[vb_popup.value]) then 
            choices[vb_popup.value]()
          else
            error("Unexpected render mode")
          end
        end
      },
      
    },
    vb:row{       
      vb:button{
        tooltip = "Show favorites",
        text = "★",
        height = xStreamUI.BITMAP_BUTTON_H,
        width = xStreamUI.BITMAP_BUTTON_W,
        notifier = function()
          self.xstream.ui.favorites:show()
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
  }

end
