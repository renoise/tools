--[[============================================================================
main.lua

changes May 20th 2012 by vV:
-Changed transport preview for OSC preview
-Added preview button in create_dialog(), listens to preview_mode and sets
button collor using bool_button. Preview mode is on by default and doesn't
add notes to the track, if turned off, it will add notes to the track.

============================================================================]]--



require 'scale'

local scale_root = 4
local scale_type = 1
local scale_pattern
local ccont = {}

local vb = renoise.ViewBuilder()
local sdisplay = vb:text{ width = 190, font = 'bold' }
local cdisplay = vb:text{ width = 160, font = 'bold', text = 'Chord  [none selected]' }

local cb_headers = { 'I', 'ii', 'iii', 'IV', 'V', 'vi', 'vii', 'viii','ix','x','xi','xii' }
local chord_boxes = {}
for i = 1, 12 do
  chord_boxes[i] = vb:column { 
    style = 'panel', 
    vb:text{ 
      align = 'center',
      width = 60,
      font = 'bold', 
      text = cb_headers[i] 
    }
  }
end

local chord_reverse = false

osc_host = "localhost"
osc_port = 8000
osc_protocol = renoise.Socket.PROTOCOL_UDP
socket_timeout = 1000
client, client_error = nil

OscMessage = renoise.Osc.Message
OscBundle = renoise.Osc.Bundle

nr_debug = false

--------------------------------------------------------------------------------
function insert_note(note, col, insv)
  local message = {0x80,0,0}
  local note_string = tostring((note - 4 + renoise.song().transport.octave * 12)-48)
  
  -- Add note
  if tab_states.top == 1 then
    local key = {}
    key.note = note -4
    play_note({0x80,(note - 4 + renoise.song().transport.octave * 12),0x80})
    handle_note(key)
    key.note = note
    
  elseif tab_states.top == 2 then
    if tonumber(note_string) > 12 or tonumber(note_string) < -12 then
      note_string = '['..note_string..']'
    end
  
    if env_pitch_scheme == '' then
      env_pitch_scheme = note_string
      note_point_scheme = '0'
    else
      env_pitch_scheme = env_pitch_scheme .. ","..note_string
      note_point_scheme = note_point_scheme .. ", "..tostring(col*note_chord_spacing)
    end
  end
end

function clear_cb()
  for i, v in ipairs(ccont) do
    if v ~= nil then
      chord_boxes[i]:remove_child(v)
      chord_boxes[i]:resize()
      ccont[i] = nil
    end 
  end
end

