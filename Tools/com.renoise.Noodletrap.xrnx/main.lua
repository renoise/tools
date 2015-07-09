--[[============================================================================
main.lua
============================================================================]]--

-- includes

require "classes/NTrapEvent"
require "classes/NTrap"
require "classes/NTrapPrefs"
require "classes/NTrapUI"
require "classes/ProcessSlicer"

--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

TRACE = function(...)
  --print(...)
end

LOG = function(...)
  if ntrap then
    ntrap:log_string(...)
  else
    print(...)
  end
end


--------------------------------------------------------------------------------
-- main
--------------------------------------------------------------------------------

local ntrap_preferences = NTrapPrefs()
renoise.tool().preferences = ntrap_preferences

ntrap = NTrap(ntrap_preferences)

-- workaround for http://goo.gl/UnSDnw
local waiting_to_show_dialog = true

--------------------------------------------------------------------------------
-- menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Noodletrap",
  invoke = function()
    if ntrap then
      ntrap:show_dialog()
    end
  end  
}

--------------------------------------------------------------------------------
-- keybindings
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Global:Noodletrap:Show Dialog...",
  invoke = function(repeated) 
    if (not repeated) then 
      if ntrap then
        ntrap:show_dialog()
      end
    end
  end
}

--------------------------------------------------------------------------------
-- notifications
--------------------------------------------------------------------------------

renoise.tool().app_idle_observable:add_notifier(function()
  --TRACE("main:app_idle_observable fired...")
  if ntrap 
    and waiting_to_show_dialog 
    and ntrap._settings.autorun_enabled.value 
  then
    waiting_to_show_dialog = false
    ntrap:show_dialog()
  end
  if ntrap:is_running() then
    ntrap:_on_idle()
  end

end)

renoise.tool().app_release_document_observable:add_notifier(function()
  TRACE("main:app_release_document_observable fired...")
  if ntrap:is_running() then
    ntrap:detach_from_song()
  end

end)

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("main:app_new_document_observable fired...")
  if ntrap:is_running() then
    ntrap:attach_to_song(true)
  end

end)


