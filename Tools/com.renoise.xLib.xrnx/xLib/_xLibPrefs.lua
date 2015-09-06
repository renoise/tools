--[[============================================================================
-- xLibPrefs
============================================================================]]--

--[[--

### About

Manage preferences for the entire xLib suite

--]]

--==============================================================================

class 'xLibPrefs'(renoise.Document.DocumentNode)

-- Configuration Settings

xLibPrefs.MAX_INTERPOLATE = {
  ANY = 1,
  LINEAR = 2,
  CUBIC = 3,
  SINC = 4,
}


function xLibPrefs:__init()

  renoise.Document.DocumentNode.__init(self)

  -- xcleaner specific
  self:add_property("check_unreferenced", renoise.Document.ObservableBoolean(true))
  self:add_property("find_issues", renoise.Document.ObservableBoolean(true))
  self:add_property("find_actual_bit_depth", renoise.Document.ObservableBoolean(true))
  self:add_property("find_channel_issues", renoise.Document.ObservableBoolean(true))
  self:add_property("find_excess_data", renoise.Document.ObservableBoolean(true))
  self:add_property("find_peak_levels", renoise.Document.ObservableBoolean(true))
  self:add_property("skip_empty_samples", renoise.Document.ObservableBoolean(true))
  -- TODO make the following into "conditions" - a more flexible approach, 
  -- Warn condition: specify any sample property to be matched with a specific value
  -- Fix condifiton: like warn, but also providing a solution
  self:add_property("max_bit_depth", renoise.Document.ObservableNumber(16))
  self:add_property("max_interpolation_mode", renoise.Document.ObservableNumber(xLibPrefs.MAX_INTERPOLATE.CUBIC))
  self:add_property("warn_on_oversampling", renoise.Document.ObservableBoolean(true))


  -- general
  self:add_property("autorun_enabled",    renoise.Document.ObservableBoolean(false))
  self:add_property("process_slicing",      renoise.Document.ObservableBoolean(true))
  --self:add_property("yield_counter",      renoise.Document.ObservableNumber(0))

  -- filesystem
  self:add_property("unique_export_names",  renoise.Document.ObservableBoolean(true))

end





