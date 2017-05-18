--[[============================================================================
vDialogWizard
============================================================================]]--

--[[

  Dialog with next/previous style navigation between 'pages', which in 
  turn can be organized into 'options'

  Page 1    Page 2    Page 3

  Option1 > Option1 > Option1   
  Option2 > Option2
  Option3 > Option3


]]

--==============================================================================

require (_vlibroot.."vDialog")

class 'vDialogWizard' (vDialog)

vDialogWizard.SUBMIT_BT_W = 82
vDialogWizard.LARGE_BUTTON_H = 22

function vDialogWizard:__init(...)
  TRACE("vDialogWizard:__init(...)")

  self.dialog_page = nil
  self.dialog_option = nil

  -- internal

  self._prev_button = nil
  self._next_button = nil
  self._cancel_button = nil


  -- init --
 
  vDialog.__init(self,...)

end


--------------------------------------------------------------------------------
-- override this method

function vDialogWizard:show_prev_page()

end

--------------------------------------------------------------------------------
-- override this method

function vDialogWizard:show_next_page()

end

--------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function vDialogWizard:create_dialog()

  local content = vDialog.create_dialog(self)
  local vb = self.vb 

  return vb:column{
    content,
    self:build_navigation(),
  }


end

--------------------------------------------------------------------------------

function vDialogWizard:build_navigation()

  local vb = self.vb 

  self._prev_button = vb:button{
    text = "Previous",
    active = false,
    height = vDialogWizard.LARGE_BUTTON_H,
    width = vDialogWizard.SUBMIT_BT_W,
    notifier = function()
      self:show_prev_page()
    end,
  }

  self._next_button = vb:button{
    text = "Next",
    height = vDialogWizard.LARGE_BUTTON_H,
    width = vDialogWizard.SUBMIT_BT_W,
    notifier = function()
      self:show_next_page()
    end
  }

  self._cancel_button = vb:button{
    text = "Cancel",
    height = vDialogWizard.LARGE_BUTTON_H,
    width = vDialogWizard.SUBMIT_BT_W,
    notifier = function()
      self.dialog:close()
    end
  }

  return vb:row{
    margin = 6,
    self._prev_button,
    self._next_button,
    self._cancel_button,
  }

end


