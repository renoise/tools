--[[============================================================================
-- Duplex.Applications.Keyboard.GridLayout.HarmonicWrapped
============================================================================]]--

--[[--
Harmonic layout for the Keyboard application (wrapped version)
See also: @{Duplex.Applications.Keyboard.GridLayout} 
 

--]]

--==============================================================================


class 'HarmonicWrapped' (GridLayout)

HarmonicWrapped.ALIGN_NONE = 1
HarmonicWrapped.ALIGN_OCTAVES = 2

function HarmonicWrapped:__init(...)
  TRACE("HarmonicWrapped:__init()")

  self.alignment = HarmonicWrapped.ALIGN_OCTAVES
  self.flip_octaves = true 

  GridLayout.__init(self,...)

end

--------------------------------------------------------------------------------
--- overridden method
-- @see GridLayout.get_pitches_from_index

function HarmonicWrapped:get_pitches_from_index(idx)
  TRACE("HarmonicWrapped:get_pitches_from_index(idx)",idx)

  if not table.is_empty(self._cached_indexes) and
    self._cached_indexes[idx]
  then
    return self._cached_indexes[idx]
  end

  local unit_count = self.kb.grid_w*self.kb.grid_h
  local row = math.ceil((idx/unit_count) * self.kb.grid_w)
  local col = idx%self.kb.grid_h
  col = (col == 0) and self.kb.grid_h or col
  if self.flip_octaves then
    row = (self.kb.grid_w - row) + 1
  end

  local scale = HARMONIC_SCALES[self.kb.scale_mode]
  col = col - (self.kb.scale_key-1)
  if (col <= 0) then
    row = row + math.ceil(col/scale.count) - 1
    col = col%scale.count
    col = (col == 0) and scale.count or col
  end

  local pitch = (col-1) + ((row-1)*self.kb.grid_h)
  pitch = pitch + (self.kb.scale_key-1) + (self.kb.curr_octave-1)*12
  return {self.kb:restrict_pitch_to_scale(pitch)}

end
