--[[============================================================================
main.lua
============================================================================]]--

-- variables --------------------------

local ntrap = nil
local ntrap_preferences = nil
local waiting_to_show_dialog = true

rns = nil

--_trace_filters = {".*"}
_trace_filters = nil

-- includes ---------------------------

_clibroot = "classes/cLib/classes/"
require (_clibroot.."cDebug")
require (_clibroot.."cProcessSlicer")

_xlibroot = "classes/xLib/classes/"
require (_xlibroot.."xPhraseManager")
require (_xlibroot.."xNoteColumn")

require "classes/NTrapEvent"
require "classes/NTrap"
require "classes/NTrapPrefs"
require "classes/NTrapUI"

--------------------------------------------------------------------------------
-- debug
--------------------------------------------------------------------------------

--[[
TRACE = function(...)
  if ntrap then
    ntrap:log_string(...)
  else
    print(...)
  end
end

LOG = function(...)
  if ntrap then
    ntrap:log_string(...)
  else
    print(...)
  end
end
]]

--------------------------------------------------------------------------------
-- initialize
--------------------------------------------------------------------------------

ntrap_preferences = NTrapPrefs()
renoise.tool().preferences = ntrap_preferences
ntrap = NTrap(ntrap_preferences)

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

  rns = renoise.song()

  if ntrap:is_running() then
    ntrap:attach_to_song(true)
  end

end)


