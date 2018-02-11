--[[===============================================================================================
-- AutoMateGenerators.lua
===============================================================================================]]--

--[[--

This class manages instances of AutoMateGenerator

--]]

--=================================================================================================

class 'AutoMateGenerators' (AutoMateSandboxManager)

function AutoMateGenerators:__init(app)
  TRACE("AutoMateGenerators:__init(app)",app)

  --- AutoMate
  self._app = app
  
  AutoMateSandboxManager.__init(self)

  -- observables ----------------------

  self.realtime_output_requested:add_notifier(function()
    print(">>> AutoMateGenerators - realtime_output_requested fired...")
    if (self.selected_preset) then 
      self._app:generate()
    end
  end)

end

---------------------------------------------------------------------------------------------------
-- @param target (AutoMate.TARGET)

function AutoMateGenerators:show_dialog(target)
  TRACE("AutoMateGenerators:show_dialog(target)",target)

  self._ui:show()
  self._ui.target = target
end

---------------------------------------------------------------------------------------------------
-- Overridden methods (AutoMatePresetManager)
---------------------------------------------------------------------------------------------------

function AutoMateGenerators:get_path()
  return AutoMateUserData.USERDATA_ROOT .. AutoMateUserData.GENERATORS_FOLDER
end


