--[[============================================================================
Note-off.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 6,
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
      value = 4,
      properties = {
          min = 0,
          quant = 1,
          max = 12,
      },
      description = "Tracking the selected note-column via polling",
  },
},
data = {
  columns = {
      false,
      true,
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
      true,
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
-- FIXME why doesn't note_value work in this example??? 
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

-- First, we define two data tables: 'columns' and 'columns2'. 
-- Each table contains 12 entries, one for each note-column. 
-- In those tables, we _always_ save the current column index, like this:

data.columns[args.note_col_idx] = true
data.columns2[args.note_col_idx] = true

-- Next, we define a function which will write a note-off if any of the
-- non-selected columns are true (== previously active). 

local check_columns = function (t,t2)
  for k,v in ipairs(t) do
    if (v) and (k ~= args.note_col_idx) then
      xline.note_columns[k] = {
        note_string = "OFF",
      }
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

rprint(xline)





]],
}