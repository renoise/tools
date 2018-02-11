--[[===============================================================================================
-- AutoMate.lua
===============================================================================================]]--

--[[--

# AutoMate Library 

Contains re-usable clips that are stored on disk 

--]]

--=================================================================================================

class 'AutoMateLibrary' (AutoMatePresetManager)

---------------------------------------------------------------------------------------------------
-- Constructor

function AutoMateLibrary:__init(app)
  TRACE("AutoMateLibrary:__init(app)",app)

  AutoMatePresetManager.__init(self)

  assert(type(app)=="AutoMate")
  
  --- (AutoMate) instance of main class
  self._app = app
  
  --- (AutoMateLibrary)
  self._ui = AutoMateLibraryUI(self)

  -- observables ----------------------
  
  --- observables ---------------------

  self._ui.dialog_visible_observable:add_notifier(function()
    print(">>> AutoMateLibrary - dialog_visible_observable fired...")
    self:load_presets()
  end)


end

---------------------------------------------------------------------------------------------------

function AutoMateLibrary:show_dialog()
  TRACE("AutoMateLibrary:show_dialog()")

  self._ui:show()

end

---------------------------------------------------------------------------------------------------

function AutoMateLibrary:copy_to_clipboard()
  TRACE("AutoMateLibrary:copy_to_clipboard()")

  if not self.selected_preset then 
    renoise.app():show_warning("No preset is selected")
    return 
  end

  self._app.clipboard = self.selected_preset

end

---------------------------------------------------------------------------------------------------

function AutoMateLibrary:apply_preset_to_pattern()
  TRACE("AutoMateLibrary:apply_preset_to_pattern()")

  if not self.selected_preset then 
    renoise.app():show_warning("No preset is selected")
    return 
  end

  self._app:paste(function(success,msg_or_err)
    --print("success,msg_or_err",success,msg_or_err)
  end,self._selected_preset)

end

---------------------------------------------------------------------------------------------------
-- Overridden methods (AutoMatePresetManager)
---------------------------------------------------------------------------------------------------

function AutoMateLibrary:get_path()
  TRACE("AutoMateLibrary:get_path()")
  return AutoMateUserData.USERDATA_ROOT .. AutoMateUserData.LIBRARY_FOLDER
end


