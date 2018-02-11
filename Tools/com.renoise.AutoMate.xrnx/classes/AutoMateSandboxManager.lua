--[[===============================================================================================
-- AutoMateGenerators.lua
===============================================================================================]]--

--[[--

This class manages instances of AutoMateGenerator or AutoMateTransformer

--]]

--=================================================================================================

class 'AutoMateSandboxManager' (AutoMatePresetManager)

function AutoMateSandboxManager:__init()

  AutoMatePresetManager.__init(self)
  
  local dialog_title = type(self)=="AutoMateGenerators"
    and "AutoMate Generators" or "AutoMate Transformers"

  --- AutoMateSandboxUI
  self._ui = AutoMateSandboxUI(self,dialog_title)
  
  --- triggered when arguments in attached preset have changed 
  self.realtime_output_requested = renoise.Document.ObservableBang()

  --- list of preset notifiers 
  self._preset_notifiers = {}

  -- observables ---------------------

  self._ui.dialog_visible_observable:add_notifier(function()
    print(">>> AutoMateSandboxManager - dialog_visible_observable fired...")
    self:load_presets()
  end)
  
  self.selected_preset_observable:add_notifier(function()
    print(">>> AutoMateSandboxManager - selected_preset_observable fired...")
    if self.selected_preset then 
      --self.selected_preset:save(self:get_path().."test")
      --error("!!!")
      self:_attach_to_preset()
    end

  end)  
end

---------------------------------------------------------------------------------------------------

function AutoMateSandboxManager:_attach_to_preset()
  TRACE("AutoMateSandboxManager:_attach_to_preset()")

  self:_remove_notifiers(self._preset_notifiers)
  
  local preset = self.selected_preset
  if preset then
    for k,arg in ipairs(preset.arguments) do 
      table.insert(self._preset_notifiers,arg.value_changed_observable)
      arg.value_changed_observable:add_notifier(self,
        function()
          print(">>> AutoMateSandboxManager:value_changed_observable fired...")
          local request_output = false 
          if (type(self)=="AutoMateGenerators" and prefs.realtime_generate.value) 
            or (type(self)=="AutoMateTransformers" and prefs.realtime_transform.value)           
          then 
            self.realtime_output_requested:bang()
          end
        end
      )
    end
  end  


end

---------------------------------------------------------------------------------------------------
-- Detach all attached notifiers in list
-- @param observables (table) 

function AutoMateSandboxManager:_remove_notifiers(observables)
  TRACE("AutoMate:_remove_notifiers()",#observables)

  for _,observable in pairs(observables) do
    pcall(function() observable:remove_notifier(self) end)
  end
    
  observables = {}

end

