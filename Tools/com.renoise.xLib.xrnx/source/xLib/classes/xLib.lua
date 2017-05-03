--[[============================================================================
xLib
============================================================================]]--

--[[--

Global constants and static methods for xLib
.
#


]]

--==============================================================================

class 'xLib'

xLib.COLOR_ENABLED = {0xD0,0xD8,0xD4}
xLib.COLOR_DISABLED = {0x00,0x00,0x00}

--------------------------------------------------------------------------------
-- [Static] Detect if we have a renoise song: in rare cases it can briefly 
-- go missing (e.g. while loading a song or creating a new document...)

function xLib.is_song_available()

  local pass,err = pcall(function()
    rns.selected_instrument_index = rns.selected_instrument_index
  end)
  if not pass then
    return false
  end

  return true

end

