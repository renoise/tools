--[[===========================================================================
Note-shuffle.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 2,
      properties = {
          max = 255,
          min = 1,
          display_as = "hex",
          zero_based = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      name = "num_steps",
      value = 3,
      properties = {
          min = 1,
          display_as = "integer",
          max = 32,
      },
      description = "Specify the number of steps in the sequence",
  },
  {
      name = "volume",
      value = 128,
      properties = {
          max = 128,
          display_as = "hex",
          min = 0,
      },
      description = "Specify the general volume level",
  },
  {
      name = "shuffle",
      value = 0.22,
      properties = {
          max = 1,
          min = 0,
      },
      description = "Control the amount of shuffle",
  },
},
presets = {
  {
      instr_idx = 2,
      shuffle = 0.22,
      volume = 128,
      name = "!#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ",
      num_steps = 3,
  },
  {
      instr_idx = 2,
      shuffle = 0.6895652173913,
      volume = 128,
      name = "",
      num_steps = 5,
  },
},
data = {
},
options = {
 color = 0x9ED68C,
},
callback = [[
-------------------------------------------------------------------------------
-- Notes & Shuffle
-- Control the amount of 'shuffle' (delay on every second note),
-- with a semi-complex note-sequence based on 'num_steps'
-------------------------------------------------------------------------------

local produce_note = (xinc%2==0) and true or false
if not produce_note then
  xline.note_columns[1] = {}
else
  local arp_index = (xinc)%args.num_steps
  xline.note_columns[1] = 
  {
    note_value = arp_index + (arp_index%2 == 1 and 36 or 24),
    instrument_value = args.instr_idx,
    volume_value = args.volume,
    delay_value = (xinc%4 == 0) and math.floor(255*args.shuffle) or 0,
  }
end  
  
  



]],
}