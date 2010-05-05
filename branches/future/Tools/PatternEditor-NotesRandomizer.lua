--[[----------------------------------------------------------------------------
Random Class
----------------------------------------------------------------------------]]--

class "Random"

Random.valid_modes = {
  ['Chaos'] = {'C-','C#','D-','D#','E-','F-','F#','G-','G#','A-','A#','B-'},
  ['Harmonic Minor'] = {'C-','D-','D#','F-','G-','G#'},
  ['Locrian'] = {'C-','C#','D#','F-','F#','G#','A#','C-'},
  ['Lydian'] = {'C-','D-','E-','F#','G-','A-','B-'},
  ['Melodic minor'] = { 'C-', 'D-', 'D#', 'F-', 'G-', 'A-', 'B-' },
  ['Pentatonic Blues'] = {'C-','D#','F-','F#','G-'},
  ['Pentatonic Major'] = {'C-','D-','F-','G-','A-'},
  ['Pentatonic Minor'] = {'C-','D#','F-','G-','A#'},
  ['Pentatonic Neutral'] = {'C-','D-','F-','G-','A#'},
}

function Random:__init(mode, preserve_octave)
  math.randomseed(os.time())
  self:set_mode(mode or 'Chaos')
  self:set_preserve_octave(preserve_octave or false)
end

function Random:set_mode(mode)
  assert(Random.valid_modes[mode] ~= nil)
  self.mode = mode
end

function Random:set_preserve_octave(preserve_octave)
  assert(type(preserve_octave) == 'boolean')
  self.preserve_octave = preserve_octave
end

function Random:randomize(note)
  local number = nil
  local note_prefix_table = Random.valid_modes[self.mode]
  local prefix = math.random(1, #note_prefix_table)
  prefix = note_prefix_table[prefix]

  if (self.preserve_octave) then
    number = tonumber(string.sub(note, -1))
  end

  if type(number) == 'nil' then
    number = math.random(0, 9)
  end

  return (prefix .. number)
end


--[[----------------------------------------------------------------------------
Shuffle Class
----------------------------------------------------------------------------]]--

class "Shuffle"

function Shuffle:__init()
  math.randomseed(os.time())
  self.stack = {}
end

function Shuffle:reset()
  self.stack = {}
end

function Shuffle:push(note)
  table.insert(self.stack, note)
end

function Shuffle:pop()
  return table.remove(self.stack, math.random(1, #self.stack))
end


--[[----------------------------------------------------------------------------
Custom Iterator Class
----------------------------------------------------------------------------]]--

class "Iterator"

function Iterator:__init(constrain_to_selected, callback_function)
  self.constrain_to_selected = constrain_to_selected or false
  self.callback = callback_function or function(x) return x end
end

function Iterator:set_constrain_to_selected(selected)
  assert(type(selected) == 'boolean')
  self.constrain_to_selected = selected
end

function Iterator:set_callback(callback_function)
  assert(type(callback_function) == 'function')
  self.callback = callback_function
end

function Iterator:go(iter)
  for _,line in iter do
    if not line.is_empty then
      for _,note_col in ipairs(line.note_columns) do
        if
          not self.constrain_to_selected or
          self.constrain_to_selected and note_col.is_selected
        and
          not note_col.is_empty and
          note_col.note_value ~= renoise.PatternTrackLine.NOTE_OFF and
          note_col.note_value ~= renoise.PatternTrackLine.EMPTY_NOTE
        then
          note_col.note_string = self.callback(note_col.note_string)
        end
      end
    end
  end
end


--[[----------------------------------------------------------------------------
Randomize notes
----------------------------------------------------------------------------]]--

function invoke_random(mode, pattern_iterator, constrain)

  local preserve_octave = renoise.app():show_prompt(
    'Randomizer',
    'Preserve the octave of each note?',
    {'No', 'Yes'}
  )

  local randomizer = Random(mode, preserve_octave == 'Yes')
  local iterator = Iterator(constrain)

  iterator:set_callback(function(x) return randomizer:randomize(x) end)
  iterator:go(pattern_iterator)
end


--[[----------------------------------------------------------------------------
Shuffle notes
----------------------------------------------------------------------------]]--

function invoke_shuffle(pattern_iterator, constrain)

  local shuffle = Shuffle()
  local iterator = Iterator(constrain)

  iterator:set_callback(function(x) shuffle:push(x); return x end)
  iterator:go(pattern_iterator)

  iterator:set_callback(function(x) return shuffle:pop(x); end)
  iterator:go(pattern_iterator)
end


--[[----------------------------------------------------------------------------
Manifest
----------------------------------------------------------------------------]]--

manifest = {}
manifest.api_version = 0.2
manifest.author = "Dac Chartrand [dac@renoise.com]"
manifest.description = "Randomize Notes, Version 0.2"

manifest.actions = {}


--[[ Song ]]--

-- Randomize song
for mode,_ in pairs(Random.valid_modes) do
  manifest.actions[mode .. #manifest.actions + 1] = {
    name = "MainMenu:Tools:Randomize:Song:" .. mode,
    description = "Randomize a song using mode: " .. mode,
    invoke = function()
      local song = renoise.song()
      local iter = song.pattern_iterator:lines_in_song(true)
      invoke_random(mode, iter)
    end
  }
end

-- Shuffle song
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Randomize:Song:Shuffle",
  description = 'Shuffle a song',
  invoke = function()
    local song = renoise.song()
    local iter = song.pattern_iterator:lines_in_song(true)
    invoke_shuffle(iter)
  end
}


--[[ Pattern ]]--

-- Randomize pattern
for mode,_ in pairs(Random.valid_modes) do
  manifest.actions[mode .. #manifest.actions + 1] = {
    name = "MainMenu:Tools:Randomize:Pattern:" .. mode,
    description = "Randomize a pattern using mode: " .. mode,
    invoke = function()
      local song = renoise.song()
      local index = song.selected_pattern_index
      local iter = song.pattern_iterator:lines_in_pattern(index)
      invoke_random(mode, iter)
    end
  }
end

-- Shuffle pattern
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Randomize:Pattern:Shuffle",
  description = 'Shuffle pattern',
  invoke = function()
    local song = renoise.song()
    local index = song.selected_pattern_index
    local iter = song.pattern_iterator:lines_in_pattern(index)
    invoke_shuffle(iter)
  end
}


--[[ Track ]]--

-- Randomize track
for mode,_ in pairs(Random.valid_modes) do
  manifest.actions[mode .. #manifest.actions + 1] = {
    name = "MainMenu:Tools:Randomize:Track:" .. mode,
    description = "Randomize a track using mode: " .. mode,
    invoke = function()
      local song = renoise.song()
      local index = song.selected_track_index
      local iter = song.pattern_iterator:lines_in_track(index, true)
      invoke_random(mode, iter)
    end
  }
end

-- Shuffle track
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Randomize:Track:Shuffle",
  description = 'Shuffle track',
  invoke = function()
    local song = renoise.song()
    local index = song.selected_track_index
    local iter = song.pattern_iterator:lines_in_track(index, true)
    invoke_shuffle(iter)
  end
}


