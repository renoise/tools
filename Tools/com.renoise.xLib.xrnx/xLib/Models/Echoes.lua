--[[============================================================================
Echoes.lua
============================================================================]]--

return {
arguments = {
  {
      name = "num_echoes",
      value = 2,
      properties = {
          min = 1,
          quant = 1,
          max = 8,
      },
      description = "How many echoes to produce",
  },
},
data = {
  source_notes = {},
},
callback = [[
-------------------------------------------------------------------------------
-- Echoes
-------------------------------------------------------------------------------

-- Apply echoes to existing notes
-- will leave notes intact if the echo was to overwrite them


local note_col = xline.note_columns[1]

-- Check if we have a source note 
-- and add it to our look-up table 
if (note_col.note_value < 120) then
  table.insert(data.source_notes,{
    incr = xinc,
    note_col = note_col,
  })
elseif(note_col.note_string == "---") then
  -- Empty note-column, check for echoes
  --data.compute_delay_lines(xinc,data.source_notes,args.num_echoes)
  print("source_notes",#data.source_notes)

end




]],
}