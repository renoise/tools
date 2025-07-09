--[[
This tool was originally created by danoise,
and somewhat heavily modified by Esa Ruoho a.k.a. Lackluster.
]]--

rns = nil -- reference to renoise.song() 
_trace_filters = nil -- don't show traces in console
--_trace_filters = {".*"}
--_trace_filters = {"^xOscClient"}
-- Only show essential Sononym-related traces, filter out noisy UI/library traces
_trace_filters = {
  "sononym%.db", "%.flac", "%.wav", "%.aiff", -- Show sample file info
  "parsed selection:", "Found filename:", "selectedLocationPath:", -- Show Sononym data
  "Selected Sample Full path:", "Sample loaded:", "Failed to load sample:" -- Show load results
}

_clibroot = 'source/cLib/classes/'

require (_clibroot..'cLib')
require (_clibroot..'cDebug')
require (_clibroot..'cFileMonitor')

---------------------------------------------------------------------------------------------------
-- Sample utility functions (replacement for xLib xSample functions)
---------------------------------------------------------------------------------------------------

-- Get sample buffer if it exists and has sample data
-- @param sample (renoise.Sample)
-- @return renoise.SampleBuffer or nil 
function get_sample_buffer(sample) 
  TRACE("get_sample_buffer(sample)",sample)
  
  if sample.sample_buffer 
    and sample.sample_buffer.has_sample_data
  then
    return sample.sample_buffer
  end
end 

-- Get sample name, as it appears in the sample-list (untitled samples included)
-- @param sample (renoise.Sample)
-- @param sample_idx (number)
-- @return string
function get_display_name(sample,sample_idx)
  TRACE("get_display_name(sample,sample_idx)",sample,sample_idx)
  assert(type(sample)=="Sample")
  assert(type(sample_idx)=="number")
  return (sample.name == "") 
    and ("Sample %02X"):format(sample_idx-1) 
    or sample.name
end

---------------------------------------------------------------------------------------------------
-- AppPrefs class (needs to be defined before requiring other modules that use it)
---------------------------------------------------------------------------------------------------
class 'AppPrefs'(renoise.Document.DocumentNode)
---------------------------------------------------------------------------------------------------
-- constructor, initialize with default values
function AppPrefs:__init()
  renoise.Document.DocumentNode.__init(self)
  self:add_property("autostart", renoise.Document.ObservableBoolean(false))
  self:add_property("autotransfercreatenew", renoise.Document.ObservableBoolean(false))
  self:add_property("autotransfercreateslot", renoise.Document.ObservableBoolean(false))
  self:add_property("polling_interval", renoise.Document.ObservableNumber(1))
  self:add_property("path_to_exe", renoise.Document.ObservableString(""))
  self:add_property("path_to_config", renoise.Document.ObservableString(""))
  self:add_property("show_transfer_warning", renoise.Document.ObservableBoolean(true))
  self:add_property("show_search_warning", renoise.Document.ObservableBoolean(true))
  self:add_property("show_prefs", renoise.Document.ObservableBoolean(true))
end

require ('AppUI')
require ('App')

---------------------------------------------------------------------------------------------------
-- local variables & initialization
---------------------------------------------------------------------------------------------------
local TOOL_NAME = "Sononymph"
local TOOL_VERSION = "1.10"

local prefs = AppPrefs()
renoise.tool().preferences = prefs

local app = nil 

---------------------------------------------------------------------------------------------------
function start(do_show)
  rns = renoise.song()
  if not app then 
    app = App{
      prefs = prefs,
      tool_name = "Sononymph",
      tool_version = TOOL_VERSION,
      waiting_to_show_dialog = prefs.autostart.value
    }
  end
  if do_show then app.ui:show() end
end


-- Search Selected Sample function
local function search_selected_sample()
  start(true) -- Open dialog
  if app and app.ui.dialog and app.ui.dialog.visible then
    app:search_selected_sample()
  end
end

renoise.tool():add_midi_mapping{name="Sononymph:Toggle Sononym Auto-Transfer [Trigger]",invoke=function() start(false) if app then app:toggle_live_transfer() end end}
renoise.tool():add_midi_mapping{name="Sononymph:Open Sononymph Dialog...", invoke=function() start(true) end}
renoise.tool():add_midi_mapping{name="Sononymph:Search Selected Sample in Sononym [Trigger]",invoke=function() search_selected_sample() end}
renoise.tool():add_midi_mapping{name="Sononymph:Load Selected Sample from Sononym (Prompt) [Trigger]",invoke=function(message) if message:is_trigger() then start(false) if app then app:load_selected_sample_from_sononym(true) end end end}
renoise.tool():add_midi_mapping{name="Sononymph:Load Selected Sample from Sononym (No Prompt) [Trigger]",invoke=function(message) if message:is_trigger() then start(false) if app then app:load_selected_sample_from_sononym(false) end end end}

renoise.tool():add_keybinding{name="Global:Sononymph:Toggle Sononym Auto-Transfer [Trigger]", invoke=function() start(false) if app then app:toggle_live_transfer() end end}
renoise.tool():add_keybinding{name="Global:Sononymph:Open Sononymph Dialog...", invoke=function() start(true) end}
renoise.tool():add_keybinding{name="Global:Sononymph:Search Selected Sample in Sononym", invoke=search_selected_sample}
renoise.tool():add_keybinding{name="Global:Sononymph:Load Selected Sample from Sononym (Prompt) [Trigger]", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(true) end end}
renoise.tool():add_keybinding{name="Global:Sononymph:Load Selected Sample from Sononym (No Prompt) [Trigger]", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(false) end end}

