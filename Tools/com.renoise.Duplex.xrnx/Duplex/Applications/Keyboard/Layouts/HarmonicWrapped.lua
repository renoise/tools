--[[============================================================================
-- Duplex.Applications.Keyboard.GridLayout.HarmonicWrapped
============================================================================]]--

--[[--
Harmonic layout for the Keyboard application (wrapped version)
See also: @{Duplex.Applications.Keyboard.GridLayout} 
 

--]]

--==============================================================================


class 'HarmonicWrapped' (GridLayout)

function HarmonicWrapped:__init(...)
  TRACE("HarmonicWrapped:__init()")

  self.flip_octaves = true 

  GridLayout.__init(self,...)

end

--------------------------------------------------------------------------------
-- @see GridLayout.get_pitches_from_index

function HarmonicWrapped:get_pitches_from_index(idx)
  TRACE("HarmonicWrapped:get_pitches_from_index(idx)",idx)

  if not table.is_empty(self._cached_indexes) and
    self._cached_indexes[idx]
  then
    return self._cached_indexes[idx]
  end

  if self.flip_octaves then 
    local row = self.kb.grid_h - math.ceil(idx / self.kb.grid_w)
    idx = ((idx-1) % self.kb.grid_w+1) + (row * self.kb.grid_w)
  end 
  
  local scale = xScale.get_scale_by_name(self.kb.scale_mode)
  local oct = math.ceil(idx/scale.count)+self.kb.curr_octave - 2
  local nth_note = (idx-1)%scale.count+1
  local semitones = self.kb:get_nth_note(nth_note) - 1
  local pitch = (oct*12) + semitones
  return {self.kb:restrict_pitch_to_scale(pitch)}

end
