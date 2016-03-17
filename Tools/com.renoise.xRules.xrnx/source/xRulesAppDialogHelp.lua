--[[============================================================================
xRulesAppDialogHelp
============================================================================]]--

--[[

  This is a supporting class for xRulesApp

]]

--==============================================================================

class 'xRulesAppDialogHelp' (vDialog)

function xRulesAppDialogHelp:__init(ui)
  TRACE("xRulesAppDialogHelp:__init()",ui)

  vDialog.__init(self)

  -- xRulesUI, instance of parent class
  self.ui = ui

  -- string
  self.title = "xRules - help & reference"

end

-------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xRulesAppDialogHelp:create_dialog()
  TRACE("xRulesAppDialogHelp:create_dialog()")

  local vb = self.vb

  return vb:column{
    vb:multiline_text{
      width = 400,
      height = 300,
      font = "mono",
      text = [[xRules - help & reference
-----------------------------------------------------------

]]
    },
  }

end