--------------------------------------------------------------------------------
function add_chord(root, chord)
  cdisplay.text = 'Chord: ' .. get_note(root) .. chord["code"]
  local cpattern = chord["pattern"]
  local res = ''
  local note_offset = 0
  local current_instrument = renoise.song().selected_instrument_index
  local first_note = -1
  local note_pattern_start = 1
  local note_pattern_end = #cpattern

  if midi_record_mode then
    init_tables(ENV_NOTE_COLUMN)
    env_pitch_scheme = ''
    note_point_scheme = ''
  end
  
  if not chord_reverse then
    for n = 1, #cpattern do
      if cpattern:sub(n, n) == '1' then
        local note = root + n - 1;
        -- Form the string for chord note listing
        if res ~= '' then 
          res = res .. ', '
        else
          res = 'Chord ' ..  get_nname(root) .. chord["code"] .. ': '
        end
        res = res .. get_nname(note)
        if n == 1 then
          first_note = note
        end 
       
        -- Insert note
        insert_note(note, note_offset, current_instrument)
        note_offset = note_offset + 1
      end
    end
  else
    for n = #cpattern,1,-1 do
      if cpattern:sub(n, n) == '1' then
        local note = root + n - 1;
        -- Form the string for chord note listing
        if res ~= '' then 
          res = res .. ', '
        else
          res = 'Chord ' ..  get_nname(root) .. chord["code"] .. ': '
        end
        res = res .. get_nname(note)
        if n == 1 then
          first_note = note
        end 
       
        -- Insert note
        insert_note(note, note_offset, current_instrument)
        note_offset = note_offset + 1
      end
    end
  end
  
  if midi_record_mode then
    env_pitch_scheme = env_pitch_scheme..", 2222"
    note_point_scheme = note_point_scheme .. ", ".. tostring(note_offset*note_chord_spacing)

    ea_gui.views['auto_note_loop'].value = ARP_MODE_OFF

    prepare_note_tables(ENV_NOTE_COLUMN)
    
    if ea_gui.views['sync_pitch_column'].value > 0 then
      change_line_sync(ENV_NOTE_COLUMN,ea_gui.views['sync_pitch_column'].value)
    end
      if vol_pulse_mode ~= ARP_MODE_OFF then
        change_from_tool = true
          construct_envelope_pulse(ENV_VOL_COLUMN)
        change_from_tool = false      
      end
      if pan_pulse_mode ~= ARP_MODE_OFF then
        change_from_tool = true
          construct_envelope_pulse(ENV_PAN_COLUMN)
        change_from_tool = false      
      end
    note_loop_start = 0
    note_loop_end = note_offset*note_chord_spacing
    note_loop_type = ENV_LOOP_FORWARD
    note_freq_type = FREQ_TYPE_FREEFORM
    set_cursor_location()

  --  if env_auto_apply then
      change_from_tool = true
        configure_envelope_loop()
      change_from_tool = false
      if ea_gui.views['sync_pitch_column'].value > 0 then
        change_line_sync(ENV_NOTE_COLUMN,ea_gui.views['sync_pitch_column'].value)
      end
      set_pitch_table()
      if vol_pulse_mode ~= ARP_MODE_OFF then
        change_from_tool = true
          construct_envelope_pulse(ENV_VOL_COLUMN)
        change_from_tool = false      
      end
      if pan_pulse_mode ~= ARP_MODE_OFF then
        change_from_tool = true
          construct_envelope_pulse(ENV_PAN_COLUMN)
        change_from_tool = false      
      end
      if preset_version == "3.15" then
        apply_unattended_properties()        
      end
 --   end

  end
  
  play_note({0x80,(first_note - 4 + renoise.song().transport.octave * 12),0x80})
  cdisplay.text = res
end
--------------------------------------------------------------------------------
function update()
  clear_cb()
  scale_pattern = get_scale(scale_root, scales[scale_type])
  local res = ''
  local sn = 0
  local song = renoise.song()
  local track = song.selected_track_index
  local pattern  = song.selected_pattern_index
  local line = song.selected_line_index
  
  for n = scale_root, scale_root + 11 do
    if scale_pattern[get_note(n)] then
      -- Form the string for scale note listing
      if res ~= '' then 
        res = res .. ', '
      else
        res = 'Scale: '
      end
      res = res .. get_nname(n)
      
      -- Build the chord views
      sn = sn + 1
      local cc = vb:column {} -- Chord Container
      ccont[sn] = cc
      chord_boxes[sn]:add_child(cc)
      for k, c in ipairs(chords) do
        if is_valid(n, k, scale_pattern) then
          local cb = vb:button {
            width = 70,
            height = 30,
            text = get_nname(n) .. c['code'],
            midi_mapping = "Scale Finder (EA):Chord:"..get_nname(n) .. c['code'],
            pressed = function()
              add_chord(n, c)
            end,
            released = function()
              for n = 0, 120 do
                play_note({0x80,n,0})
              end
            end
          }
          cc:add_child(cb)
          if not renoise.tool():has_midi_mapping("Scale Finder (EA):Chord:"..get_nname(n) .. c['code']) then
            renoise.tool():add_midi_mapping{
              name = "Scale Finder (EA):Chord:"..get_nname(n) .. c['code'],
              invoke = function(message)
                if message:is_trigger() then
                    add_chord(n, c)
                else
                  for n = 0, 120 do
                    play_note({0x80,n,0})
                  end
                end
              end
            } 
          end
        end
      end
    end
  end
  sdisplay.text = res
end

--------------------------------------------------------------------------------
snames = { }
for key, scale in ipairs(scales) do
  table.insert(snames,scale['name'])
end
local dialog_view

