--[[============================================================================
main.lua
============================================================================]]--

dbug_mode = false
coroutine_mode = true

require "toolbox"
require "ProcessSlicer"
require "Midi"
-- require "import"
require "export"


--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Debug print
function dbug(msg)
  if dbug_mode == false then return end
  if type(msg) == 'table' then rprint(msg)
  else print(msg) end
end


function current_song_format()
  local ok = true; -- TODO: An actual check
  if not ok then
    renoise.app():show_error("Error: This script will not run on old XRNS " ..
    "files with Tick Speed. Upgrade your song in the 'Songs Settings' tab.")
    ok = false
  end
  return ok
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

function export(plan)
  if not current_song_format() then return end
  export_procedure(plan)
end


--------------------------------------------------------------------------------
-- Menu Registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:File:Export Song to MIDI...",
  invoke = export
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Selection:Export to MIDI...",
  invoke = function() export('selection') end
}
