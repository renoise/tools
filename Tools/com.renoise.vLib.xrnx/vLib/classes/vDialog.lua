--[[============================================================================
vDialog
============================================================================]]--

--[[

  Standard dialogs for vLib (implement class to supply your own content)

]]

--==============================================================================

class 'vDialog'

vDialog.DEFAULT_DIALOG_TITLE = "This is a dialog"

function vDialog:__init(...)
  TRACE("vDialog:__init()")

  local args = cLib.unpack_args(...)

  -- string
  self.dialog_title = self.dialog_title and self.dialog_title or args.dialog_title or vDialog.DEFAULT_DIALOG_TITLE

  -- renoise.View
  self.dialog_content = args.dialog_content or nil

  -- function, custom keyhandler
  self.dialog_keyhandler = args.dialog_keyhandler or function() end

  --- function, supply your own idle notifier here
  -- (will only start once Renoise has an active document)
  --self.on_idle_notifier = args.on_idle_notifier or nil

  --- bool, set to true to wait until Renoise has a document
  self.waiting_to_show_dialog = args.waiting_to_show_dialog or false

  -- events --

  --- when dialog is opened
  self.dialog_visible_observable = renoise.Document.ObservableBang()

  --- when dialog is closed
  -- TODO 
  --self.dialog_hidden_observable = renoise.Document.ObservableBang()

  --- when dialog gains focus
  -- TODO make it work both when invoked manually and programatically 
  self.dialog_became_active_observable = renoise.Document.ObservableBang()

  --- when dialog looses focus
  -- TODO make it work when invoked manually and/or programatically 
  --self.dialog_resigned_active_observable = renoise.Document.ObservableBang()

  -- private --

  -- renoise.Dialog
  self.dialog = nil

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()

  -- initialize --

  if self.waiting_to_show_dialog then
    renoise.tool().app_idle_observable:add_notifier(self,self.idle_notifier_waiting)
  end

end

--------------------------------------------------------------------------------
-- create/re-use existing dialog 

function vDialog:show()
  TRACE("vDialog:show()")

  if self.waiting_to_show_dialog then
    return false
  end

  if not self.dialog or not self.dialog.visible then
    if not self.dialog_content then
      self.dialog_content = self:create_dialog()
    end
    self.dialog = renoise.app():show_custom_dialog(
      self.dialog_title, self.dialog_content,function(dialog,key)
        return self:dialog_keyhandler(dialog,key)
      end)
    self.dialog_visible_observable:bang()
  else
    self.dialog:show()
    self.dialog_became_active_observable:bang()
  end

  return true

end

-------------------------------------------------------------------------------
-- @return renoise.Views.Rack

function vDialog:create_dialog()
  TRACE("vDialog:create_dialog()")

  local vb = self.vb
  return vb:column{
    vb:text{
      text = "Hello World!"
    },
  }

end

-------------------------------------------------------------------------------

function vDialog:dialog_is_visible()
  --TRACE("vDialog:dialog_is_visible()")

  return self.dialog and self.dialog.visible or false

end

-------------------------------------------------------------------------------
-- wait with launch until tool has a renoise document to work on
-- workaround for http://goo.gl/UnSDnw

function vDialog:idle_notifier_waiting()
  TRACE("vDialog:idle_notifier_waiting()")

  local idle_obs = renoise.tool().app_idle_observable
  local remove_notifier = false

  if self.waiting_to_show_dialog 
    and renoise.song() 
  then
    self.waiting_to_show_dialog = false
    self:show() 
    remove_notifier = true
  end  

  if remove_notifier and idle_obs:has_notifier(self,vDialog.idle_notifier_waiting) then
    idle_obs:remove_notifier(self,vDialog.idle_notifier_waiting)
  end

end

-------------------------------------------------------------------------------

