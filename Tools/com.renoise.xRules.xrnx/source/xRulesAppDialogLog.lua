--[[============================================================================
xRulesAppDialogLog
============================================================================]]--

--[[

  This is a supporting class for xRulesApp

]]

--==============================================================================

class 'xRulesAppDialogLog' (vDialog)

function xRulesAppDialogLog:__init(ui)

  vDialog.__init(self)

  -- xRulesUI, instance of parent class
  self.ui = ui

  -- string
  self.title = "xRules - Log window"

  -- vLogView
  self.vlog = nil

end

-------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xRulesAppDialogLog:create_dialog()

  local vb = self.vb

  self.vlog = vLogView{
    vb = vb,
    width = 640,
    height = 300,
  }

  local dialog_view = vb:column{
    self.vlog.view,
    vb:horizontal_aligner{
      vb:row{
        id = "clear_button_container",
      }
    },
    --[[
    vb:button{
      text = "remove traces",
      notifier = function()
        xDebug.remove_trace_statements()
      end
    }
    ]]
  }

  -- add views --

  self.vlog:add_view('clear_button',self.vb.views["clear_button_container"])


  return dialog_view

end

