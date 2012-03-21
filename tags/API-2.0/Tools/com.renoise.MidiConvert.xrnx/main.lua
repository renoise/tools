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
  local base_types = {
    ["nil"]=true, ["boolean"]=true, ["number"]=true,
    ["string"]=true, ["thread"]=true, ["table"]=true
  }
  if not base_types[type(msg)] then oprint(msg)
  elseif type(msg) == 'table' then rprint(msg)
  else print(msg) end
end

-- Check timing model
function current_song_format()
  if renoise.song().transport.timing_model ~= renoise.Transport.TIMING_MODEL_LPB then
    renoise.app():show_error("Error: This script will not run on old XRNS " ..
    "files with Tick Speed. Upgrade your song in the 'Songs Settings' tab.")
    return false
  end
  return true
end


--------------------------------------------------------------------------------
-- Export
--------------------------------------------------------------------------------

function export(plan)
  if not current_song_format() then return end
  export_procedure(plan)
end


--------------------------------------------------------------------------------
-- Menu Registration, Key Bindings
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:File:Export Song to MIDI...",
  invoke = export
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Selection:Export to MIDI...",
  invoke = function() export('selection') end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Play:Export Selection to MIDI",
  invoke = function(repeated) export('selection') end
}
