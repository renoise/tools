--[[============================================================================
xStreamFavorite
============================================================================]]--
--[[

  A favorites is a combination of a model and (optionally) preset, with some 
  additional settings for how to launch the favorite when triggered. 

]]

--==============================================================================

class 'xStreamFavorite'

function xStreamFavorite:__init(args)

  args = args or {}

	self.model_name = property(self.get_model_name,self.set_model_name)
	self.model_name_observable = renoise.Document.ObservableString(args.model_name or "")

	self.preset_index = property(self.get_preset_index,self.set_preset_index)
	self.preset_index_observable = renoise.Document.ObservableNumber(args.preset_index or 0)

	self.preset_bank_name = property(self.get_preset_bank_name,self.set_preset_bank_name)
	self.preset_bank_name_observable = renoise.Document.ObservableString(args.preset_bank_name or xStreamModelPresets.DEFAULT_BANK_NAME)

	self.schedule_mode = property(self.get_schedule_mode,self.set_schedule_mode)
	self.schedule_mode_observable = renoise.Document.ObservableNumber(args.schedule_mode or xStreamPos.SCHEDULE.BEAT)

	self.launch_mode = property(self.get_launch_mode,self.set_launch_mode)
	self.launch_mode_observable = renoise.Document.ObservableNumber(args.launch_mode or xStreamFavorites.LAUNCH_MODE.AUTOMATIC)

	self.apply_mode = property(self.get_apply_mode,self.set_apply_mode)
	self.apply_mode_observable = renoise.Document.ObservableNumber(args.apply_mode or xStreamFavorites.APPLY_MODE.PATTERN)

end

-------------------------------------------------------------------------------
-- Get/set methods
-------------------------------------------------------------------------------

function xStreamFavorite:get_model_name()
  return self.model_name_observable.value
end

function xStreamFavorite:set_model_name(val)
  assert(type(val)=="string")
  self.model_name_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamFavorite:get_preset_index()
  return self.preset_index_observable.value
end

function xStreamFavorite:set_preset_index(val)
  assert(type(val)=="number")
  self.preset_index_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamFavorite:get_preset_bank_name()
  return self.preset_bank_name_observable.value
end

function xStreamFavorite:set_preset_bank_name(val)
  assert(type(val)=="string")
  self.preset_bank_name_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamFavorite:get_schedule_mode()
  return self.schedule_mode_observable.value
end

function xStreamFavorite:set_schedule_mode(val)
  assert(val >= 1 and val <= #xStreamPos.SCHEDULES)
  self.schedule_mode_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamFavorite:get_launch_mode()
  return self.launch_mode_observable.value
end

function xStreamFavorite:set_launch_mode(val)
  assert(val >= 1 and val <= #xStreamFavorites.LAUNCH_MODES_SHORT)
  self.launch_mode_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamFavorite:get_apply_mode()
  return self.apply_mode_observable.value
end

function xStreamFavorite:set_apply_mode(val)
  assert(val >= 1 and val <= #xStreamFavorites.APPLY_MODES)
  self.apply_mode_observable.value = val
end

-------------------------------------------------------------------------------

function xStreamFavorite:__tostring()

  return ("xStreamFavorite: model_name = "..self.model_name..", preset_index = "..tostring(self.preset_index)..", preset_bank_name = "..self.preset_bank_name)

end
