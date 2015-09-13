--[[============================================================================
Undefined.lua
============================================================================]]--

return {
arguments = {
  {
      name = "undefined",
      value = 1,
      properties = {
          items = {
              "CLEAR",
              "KEEP",
          },
      },
      description = "Specify how xStream should treat undefined content",
  },
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
      value = 4.68,
      properties = {
          max = 12,
          min = 0,
      },
      description = "Tracking the selected note-column",
  },
  {
      name = "volume",
      value = 28.16,
      properties = {
          max = 128,
          min = 0,
      },
      description = "Specify the general volume level",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- DEFINED vs. UNDEFINED - understanding how output works
-------------------------------------------------------------------------------

-- TODO rewrite to demonstrate expanding (sub-)columns

-- xStream lets you distinguish between 'defined' and 'undefined' content. 
-- We can demonstrate this by writing a stream of notes into a single
-- note column, and then decide what to do about the other, undefined ones.
-- Try to navigate from note column to note column while switching between 
-- CLEAR and KEEP modes. This should make it obvious how UNDEFINED can be 
-- used for controlling the output 

-- First, we define a note column that output random notes
local note_col = {
  note_value = math.random(36,60),
  instrument_value = args.instr_idx, 
}

-- We then define a line with 12 empty note columns, like this:
line = {
  note_columns = {
    {},{},{},{},
    {},{},{},{},
    {},{},{},{},
  }
}

-- But - isn't it obvious that columns are undefined, until created? 
-- Well, it has to do with the way lua works - any ordered list (such as 
-- our note_columns) can't really contain undefined entries ('nil' values). 
-- This: {"one","two",nil,"three"} will become {"one","two","three"} -
-- undefined entries are simply removed. 

-- Having created all 12-note-columns, we can add our content 
xline.note_columns[args.note_col_idx] = note_col

-- Note: the argument 'note_col_idx' is polling the active note column - 
-- see ArgsPolling.lua for more information on how this works.

-- As a final step, we enable the property 'expand_columns'. This ensures
-- that columns are automatically shown as content is written there... 
-- TODO configure this as a model property
xstream.expand_columns = true


]],
}