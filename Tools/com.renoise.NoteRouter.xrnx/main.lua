-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool registration
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Note Mapper...",
  invoke = function() 
     initialize()
  end
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Note Mapper...",
  invoke = function() initialize() end
}


-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- main content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
require "mididevice"
require "globals"
require "gui"

TYPE_TRACK = 1
TYPE_MASTER = 2
TYPE_SEND = 3

midi_notes = {}
note_table = {"C-", "C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-"}

-------------------------------------------------------------------------------

function initialize()
  local inputs = renoise.Midi.available_input_devices()

  build_note_table()
  main_dialog()    
  get_track_index()
  get_device_index()

end


function process_messages(message)
  
  if message[1] >= 0x80 and message[1] <= 0x9F then
    if message[3] ~= 0 and message[1] >= 90 then

      if nr_debug then
        print (message[2])
        print (midi_notes[tonumber(message[2])+1])
      end 

      if record_mode then
        if record_destination == PATTERN_EDITOR then
          map_to_pattern_editor(message)
        else
          map_to_track(message)
        end
       
      end
    else
      --Need note-off support? then do you stuff here....
      if nr_debug then
        print ("OFF "..string.lower(midi_notes[tonumber(message[2])+1]))
      end

    end

  end

end


function map_to_track(message)
  local song = renoise.song()

--Link the internal Renoise octave settings to the General MIDI note table specifications
--Simply take care the key you would hit in Renoise generates the same note-value as in this script.
  local current_octave = song.transport.octave  
  local octave_derivate = (current_octave - 4) * 12
  local midi_note = (tonumber(message[2])+1)+octave_derivate

  if nr_debug then
    print ("current midi-note number:"..midi_note)
  end

  if midi_note > 0 and midi_note < 121 then
    note_to_track[note_map_dialog_vb.views.trackindex.value] = midi_notes[midi_note]
    note_map_dialog_vb.views.note_field.text = note_to_track[note_map_dialog_vb.views.trackindex.value]
  end
end


function map_to_pattern_editor(message)
  local song = renoise.song()
  local pattern = song.patterns[song.selected_pattern_index]
  local line = song.selected_line_index
  local instrument = song.selected_instrument_index -1
--Link the internal Renoise octave settings to the General MIDI note table specifications
--Simply take care the key you would hit in Renoise generates the same note-value as in this script.
  local current_octave = song.transport.octave  
  local octave_derivate = (current_octave - 4) * 12


  for t = 1, #note_to_track do

      if song.tracks[t].type == TYPE_TRACK then

        local visible_note_columns = song.tracks[t].visible_note_columns
        local midi_note = (tonumber(message[2])+1)+octave_derivate

        if midi_notes[midi_note] == note_to_track[t] then
          if nr_debug then
            print ("current midi-note number:"..midi_note)
          end

          if midi_note > 0 and midi_note < 121 then
            pattern.tracks[t].lines[line].note_columns[1].note_string = midi_notes[midi_note]
          
            pattern.tracks[t].lines[line].note_columns[1].instrument_value = instrument
            pattern.tracks[t].lines[line].note_columns[1].volume_value = message[3]
            break
          end
        end

      end

  end

end


function midi_engine(MODE)
  local inputs = renoise.Midi.available_input_devices()

  if not table.is_empty(inputs) then
    local device_index = note_map_dialog_vb.views.device_list.value
    local device_name = note_map_dialog_vb.views.device_list.items[device_index]

    if #inputs ~= device_index then
     --Something changed in the midi-device list meanwhile? (OSX / Linux)
      note_map_dialog_vb.views.device_list.items = inputs
      device_index = note_map_dialog_vb.views.device_list.value
      device_name = note_map_dialog_vb.views.device_list.items[device_index]
    end
  
    local midi_dumper = MidiDumper(device_name)

    if MODE == 'start' then
      midi_dumper:start()
    else
      midi_dumper:stop()
    end
  
    -- will dump till midi_dumper:stop() is called or the MidiDumber object 
    -- is garbage collected ...
  end

  if MODE=='start' then
    --Take care edit mode is always being turned off when learn mode
    --gets enabled. If no midi device detected, this still has to be 
    --triggered for PC keyboard mode!
    renoise.song().transport.edit_mode = false
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


function get_device_index()
  local inputs = renoise.Midi.available_input_devices()

  if not table.is_empty(inputs) then
    note_map_dialog_vb.views.device_list.items = inputs
  else
    note_map_dialog_vb.views.device_list.items = {"None"}
  end

end


function get_track_index()
  local song = renoise.song()
  
  for t = 1, #song.tracks do
    if renoise.song().tracks[t].type == TYPE_TRACK then
      tracks[t] = song.tracks[t].name
      note_to_track[t] = 'None'
    end
  end

  if #tracks ~= nil then
    note_map_dialog_vb.views.trackindex.items = tracks
  end

end


-------------------------------------------------------------------------------
---                         Keyboard control handler                       ----
-------------------------------------------------------------------------------
function key_handler(dialog, mod, key)
  local message = {0x90,0,0x80}

  if (mod == "" and key == "numpad /") then

    if renoise.song().transport.octave >0 then
      renoise.song().transport.octave = renoise.song().transport.octave - 1
    end

  end

  if (mod == "" and key == "numpad *") then

    if renoise.song().transport.octave < 8 then
      renoise.song().transport.octave = renoise.song().transport.octave +1
    end

  end

  local cur_octave = renoise.song().transport.octave    
  local fnote = (cur_octave * 12)

-- We have to do some special trickery because of the octave_derivate
-- above in the midi message key translation:
  if cur_octave > 4 then
    fnote = fnote - (12* (cur_octave-4))
  else 

    if cur_octave < 4 then
      fnote = fnote + (12* (4-cur_octave))
    end

  end

--Now we translate our pc keyboard input to midi messages and send those to 
--our midi message processor, clever huh?:

  if mod == "" then
    local found = false
    for ckey = 1, 12 do

      if key == low_key[ckey] or key == high_key[ckey] or key == mid_key[ckey] then
        fnote = (ckey -1) + fnote
        found = true
      end
      if key == high_key[ckey] or key == mid_key[ckey] then
        fnote = fnote + 12
        break
      end

    end

    if found then
      message[2] = fnote
      process_messages(message)
    end

  end

  if (mod == "" and key == "esc") then
      dialog:close()
  end

end 




