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

  local args = vLib.unpack_args(...)

  -- string
  self.dialog_title = args.dialog_title or vDialog.DEFAULT_DIALOG_TITLE

  -- renoise.View
  self.dialog_content = args.dialog_content or nil

  -- function, custom keyhandler
  self.dialog_keyhandler = args.dialog_keyhandler or nil

  --- function, supply your own idle notifier here
  -- (will only start once Renoise has an active document)
  self.on_idle_notifier = args.on_idle_notifier or nil

  --- bool, set to true to wait until Renoise has a document
  self.waiting_to_show_dialog = args.waiting_to_show_dialog or false

  self.suspend_when_hidden = args.suspend_when_hidden or false

  -- events --

  --- when dialog is opened
  self.dialog_visible_observable = renoise.Document.ObservableBang()

  --- when dialog is closed
  self.dialog_hidden_observable = renoise.Document.ObservableBang()

  --- when dialog gains focus
  -- TODO make it work both when invoked manually and programatically 
  self.dialog_became_active_observable = renoise.Document.ObservableBang()

  --- when dialog looses focus
  -- TODO make it work when invoked manually and/or programatically 
  self.dialog_resigned_active_observable = renoise.Document.ObservableBang()

  -- private --

  -- renoise.Dialog
  self.dialog = nil

  -- renoise.ViewBuilder
  self.vb = renoise.ViewBuilder()


  -- initialize --

  renoise.tool().app_idle_observable:add_notifier(function()
    self:idle_notifier_waiting()
  end)


end

--------------------------------------------------------------------------------
-- create/re-use existing dialog 

function vDialog:show()
  TRACE("vDialog:show()")

  if self.waiting_to_show_dialog then
    return
  end

  if not self.dialog or not self.dialog.visible then
    -- create, or re-create if hidden
    if not self.dialog_content then
      self.dialog_content = self:create_dialog()
    end
    print("self.dialog_content",self.dialog_content)
    self.dialog = renoise.app():show_custom_dialog(
        self.dialog_title, self.dialog_content,self.dialog_keyhandler)

    -- notifier: remove pre-launch
    local idle_obs = renoise.tool().app_idle_observable
    if idle_obs:has_notifier(self.idle_notifier_waiting) then
      idle_obs:remove_notifier(self.idle_notifier_waiting)
    end
  
    -- notifier: switch to actual
    if self.on_idle_notifier then
      if idle_obs:has_notifier(self.on_idle_notifier) then
        idle_obs:remove_notifier(self.on_idle_notifier)
      end
      idle_obs:add_notifier(self.on_idle_notifier)
    end

    self.dialog_visible_observable:bang()

  else
    -- bring existing/visible dialog to front
    self.dialog:show()
    self.dialog_became_active_observable:bang()
  end

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
-- @return boolean, true if we should suspend

function vDialog:dialog_is_suspended()
  return (self.suspend_when_hidden) and
    self.dialog and not self.dialog.visible
end

-------------------------------------------------------------------------------
-- wait with launch until tool has a renoise document to work on
-- workaround for http://goo.gl/UnSDnw

function vDialog:idle_notifier_waiting()
  --print(">>> vDialog:idle_notifier_waiting()")
  if self.waiting_to_show_dialog then
    self.waiting_to_show_dialog = false
    self:show() 
  end  

end
