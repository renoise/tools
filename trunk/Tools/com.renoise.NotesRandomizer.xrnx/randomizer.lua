--[[============================================================================
randomizer.lua
============================================================================]]--

module("randomizer", package.seeall)


--------------------------------------------------------------------------------
-- Random Class
--------------------------------------------------------------------------------

class "Random"

-- Helper structure
Random.modes = {
  { name = 'Chaos', notes = {'C-','C#','D-','D#','E-','F-','F#','G-','G#','A-','A#','B-'} },
  { name = 'Harmonic Minor', notes = {'C-','D-','D#','F-','G-','G#'} },
  { name = 'Locrian', notes = {'C-','C#','D#','F-','F#','G#','A#','C-'} },
  { name = 'Lydian', notes = {'C-','D-','E-','F#','G-','A-','B-'} },
  { name = 'Melodic minor', notes = { 'C-', 'D-', 'D#', 'F-', 'G-', 'A-', 'B-' } },
  { name = 'Pentatonic Blues', notes = {'C-','D#','F-','F#','G-'} },
  { name = 'Pentatonic Major', notes = {'C-','D-','F-','G-','A-'} },
  { name = 'Pentatonic Minor', notes = {'C-','D#','F-','G-','A#'} },
  { name = 'Pentatonic Neutral', notes = {'C-','D-','F-','G-','A#'} },
}

-- Populate mode_names table with integers for keys
Random.mode_names = {}
for _,v in pairs(Random.modes) do
  table.insert(Random.mode_names, v.name)
end

-- Populate notes_sets table
Random.note_sets = {}
for _,v in pairs(Random.modes) do
  Random.note_sets[v.name] = v.notes
end

function Random:__init(mode, preserve_octave, neighbour, shift)
  math.randomseed(os.time())
  self:set_mode(mode or 'Chaos')
  self:set_preserve_octave(preserve_octave or false)
  self:set_neighbour(neighbour or false, shift or "up")
end

function Random:set_mode(mode)
  assert(Random.note_sets[mode] ~= nil)
  self.mode = mode
end

function Random:set_preserve_octave(preserve_octave)
  assert(type(preserve_octave) == 'boolean')
  self.preserve_octave = preserve_octave
end

function Random:set_neighbour(neighbour, shift)
  assert(type(neighbour) == 'boolean')
  self.neighbour = neighbour
  self.shift = shift or "up"
end

function Random:randomize(note)
  local number = nil
  local note_prefix_table = Random.note_sets[self.mode]
  local prefix = math.random(1, #note_prefix_table)
  prefix = note_prefix_table[prefix]

  if (self.mode ~= "Chaos" and self.neighbour) then
    prefix = self:_neighbour(note)
  end

  if (self.preserve_octave) then
    number = tonumber(string.sub(note, -1))
  end

  if type(number) == 'nil' then
    number = math.random(0, 9)
  end

  return (prefix .. number)
end

function Random:_neighbour(note)
  shift = self.shift:lower() or "up"
  local prefix = string.sub(note, 1, 2)
  local number = tonumber(string.sub(note, -1))
  if table.find(Random.note_sets[self.mode], prefix) == nil then
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
      if found == false then prefix = valid_notes[1] end --Rotate
    else
      -- Shift down
      for i = pos - 1, #valid_notes, -1 do
        if table.find(Random.note_sets[self.mode], valid_notes[i]) then
          prefix = valid_notes[i]
          found = true
          break
        end
      end
      if found == false then prefix = valid_notes[#valid_notes] end --Rotate
    end
  end
  return prefix
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
  mode, pattern_iterator, constrain, preserve_octave, neighbour, shift
)


  if (preserve_octave == nil) then
    preserve_octave = (renoise.app():show_prompt('Randomizer',
     'Preserve the octave of each note?', {'No', 'Yes'}) == "Yes")
  end

  local randomizer = Random(mode, preserve_octave, neighbour, shift)
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



