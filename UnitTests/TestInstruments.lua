--[[--------------------------------------------------------------------------
TestInstruments.lua
--------------------------------------------------------------------------]]--

do
  
  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local song = renoise.song()
  
  local selected_instrument = song.instruments[
    song.selected_instrument_index]
  
  
  
  ----------------------------------------------------------------------------
  -- insert/delete/swap
  
  local new_instr = song:insert_instrument_at(#song.instruments + 1)
  new_instr.name = "New Instrument!"
  
  song.selected_instrument_index = #song.instruments
  assert(song.selected_instrument.name == "New Instrument!")
  
  song:insert_instrument_at(#song.instruments + 1)
  song:delete_instrument_at(#song.instruments)
  
  assert_error(function()
    song:insert_instrument_at(#song.instruments + 2)
  end)
  
  assert_error(function()
    song:insert_instrument_at(0)
  end)
  
  song:insert_instrument_at(1)
  song:delete_instrument_at(1)
  
  song.instruments[1].name = "1"
  song.instruments[2].name = "2"
  song:swap_instruments_at(1, 2)
  
  assert(song.instruments[1].name == "2")
  assert(song.instruments[2].name == "1")
  
  song:swap_instruments_at(1, 2)
  assert(song.instruments[1].name == "1")
  assert(song.instruments[2].name == "2")
  
  song:delete_instrument_at(#song.instruments)

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
