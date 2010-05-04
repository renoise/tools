--[[----------------------------------------------------------------------------
ExampleTool_PatternIter.lua
----------------------------------------------------------------------------]]--

-- manifest

-- (see ExampleTool.lua for a description of this header and tools in general)

manifest = {}

manifest.api_version = 0.2
manifest.author = "taktik [taktik@renoise.com]"
manifest.description = "Shows how to use pattern iterators " ..
  "with the scripting API"

manifest.actions = {}

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Pattern Iterators:Clear Whole Song",
  description = "Clears all pattern lines in the whole song.",
  invoke = function()
    local selected_columns_only = false

    invoke_line_iter(
      renoise.song().pattern_iterator:lines_in_song(),
      selected_columns_only)
  end
}

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Pattern Iterators:Clear Current Pattern",
  description = "Clears all pattern lines in the current pattern.",
  invoke = function()
    local pattern = renoise.song().selected_pattern_index
    local selected_columns_only = false

    invoke_line_iter(
      renoise.song().pattern_iterator:lines_in_pattern(pattern),
      selected_columns_only)
  end
}

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Pattern Iterators:Clear Current Track",
  description = "Clears all pattern lines in the current track.",
  invoke = function()
    local track = renoise.song().selected_track_index
    local selected_columns_only = false

    invoke_line_iter(
      renoise.song().pattern_iterator:lines_in_track(track),
      selected_columns_only)
  end
}

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Pattern Iterators:Clear Current Patterns Track",
  description = "Clears all pattern lines in the current patterns track.",
  invoke = function()
    local pattern = renoise.song().selected_pattern_index
    local track = renoise.song().selected_track_index
    local selected_columns_only = false

    invoke_line_iter(
      renoise.song().pattern_iterator:lines_in_pattern_track(pattern, track),
      selected_columns_only)
  end
}

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Pattern Iterators:Clear Selection in Current Pattern",
  description = "Clears all selected pattern lines in the current pattern.",
  invoke = function()
    local pattern = renoise.song().selected_pattern_index
    local selected_columns_only = true

    invoke_line_iter(
      renoise.song().pattern_iterator:lines_in_pattern(pattern),
      selected_columns_only)
  end
}

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Pattern Iterators:Clear Note Columns in Current Pattern",
  description = "Clears all note columns in the current pattern.",
  invoke = function()
    local pattern = renoise.song().selected_pattern_index
    local selected_columns_only = false

    invoke_note_column_iter(
      renoise.song().pattern_iterator:note_columns_in_pattern(pattern),
      selected_columns_only)
  end
}

manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Example Tools:Pattern Iterators:Clear Effect Columns in Current Track",
  description = "Clears all note columns in the current pattern.",
  invoke = function()
    local pattern = renoise.song().selected_track_index
    local selected_columns_only = false

    invoke_effect_column_iter(
      renoise.song().pattern_iterator:effect_columns_in_track(pattern),
      selected_columns_only)
  end
}


--------------------------------------------------------------------------------
-- content
--------------------------------------------------------------------------------

-- invoke_line_iter

function invoke_line_iter(iter, selected_columns_only)

  -- Note: this is a very silly example. The patterns, pattern.track or
  -- lines clear() is far more efficient than this way of clearing...
  --
  -- A more simple example without the magic invoke_line_iter() stuff:
  --
  --   local pattern_iterator = renoise.song().pattern_iterator
  --   
  --   local visible_patterns_only = true
  --   for pos, line in pattern_iterator:lines_in_song(visible_patterns_only) do
  --   -- do something with 'line' at the given 'pos' in the whole song...
  --   end
  --
  --   see renoise.PatternIterator in RenoiseAPI.txt for all available 
  --   iterators & more details...
  --
  -- Accessing a note column:
  --   note_column.note_value / note_string
  --   note_column.instrument_value / instrument_string
  --   note_column.volume_value / volume_string
  --   note_column.panning_value / panning_string
  --   note_column.delay_value / delay_string
  --
  -- Accessing an effect column:
  --   effect_column.number_value / number_string
  --   effect_column.amount_value / amount_string
  --
  -- XXX_value is the raw number, XXX_string, the value as you see it
  -- in the pattern editor. both properties have getters & setters, so simply
  -- use number or values where appropriated (transform vs. visualize)

  local start_time_secs = os.clock()

  for pos, line in iter do
    -- no need to look at completely empty lines in this example
    if not line.is_empty then

      -- iterate over the lines note columns
      for i,note_column in ipairs(line.note_columns) do
        if not note_column.is_empty then
          if not selected_columns_only or note_column.is_selected then
            print(string.format("deleting note column:%d '%s' in " ..
              "pattern: %d, track: %d, line: %d",
             i, tostring(note_column), pos.pattern, pos.track, pos.line))
            note_column:clear()
          end
        end
      end

      -- iterate over the lines effect columns
      for i,effect_column in ipairs(line.effect_columns) do
        if not effect_column.is_empty then
          if not selected_columns_only or effect_column.is_selected then
            print(string.format("deleting effect column:%d '%s' in " ..
              "pattern: %d, track: %d, line: %d",
               i, tostring(effect_column), pos.pattern, pos.track, pos.line))
            effect_column:clear()
          end
        end
      end

    end
  end

  print(string.format(">> PatternIterExample ran %.2f seconds",
    os.clock() - start_time_secs))
end


-- invoke_note_column_iter

function invoke_note_column_iter(iter, selected_columns_only)

  -- column iterators are like the line ierators, but they also 
  -- have a "column" field in the pos, and directly return the 
  -- coilumn
  --
  local start_time_secs = os.clock()

  for pos, note_column in iter do
    -- no need to look at completely empty columns in this example
    if not note_column.is_empty then
      if not selected_columns_only or note_column.is_selected then
        print(string.format("deleting note column:%d '%s' in " ..
          "pattern: %d, track: %d, line: %d",
          pos.pattern, tostring(note_column), 
          pos.pattern, pos.track, pos.line))
        note_column:clear()
      end
    end
  end

  print(string.format(">> PatternIterExample ran %.2f seconds",
    os.clock() - start_time_secs))
end


-- invoke_effect_column_iter

function invoke_effect_column_iter(iter, selected_columns_only)

  local start_time_secs = os.clock()

  for pos, effect_column in iter do
    -- no need to look at completely empty columns in this example
   if not effect_column.is_empty then
      if not selected_columns_only or effect_column.is_selected then
        print(string.format("deleting effect column:%d '%s' in " ..
          "pattern: %d, track: %d, line: %d",
           pos.column, tostring(effect_column), 
           pos.pattern, pos.track, pos.line))
        effect_column:clear()
      end
    end
  end

  print((">> PatternIterExample ran %.2f seconds"):format(
    os.clock() - start_time_secs))
end


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
