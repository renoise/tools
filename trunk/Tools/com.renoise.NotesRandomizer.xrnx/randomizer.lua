--[[============================================================================
randomizer.lua
============================================================================]]--

module("randomizer", package.seeall)


--------------------------------------------------------------------------------
-- Random Class
--------------------------------------------------------------------------------

class "Random"

-- Helper structure
-- Important: Do not change "Chaos", it represents "All notes" internally
Random.modes = {
  { name = 'Chaos', notes = {'C-','C#','D-','D#','E-','F-','F#','G-','G#','A-','A#','B-'} },
  { name = 'Algerian', notes = {'C-','D-','E-','F-','F#','G-','A-','B-'} },
  { name = 'Augmented', notes = {'C-','D-','E-','F#','G#','B-'} },
  { name = 'Auxiliary Augmented', notes = {'D-','E-','F#','G#','A#','B#'} },
  { name = 'Auxiliary Diminished Blues', notes = {'C#','D-','E-','E#','G-','G#','A#','B-'} },
  { name = 'Auxiliary Diminished', notes = {'D-','E-','F-','G-','G#','A-','A#', 'B-', 'C#'} },
  { name = 'Balinese', notes = {'C-','D-','B-','G-','A-'} },
  { name = 'Blues', notes = {'C-','E-','f-','F#','G-','B-'} },
  { name = 'Harmonic Minor', notes = {'C-','D-','D#','F-','G-','G#'} },
  { name = 'Hirajoshi', notes = {'C#','D#','E-','G#','A-'} },
  { name = 'Locrian', notes = {'C-','C#','D#','F-','F#','G#','A#','C-'} },
  { name = 'Lydian', notes = {'C-','D-','E-','F#','G-','A-','B-'} },
  { name = 'Melodic minor', notes = { 'C-', 'D-', 'D#', 'F-', 'G-', 'A-', 'B-' } },
  { name = 'Pentatonic Blues', notes = {'C-','D#','F-','F#','G-'} },
  { name = 'Pentatonic Major', notes = {'C-','D-','F-','G-','A-'} },
  { name = 'Pentatonic Minor', notes = {'C-','D#','F-','G-','A#'} },
  { name = 'Pentatonic Neutral', notes = {'C-','D-','F-','G-','A#'} },
}

-- Populate mode_names table with integers for keys (used for sorting)
Random.mode_names = {}
for _,v in pairs(Random.modes) do
  table.insert(Random.mode_names, v.name)
end

-- Populate note_sets table
Random.note_sets = {}
for _,v in pairs(Random.modes) do
  Random.note_sets[v.name] = table.copy(v.notes)
end

function Random:__init(mode)
  math.randomseed(os.time())
  -- Fix for poor OSX/BSD random behavior
  -- @see: http://lua-users.org/lists/lua-l/2007-03/msg00564.html
  local garbage = math.random()
  garbage = math.random()
  self:set_mode(mode or 'Chaos')
end

function Random:set_mode(mode)
  assert(Random.note_sets[mode] ~= nil)
  self.mode = mode
end

function Random:set_key(key)
  assert(table.find(Random.note_sets["Chaos"], key) ~= nil)
  -- Reset keys to C-
  for _,v in pairs(Random.modes) do
    Random.note_sets[v.name] = table.copy(v.notes)
  end
  if self.mode == "Chaos" or key == "C-" then return end

  local intervals = {}
  local shift = table.copy(Random.note_sets["Chaos"])
  local key_table = Random.note_sets[self.mode]

  for i = 1, #key_table do
    table.insert(intervals, (table.find(Random.note_sets["Chaos"], key_table[i])))
  end

  while shift[1] ~= key do
     table.insert(shift, shift[1])
     table.remove(shift, 1)
  end

  for i = 1, #intervals do
    key_table[i] = shift[intervals[i]]
  end

end


function Random:set_preserve_notes(preserve_notes)
  assert(type(preserve_notes) == 'boolean')
  self.preserve_notes = preserve_notes
end

function Random:set_preserve_octave(preserve_octave)
  assert(type(preserve_octave) == 'boolean')
  self.preserve_octave = preserve_octave
end

function Random:set_neighbour(neighbour, shift)
  assert(type(neighbour) == 'boolean')
  self.neighbour = neighbour
  self.shift = shift or "rand"
end

function Random:set_range(min, max)
  assert(type(min) == 'number')
  assert(type(max) == 'number')
  assert(min <= max)
  self.min = math.min(9, math.max(min, 0))
  self.max = math.min(9, math.max(max, 0))