function create_dialog ()
  dialog_view = vb:column {  
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    vb:column {
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      vb:row {
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
        width = 700,
        style = 'group',
        vb:text { text = 'Key:' },
        vb:popup { 
          items = notes, 
          value = scale_root,
          notifier = function (i) scale_root = i; update() end 
        },
        vb:text { text = ' Scale:' },
        vb:popup { 
          items = snames,  
          value = scale_type,
          notifier = function (i) scale_type = i; update() end  
        },
        sdisplay,
        vb:button{
          id = 'chord_reverse',
          text = "Reverse",
          tooltip = 'Reverse the note order of the chord',
          color = bool_button[chord_reverse],
          notifier = function()
            chord_reverse = not chord_reverse
            vb.views['chord_reverse'].color = bool_button[chord_reverse]
          end
        },
      },
      vb:column {
        style = 'group',
        margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        height = 200,
        cdisplay,
        vb:row{
          chord_boxes[1], 
          chord_boxes[2], 
          chord_boxes[3], 
          chord_boxes[4], 
          chord_boxes[5], 
          chord_boxes[6], 
          chord_boxes[7],
--          chord_boxes[8],
--          chord_boxes[9],
--          chord_boxes[10],
--          chord_boxes[11],
--          chord_boxes[12]
        }
      }
    }
  }
end

function handle_keys(d, k)
  --print(k.name)
  if k.name == 'esc' then
    row_frequency_size = renoise.song().transport.edit_step
    toggle_midi_record()
    top_tab_arming_toggle()
    set_cursor_location()
  else 
    return k
  end
end

--------------------------------------------------------------------------------
local dialog

function sf_display()
  update()
  connect_to_server()
  if dialog_view == nil then
    create_dialog()
  end
  
  if dialog == nil or not dialog.visible then
    dialog = renoise.app():show_custom_dialog('Scale finder (Epic Arpeggiator edition)', 
        dialog_view, handle_keys )
  end
end



--------------------------------------------------------------------------------
-- OSC client
--------------------------------------------------------------------------------

function connect_to_server()
  if client ~= nil then
    return 
  end

  client, client_error = renoise.Socket.create_client(osc_host, osc_port, osc_protocol)
  
  if client ~= nil then

    if client.is_open then

      if nr_debug then
        print("Server connected")
      end

    else

      if renoise.Midi.devices_changed_observable():has_notifier(get_device_index) then
        renoise.Midi.devices_changed_observable():remove_notifier(get_device_index)
      end
      
      if client_error then

        local err_msg = "Could not connect to server reason: ["..client_error..
                        "]\n\nPlease check your network connection and try again "
        local choice = renoise.app():show_prompt("Network error",err_msg,{'close'})

      end

    end

  else
    local cl_err = "Client connection-establishment failed."

    if client_error ~= nil then
      cl_err = client_error
    end

    local err_msg = "Could not connect to server reason: "..cl_err..
                    "\n\nPlease check your network connection and try again "
    local choice = renoise.app():show_prompt("Network error",err_msg,{'close'})
  end  
  
end
--------------------------------------------------------------------------------

function play_note(message)
  local song = renoise.song()
  local selected_instrument = processing_instrument -- renoise.song().selected_instrument_index
  local track  = renoise.song().selected_track_index -1
  local note_column = song.selected_note_column_index

  if renoise.song().transport.edit_mode == true then
    renoise.song().transport.edit_mode = false
  end
  
  if message[1] >= 0x80 and message[1] <= 0x9F then

    if message[3] ~= 0 and message[1] >= 90 then

      if nr_debug then
        print("note-ON:"..message[2].." velocity:"..message[3])
      end 

      local count = 0

      if client~= nil then

        if client.is_open then
          local o_message = nil
            
          o_message = OscMessage(
            "/renoise/trigger/note_on",{
            {tag="i",value=(selected_instrument-1)},
            {tag="i",value=track},
            {tag="i",value=message[2]},
            {tag="i",value=message[3]}
            }
          )
              
          if o_message ~= nil then
            client:send(o_message)
          end
        end
      end

    else
       
      if nr_debug then
        print("note OFF:"..message[2].." velocity:"..message[3])
      end 

      local count = 0

      if client~= nil then

        if client.is_open then
          local o_message = nil
            
          o_message = OscMessage(
            "/renoise/trigger/note_off",{
            {tag="i",value=(selected_instrument-1)},
            {tag="i",value=track},
            {tag="i",value=message[2]}
            }
          )

          if o_message ~= nil then
            client:send(o_message)
          end
        end
      end

      --Need note-off support? then do you stuff here....

    end

  end

end