--[[ Track in Pattern ]]--

-- Randomize track
for mode,_ in pairs(Random.valid_modes) do
  manifest.actions[mode .. #manifest.actions + 1] = {
    name = "MainMenu:Tools:Randomize:Track In Pattern:" .. mode,
    description = "Randomize selected track using mode: " .. mode,
    invoke = function()
      local song = renoise.song()
      local index = song.selected_pattern_index
      local index2 = song.selected_track_index
      local iter = song.pattern_iterator:lines_in_pattern_track(index, index2)
      invoke_random(mode, iter)
    end
  }
end

-- Shuffle track
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Randomize:Track In Pattern:Shuffle",
  description = 'Shuffle selected track',
  invoke = function()
    local song = renoise.song()
    local index = song.selected_pattern_index
    local index2 = song.selected_track_index
    local iter = song.pattern_iterator:lines_in_pattern_track(index, index2)
    invoke_shuffle(iter)
  end
}


--[[ Selection ]]--

-- Randomize selected notes in pattern
for mode,_ in pairs(Random.valid_modes) do
  manifest.actions[mode .. #manifest.actions + 1] = {
    name = "MainMenu:Tools:Randomize:Selection:" .. mode,
    description = "Randomize selected notes using mode: " .. mode,
    invoke = function()
      local song = renoise.song()
      local index = song.selected_pattern_index
      local iter = song.pattern_iterator:lines_in_pattern(index)
      invoke_random(mode, iter, true)
    end
  }
end

-- Shuffle selected notes in pattern
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Randomize:Selection:Shuffle",
  description = 'Shuffle selected notes',
  invoke = function()
    local song = renoise.song()
    local index = song.selected_pattern_index
    local iter = song.pattern_iterator:lines_in_pattern(index)
    invoke_shuffle(iter, true)
  end
}
