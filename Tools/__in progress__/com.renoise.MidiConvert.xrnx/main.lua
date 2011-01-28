
require "toolbox"
require "ProcessSlicer"
require "Midi"
require "import"
require "export"

--------------------------------------------------------------------------------
-- Export to Midi
--------------------------------------------------------------------------------

function export()
  export_procedure()
end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:__Midi Export (WIP...)",
  invoke = export
}