renoise.tool():add_menu_entry{name="Instrument Box:Sononymph:Open Sononymph Dialog...", invoke = function() start(true) end}
renoise.tool():add_menu_entry{name="--Instrument Box:Sononymph:Toggle Sononym Auto-Transfer", invoke = function() start(false) if app then app:toggle_live_transfer() end end}
renoise.tool():add_menu_entry{name="Instrument Box:Sononymph:Search Selected Sample in Sononym", invoke = search_selected_sample}
renoise.tool():add_menu_entry{name="Instrument Box:Sononymph:Load Selected Sample from Sononym (Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(true) end end}
renoise.tool():add_menu_entry{name="Instrument Box:Sononymph:Load Selected Sample from Sononym (No Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(false) end end}

renoise.tool():add_menu_entry{name="Sample Editor:Sononymph:Open Sononymph Dialog...", invoke = function() start(true) end}
renoise.tool():add_menu_entry{name="--Sample Editor:Sononymph:Toggle Sononym Auto-Transfer", invoke = function() start(false) if app then app:toggle_live_transfer() end end}
renoise.tool():add_menu_entry{name="Sample Editor:Sononymph:Search Selected Sample in Sononym", invoke = search_selected_sample}
renoise.tool():add_menu_entry{name="Sample Editor:Sononymph:Load Selected Sample from Sononym (Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(true) end end}
renoise.tool():add_menu_entry{name="Sample Editor:Sononymph:Load Selected Sample from Sononym (No Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(false) end end}

renoise.tool():add_menu_entry{name="Sample Navigator:Sononymph:Open Sononymph Dialog...", invoke = function() start(true) end}
renoise.tool():add_menu_entry{name="--Sample Navigator:Sononymph:Toggle Sononym Auto-Transfer", invoke = function() start(false) if app then app:toggle_live_transfer() end end}
renoise.tool():add_menu_entry{name="Sample Navigator:Sononymph:Search Selected Sample in Sononym", invoke = search_selected_sample}
renoise.tool():add_menu_entry{name="Sample Navigator:Sononymph:Load Selected Sample to Selected Slot", invoke = function() start(false) if app then app:load_selected_sample_to_selected_slot() end end}
renoise.tool():add_menu_entry{name="Sample Navigator:Sononymph:Load Selected Sample from Sononym (Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(true) end end}
renoise.tool():add_menu_entry{name="Sample Navigator:Sononymph:Load Selected Sample from Sononym (No Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(false) end end}

renoise.tool():add_menu_entry{name="Main Menu:Tools:Sononymph:Open Sononymph Dialog...", invoke = function() start(true) end}
renoise.tool():add_menu_entry{name="--Main Menu:Tools:Sononymph:Toggle Sononym Auto-Transfer", invoke = function() start(false) if app then app:toggle_live_transfer() end end}
renoise.tool():add_menu_entry{name="Main Menu:Tools:Sononymph:Search Selected Sample in Sononym", invoke = search_selected_sample}
renoise.tool():add_menu_entry{name="Main Menu:Tools:Sononymph:Load Selected Sample from Sononym (Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(true) end end}
renoise.tool():add_menu_entry{name="Main Menu:Tools:Sononymph:Load Selected Sample from Sononym (No Prompt)", invoke = function() start(false) if app then app:load_selected_sample_from_sononym(false) end end}

-- Random sample menu entry (COMMENTED OUT - flip_a_coin function not yet supported by Sononym)
--[[
renoise.tool():add_menu_entry{
  name = "Main Menu:Tools:Sononymph:Random Sample",
  invoke = function()
    start(false) -- Initialize app but don't show dialog
    if app then
      -- Use the original flip_a_coin function for actual random selection
      flip_a_coin(app.prefs.path_to_config.value)
    end
  end
}
--]]

-- Load selected sample from Sononym menu entry

-- Random sample keybinding (COMMENTED OUT - flip_a_coin function doesn't work properly)
--[[
renoise.tool():add_keybinding{
  name = "Global:Sononymph:Random Sample [Trigger]", 
  invoke = function()
    start(false) -- Initialize app but don't show dialog
    if app then
      -- Use the original flip_a_coin function for actual random selection
      flip_a_coin(app.prefs.path_to_config.value)
    end
  end
}
--]]

---------------------------------------------------------------------------------------------------
-- tool menu entries
function register_tool_menu()
  local str_name = "Main Menu:Tools:Sononymph:Sononymph..."
  local str_name_active = "Main Menu:Tools:Sononymph:Sononymph (active)..."

  if renoise.tool():has_menu_entry(str_name) then
    renoise.tool():remove_menu_entry(str_name)
  elseif renoise.tool():has_menu_entry(str_name_active) then
    renoise.tool():remove_menu_entry(str_name_active)
  end
  renoise.tool():add_menu_entry{
    name = (app and app.monitor_active) and str_name_active or str_name,
    invoke = function() start(true) end}
end

register_tool_menu()    
---------------------------------------------------------------------------------------------------
-- notifications
---------------------------------------------------------------------------------------------------
renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("main app_new_document_observable fired...")
  start(prefs.autostart.value) end)


  _AUTO_RELOAD_DEBUG = true

  

  
  
