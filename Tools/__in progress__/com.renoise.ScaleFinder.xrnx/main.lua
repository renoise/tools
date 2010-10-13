--[[============================================================================
main.lua
============================================================================]]--
require 'scale'

local scale_root = 4
local scale_type = 1
local scale_pattern

local vb = renoise.ViewBuilder()
local sdisplay = vb:text{ width = 200, font = 'bold' }
local chord_boxes = {
  vb:column { style = 'panel', vb:text{ font = 'bold', text = 'i   tonic' }},
  vb:column { style = 'panel', vb:text{ font = 'bold', text = 'ii  supertonic' }},
  vb:column { style = 'panel', vb:text{ font = 'bold', text = 'iii mediant' }},
  vb:column { style = 'panel', vb:text{ font = 'bold', text = 'IV  subdominant' }},
  vb:column { style = 'panel', vb:text{ font = 'bold', text = 'V   dominant' }},
  vb:column { style = 'panel', vb:text{ font = 'bold', text = 'vi  submediant' }},
  vb:column { style = 'panel', vb:text{ font = 'bold', text = 'vii subtonic' }}
}

function update()
  print(scale_root .. ' - ' .. scale_type)
  scale_pattern = get_scale(scale_root, scale_type)
  local res = ''
  local sn = 0
  for i = 0, 11 do
    local n = ((scale_root + i - 1) % 12) + 1
    if scale_pattern[n] then
      sn = sn + 1
      if res ~= '' then res = res .. ', ' end
      res = res .. notes[n]
      
      for k, c in ipairs(chords) do
        if is_valid(n, k, scale_pattern) then
          chord_boxes[sn]:add_child(vb:button {
             width = 100,
             text = notes[n] .. c['code'] 
          })
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
  vb:row {
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
  vb:row {
    chord_boxes[1], 
    chord_boxes[2], 
    chord_boxes[3], 
    chord_boxes[4], 
    chord_boxes[5], 
    chord_boxes[6], 
    chord_boxes[7]
  }
}
update()
-- renoise.app():show_custom_prompt('Scale finder', dialog, {'OK'}) 
