--[[============================================================================
Args-PollingBetter.lua
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
          --quant = 1,
          max = 12,
          display_as = "integer",
      },
      description = "Tracking the selected note-column via polling",
  },
},
presets = {
},
data = {
  columns = {
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
  },
  columns2 = {
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
      false,
  },
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- Using polling for non-observable values
-- Let's improve on 'Args-Polling' by adding note-offs.
---------------------------------------------=========-------------------------

xline = {
  note_columns = EMPTY_NOTE_COLUMNS,
}

-- Save the current column index into our 'memory'

data.columns[args.note_col_idx] = true
data.columns2[args.note_col_idx] = true

-- Function which will write note-offs

local check_columns = function (t,t2)
  for k,v in ipairs(t) do
    if (v) and (k ~= args.note_col_idx) then
      if clear_undefined or (not clear_undefined and 
        xline.note_columns[k])
      then
        xline.note_columns[k] = {
          note_string = "OFF",
        }
      end
      t[k] = false
      if t2 then
        t2[k] = true
      end
    end
  end
end

-- We then call this function twice, to insert 1st and 2nd OFF. Why two times? 
-- Has to do with the Renoise playback engine - it could have progressed to 
-- the next line in the time it takes for us to process the script. The result 
-- could be a hanging - even if rare, a definite possibility. 
-- Essentially, 'double OFFs' makes the script more complex, but also reliable
-- xStream TODO: xline scheduling - a better way to handle this 
-------------------------------------------------------------------------------
check_columns(data.columns2)
check_columns(data.columns,data.columns2)

-- Finally, we can output the note:

xline.note_columns[args.note_col_idx] = {
  note_value = math.random(36,60),
  instrument_value = args.instr_idx,
}  





]],
}