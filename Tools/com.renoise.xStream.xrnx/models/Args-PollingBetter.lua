--[[============================================================================
API - PollingBetter.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 3,
      properties = {
          min = 1,
          quant = 1,
          max = 255,
          zero_based = true,
          display_as_hex = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      poll = "rns.selected_note_column_index",
      name = "note_col_idx",
      value = 2,
      properties = {
          min = 0,
          quant = 1,
          max = 12,
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
callback = [[
-------------------------------------------------------------------------------
-- Using polling for non-observable values
-- (previous example, but with note-offs)
-------------------------------------------------------------------------------

-- Let's improve on the API Polling example by adding note-offs.
-- Since the output is written to an arbitrary column, we need to manage
-- our OFF notes accordingly. 

-- A particular quirk is that, in order to have a truly reliable OFF note
-- we need to write it to the pattern _twice_. This is so, since the 
-- playback engine in Renoise could have progressed to the next line in
-- the time it takes to process the script (engine is a different thread). 
-- This makes the script a little more complex, but reliable. 

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

-- We then call this function twice, first time to insert the second 
-- note-off and second time to insert the first one. 

check_columns(data.columns2)
check_columns(data.columns,data.columns2)

-- Finally, we can output the note:

xline.note_columns[args.note_col_idx] = {
  note_value = math.random(36,60),
  instrument_value = args.instr_idx,
}  



















]],
}