--[[============================================================================
Args-Polling.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 1,
      properties = {
          min = 1,
          --quant = 1,
          max = 255,
          zero_based = true,
          display_as = "hex",
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      poll = "rns.selected_note_column_index",
      name = "note_col_idx",
      value = 1,
      properties = {
          min = 0,
          display_as = "integer",
          max = 12,
      },
      description = "Tracking the selected note-column via polling",
  },
},
presets = {
},
data = {
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- Polling (non-observable) properties in Renoise 
-- In this example, we are polling the note-column index...open the model
-- definition (click the 'magnifying glass' in the models menu) to see how  
-- polling is specified in the .lua file
-------------------------------------------------------------------------------

xline.note_columns = EMPTY_NOTE_COLUMNS
xline.note_columns[args.note_col_idx] = {
  note_value = math.random(36,60),
  instrument_value = args.instr_idx,
}  

-- In the example 'API Binding.lua', it was demonstrated how you can 
-- attach arguments to observable properties in the Renoise API via binding. 
-- But what if the value isn't observable? The answer is to 'poll' the value. 
-- This basically works the same as bind, but is implemented in a slightly 
-- different way: instead of recieving notifications when the value has 
-- changed, we are instead polling the value ourselves, updating the argument 
-- when the source has changed. 

]],
}