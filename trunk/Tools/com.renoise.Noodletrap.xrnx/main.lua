--[[============================================================================
main.lua
============================================================================]]--

-- includes

require "classes/NTrap"
require "classes/NTrapUI"
require "classes/NTrapPrefs"
require "classes/ProcessSlicer"

--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

TRACE = function(...)
  print(...)
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

ntrap = NTrap()
ntrap:retrieve_settings(ntrap_preferences)

-- workaround for http://goo.gl/UnSDnw
local waiting_to_show_dialog = true


local function show_dialog()
  if ntrap and ntrap._settings.autorun_enabled.value then
    ntrap:show_dialog()
  end
end


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
  if (waiting_to_show_dialog) then
    waiting_to_show_dialog = false
    show_dialog()
  end
  if (ntrap) then
    ntrap:_on_idle()
  end

end)

renoise.tool().app_release_document_observable:add_notifier(function()
  TRACE("main:app_release_document_observable fired...")
  if (ntrap) then
    ntrap:_detach_from_song()
  end

end)

renoise.tool().app_new_document_observable:add_notifier(function()
  TRACE("main:app_new_document_observable fired...")
  if (ntrap) then
    ntrap:_attach_to_song(true)
  end

end)