end

function Random:randomize(note)

  local number = nil
  local prefix = nil

  if self.neighbour and self.mode ~= "Chaos" then
    -- Nearest neighbour
    prefix, number = self:_neighbour(note)
  else
    -- Random
    local note_prefix_table = Random.note_sets[self.mode]
    prefix = math.random(1, #note_prefix_table)
    prefix = note_prefix_table[prefix]
    if self.preserve_notes and self.mode ~= "Chaos" then
      local prefix2 = string.sub(note, 1, 2)
      if table.find(Random.note_sets[self.mode], prefix2) ~= nil then
        prefix = prefix2
      end
    end
    if self.preserve_octave then
      number = tonumber(string.sub(note, -1))
    end
  end

  -- Range
  local min, max = 0, 9
  if self.min then min = self.min end
  if self.max then max = self.max end
  if type(number) == 'nil' then
    number = math.random(min, max)
  end

  return (prefix .. number)
end

function Random:_neighbour(note)

  local shift = self.shift:lower() or "rand"
  if shift == "rand" then
    if math.random(2) == 1 then shift = "up"
    else shift = "down"
    end
  end

  local prefix = string.sub(note, 1, 2)
  local number = tonumber(string.sub(note, -1))
  if
    self.preserve_notes and
    table.find(Random.note_sets[self.mode], prefix) ~= nil
  then
    -- Keep note
  else
    local valid_notes = Random.note_sets["Chaos"]
    local pos = table.find(valid_notes, prefix)
    local found = false
    if shift == "up" then
      -- Shift up
      for i = pos + 1, #valid_notes do
        if table.find(Random.note_sets[self.mode], valid_notes[i]) then
          prefix = valid_notes[i]
          found = true
          break
        end
      end
      if found == false then --Rotate
        prefix = Random.note_sets[self.mode][1]
        number = number + 1
      end
    else
      -- Shift down
      for i = pos - 1, 1, -1 do
        if table.find(Random.note_sets[self.mode], valid_notes[i]) then
          prefix = valid_notes[i]
          found = true
          break
        end
      end
      if found == false then --Rotate
        local count = table.count(Random.note_sets[self.mode])
        prefix = Random.note_sets[self.mode][count]
        number = number - 1
      end
    end
  end

  if not self.preserve_octave then
    number = nil
  else
    number = math.min(9, math.max(number, 0))
  end

  return prefix, number

end


--------------------------------------------------------------------------------
-- Shuffle Class
--------------------------------------------------------------------------------

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


--------------------------------------------------------------------------------
-- Custom Iterator Class
--------------------------------------------------------------------------------

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
        (
          not self.constrain_to_selected or
          self.constrain_to_selected and note_col.is_selected
        )
        and
        (
          not note_col.is_empty and
          note_col.note_value ~= renoise.PatternTrackLine.NOTE_OFF and
          note_col.note_value ~= renoise.PatternTrackLine.EMPTY_NOTE
        )
        then
          note_col.note_string = self.callback(note_col.note_string)
        end
      end
    end
  end
end


--------------------------------------------------------------------------------
-- functions
--------------------------------------------------------------------------------

-- invoke_random

function invoke_random(
  mode, pattern_iterator, constrain, key, preserve_notes, preserve_octave,
  neighbour, shift, min, max
)

  if (preserve_octave == nil) then
    preserve_octave = (renoise.app():show_prompt('Randomizer',
     'Preserve the octave of each note?', {'No', 'Yes'}) == "Yes")
  end

  local randomizer = Random(mode)
  if key then randomizer:set_key(key) end
  if preserve_octave then randomizer:set_preserve_octave(preserve_octave) end
  if preserve_notes then randomizer:set_preserve_notes(preserve_notes) end
  if neighbour then randomizer:set_neighbour(neighbour, shift) end
  if min and max then randomizer:set_range(min, max) end

  local iterator = Iterator(constrain)
  iterator:set_callback(function(x) return randomizer:randomize(x) end)
  iterator:go(pattern_iterator)
end


--------------------------------------------------------------------------------

-- Shuffle notes

function invoke_shuffle(pattern_iterator, constrain)

  local shuffle = Shuffle()
  local iterator = Iterator(constrain)

  iterator:set_callback(function(x) shuffle:push(x); return x end)
  iterator:go(pattern_iterator)

  iterator:set_callback(function(x) return shuffle:pop(x) end)
  iterator:go(pattern_iterator)
end



