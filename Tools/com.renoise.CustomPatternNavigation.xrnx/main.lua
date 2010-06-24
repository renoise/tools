-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool registration
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Note Router",
  invoke = function() 
     routing_dialog()
  end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Note Router",
  invoke = function() routing_dialog() end
}


-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- main content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
require "mididevice"
midi_notes = {}
note_table = {"C-", "C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"}
-------------------------------------------------------------------------------

function routing_dialog()
  local inputs = renoise.Midi.available_input_devices()

  build_note_table()
    
  if not table.is_empty(inputs) then
    local device_name = inputs[1]
  
    local midi_dumper = MidiDumper(device_name)
    midi_dumper:start()
  
    -- will dump till midi_dumper:stop() is called or the MidiDumber object 
    -- is garbage collected ...
  end

end

function process_messages(message)
  local song = renoise.song()
  local pattern = song.patterns[song.selected_pattern_index]
  local line = song.selected_line_index
  local instrument = song.selected_instrument_index -1

  if message[1] == 0x90 then
    if message[3] ~= 0 then
      print (midi_notes[tonumber(message[2])+1])
      local cur_pos = song.selected_line_index
      local cur_note = message[3] + 1
      local cur_note_string = midi_notes[tonumber(message[2])+1]
      for t = 1, 12 do
        if string.sub(cur_note_string,1,2) == note_table[t] then
          local visible_note_columns = song.tracks[t].visible_note_columns


          pattern.tracks[t].lines[line].note_columns[1].note_string = midi_notes[(tonumber(message[2])+1)]
          
          pattern.tracks[t].lines[line].note_columns[1].instrument_value = instrument
          pattern.tracks[t].lines[line].note_columns[1].volume_value = message[3]
          break
        end
      end
      
    else
      print (string.lower(midi_notes[tonumber(message[2])+1]))
--      print ("OFF")
    end
  end
end

function build_note_table()
  local current_midi_note = 0
  for octave = 0,9 do
    for notepos = 1,12 do
      current_midi_note = current_midi_note +1
      midi_notes[current_midi_note] = note_table[notepos]..tostring(octave)
      if current_midi_note == 128 then
        break
      end
    end
    if current_midi_note == 128 then
      break
    end
  end

end
