--[[============================================================================
main.lua
============================================================================]]--

local dbug_mode = false

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
  if dbug_mode == true then print(msg) end
end


function check_song_version()
  local ok = true; -- TODO: An actual check
  if not ok then
    renoise.app():show_error("Error: This script will not run on old XRNS " ..
    "files with Tick Speed. Upgrade your song in the 'Songs Settings' tab.")
  end
  return ok
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

function export()
  if not check_song_version() then return end
  export_procedure()
end

--------------------------------------------------------------------------------
-- Menu Registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:MIDI Export...",
  invoke = export
}
