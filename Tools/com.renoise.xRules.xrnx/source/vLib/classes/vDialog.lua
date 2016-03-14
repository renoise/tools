--[[============================================================================
vDialog
============================================================================]]--

--[[

  Standard dialogs for vLib (implement class to supply your own content)

]]

--==============================================================================

class 'vDialog'

function vDialog:__init()

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()

  -- string
  self.title = "This is a dialog"

  -- private --

  -- renoise.Dialog
  self.dialog = nil

  -- renoise.View
  self.dialog_content = nil

end

--------------------------------------------------------------------------------
-- create/re-use existing dialog 

function vDialog:show()

  if not self.dialog or not self.dialog.visible then
    if not self.dialog_content then
      self.dialog_content = self:create_dialog()
    end
    self.dialog = renoise.app():show_custom_dialog(
        self.title, self.dialog_content)
  else
    self.dialog:show()
  end

end

-------------------------------------------------------------------------------
-- @return renoise.Views.Rack

function vDialog:create_dialog()

  local vb = self.vb

  return vb:column{
    vb:text{
      text = "Hello World!"
    },
  }

end

