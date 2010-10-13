--[[============================================================================
main.lua
============================================================================]]--
require 'scale'

local scale_root = 4
local scale_type = 1
local scale_pattern

local vb = renoise.ViewBuilder()
local sdisplay = vb:text{ width = 200, font = 'bold' }

function update()
  print(scale_root .. ' - ' .. scale_type)
  scale_pattern = get_scale(scale_root, scale_type)
  local res = ''
  for i = 0, 11 do
    local n = ((scale_root + i - 1) % 12) + 1
    if scale_pattern[n] then
      if res ~= '' then res = res .. ', ' end
      print(n)
      res = res .. notes[n]
    end
  end
  sdisplay.text = res
end

snames = { }
for key, scale in ipairs(scales) do
  table.insert(snames,scale['name'])
end
 
dialog = vb:row {
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
}

update()
-- renoise.app():show_custom_prompt('Scale finder', dialog, {'OK'}) 
