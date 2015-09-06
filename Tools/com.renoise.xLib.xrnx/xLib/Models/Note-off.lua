--[[============================================================================
Note-off.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 1,
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
      value = 1,
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
-- Since we can jump from column to column we need to keep track
-- of where we want to write our OFF notes. This example demonstrates
-- how you could add such 'memory' to the callback 

-- A particular quirk is that, in order to have a truly reliable OFF note
-- we need to write it to the pattern _twice_. This is so, since the 
-- sequencer engine in Renoise could have progressed to the next line in
-- the (very little) time it takes to process the script. This makes the
-- script a bit more complex, but the result should be reliable. 

-- Our data contains two tables: 'columns' and 'columns2'. 
-- Each one is a table with - surprise! - an entry for each note-column. 
-- In those tables, we _always_ save the current column index, like this:

data.columns[args.note_col_idx] = true
data.columns2[args.note_col_idx] = true

-- Next, we define a function which will write a note-off if any of the
-- non-selected columns are true (== previously active). 

local check_columns = function (t,t2)
  for k,v in ipairs(t) do
    if (v) and (k ~= args.note_col_idx) then
      line.note_columns[k] = {
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

line.note_columns[args.note_col_idx] = {
  --note_value = math.random(36,60),
  note_string = "C-4",
  instrument_value = args.instr_idx,
}  


]],
}