--[[============================================================================
main.lua
============================================================================]]--
require 'scale'

local scale_root = 4
local scale_type = 1
local scale_pattern

local vb = renoise.ViewBuilder()
local sdisplay = vb:text{ width = 190, font = 'bold' }
local cdisplay = vb:text{ width = 160, font = 'bold', text = 'Chord  [none selected]' }

local cb_headers = { 'I', 'ii', 'iii', 'I', 'V', 'vi', 'vii' }

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

ccont = {}

function insert_note(note, col)
  renoise.song().selected_line.note_columns[col + 1].note_value = note - 4 + 
    renoise.song().transport.octave * 12
end

function clear_cb()
  for i, v in ipairs(ccont) do
    chord_boxes[i]:remove_child(v)
    chord_boxes[i]:resize()
  end
end

function add_chord(root, chord)
  cdisplay.text = 'Chord: ' .. notes[root] .. chord["code"]
  local cpattern = get_scale(root, chord)
  local res = ''
  local note_offset = 0
  for i = 0, 11 do
    local n = ((root + i - 1) % 12) + 1
    if cpattern[n] then
      -- Form the string for chord note listing
      if res ~= '' then 
        res = res .. ', '
      else
        res = 'Chord ' ..  notes[root] .. chord["code"] .. ': '
      end
      res = res .. notes[n]
      
      -- Insert note
      insert_note(root + i, note_offset)
      note_offset = note_offset + 1
    end
  end
  cdisplay.text = res
end

function update()
  clear_cb()
  scale_pattern = get_scale(scale_root, scales[scale_type])
  local res = ''
  local sn = 0
  for i = 0, 11 do
    local n = ((scale_root + i - 1) % 12) + 1
    if scale_pattern[n] then
      -- Form the string for scale note listing
      if res ~= '' then 
        res = res .. ', '
      else
        res = 'Scale: '
      end
      res = res .. notes[n]
      
      -- Build the chord views
      sn = sn + 1
      for k, c in ipairs(chords) do
        if is_valid(n, k, scale_pattern) then
          local cb = vb:button {
            width = 60,
            height = 30,
            text = notes[n] .. c['code'],
            notifier = function()
              add_chord(n, c)
            end
          }
          chord_boxes[sn]:add_child(cb)
          ccont[sn] = cb
        end
      end 
    end
  end
  sdisplay.text = res
end

snames = { }
for key, scale in ipairs(scales) do
  table.insert(snames,scale['name'])
end

dialog = vb:column {
  
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
      sdisplay
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
        chord_boxes[7]
      }
    }
  }
}
update()
--renoise.app():show_custom_dialog('Scale finder', dialog) 
