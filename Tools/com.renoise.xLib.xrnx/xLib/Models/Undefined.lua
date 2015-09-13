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
      value = 1,
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
-- Defined vs. undefined 
-------------------------------------------------------------------------------

-- When a callback is running, you receive a full line from the pattern,
-- completely populated with whatever notes, effect commands that the song
-- contains. In other words, every line is fully defined. 

-- But you can choose to 'undefine' any aspect of a line. You do this by
-- assigning a line property (note_value, note_string, etc.) to 'nil'. 
-- Then, the flag in xStream called 'clear_undefined' will decide whether
-- to clear the content or simply skip it. 

-- OK, let's study a couple of practical example. First of all, 
-- consider the following examples: 

xline.columns[1].note_value = nil
xline.columns[1] = {
  note_value = nil
}

-- They should be the same, right? _Wrong_ - trick question, sorry :-) 
-- The first example will only set the note_value as undefined, but leave
-- the remaining data intact (remember, it was fully populated to begin with).
-- The second example will set the entire note column as undefined, and then 
-- (a bit meaningless, really...) set the note_value as undefined too. 

-- Here is another example - no tricks this time 

-- Define everything as empty (clear everything!!)
xline = EMPTY_LINE

-- Or define our note columns as empty
xline = {
  note_columns = EMPTY_NOTE_COLUMNS
}

-- Or, define note + effect columns as empty
xline = {
  note_columns = EMPTY_NOTE_COLUMNS,
  effect_columns = EMPTY_EFFECT_COLUMNS,
}

-- These "EMPTY_XXX" constants are just a handy way to avoid writing 
-- something like {{},{},{},{},{},{},{},{}} to define an empty array of
-- effect columns. 

-- But - why would you want to do that in the first place? 
-- Well, it has to do with the way lua works - any ordered list (such as 
-- our note_columns) can't really contain undefined entries ('nil' values). 
-- This: {"one","two",nil,"three"} will become {"one","two","three"} -
-- undefined entries are simply removed. 

-- So really, the deal with 'undefined' content is that you can use it 
-- to erase, ignore existing data - without having to go through the tedious 
-- task of defining each and every column as empty! 

-- Tip: enable the following statement to see the current structure
-- of the xline being printed to the Renoise scripting console:
-- rprint(xline)



]],
}