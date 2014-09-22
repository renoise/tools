--[[============================================================================
-- Duplex.Applications.Keyboard.GridLayout.HarmonicLayout
============================================================================]]--

--[[--
Harmonic layout for the Keyboard application. 
See also: @{Duplex.Applications.Keyboard.GridLayout} 
 

### Layout

        scale ►
         _ _ _ _ _ _ _ _
    o   |c|_|_|_|_|_|_|_| 
    c   |c|_|_|_|_|_|_|_|
    t   |c|_|_|_|_|_|_|_|
    a   |c|_|_|_|_|_|_|_|
    v   |c|_|_|_|_|_|_|_|
    e   |c|_|_|_|_|_|_|_|
        |c|_|_|_|_|_|_|_|
    ▼   |c|_|_|_|_|_|_|_|


The harmonic layout is great if you want to fit your playing to a specific 
harmonic scale. It is very easy to understand: up and down will change the 
octave, while left and right will play the intervals of the scale. This layout 
can be very compact, and because of this, offer a greater range of notes.  


--]]

--==============================================================================


class 'HarmonicLayout' (GridLayout)

HarmonicLayout.ALIGN_NONE = 1
HarmonicLayout.ALIGN_OCTAVES = 2

function HarmonicLayout:__init(...)
  TRACE("HarmonicLayout:__init()")

  self.alignment = HarmonicLayout.ALIGN_OCTAVES
  self.flip_octaves = false 

  GridLayout.__init(self,...)


end


--------------------------------------------------------------------------------

--- overridden method
-- @see GridLayout.get_pitches_from_index

function HarmonicLayout:get_pitches_from_index(idx)
  TRACE("HarmonicLayout:get_pitches_from_index(idx)",idx)

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

  local pitch = ((row-2)*12) + self.kb:get_nth_note(col) - 1 
  pitch = pitch + (self.kb.scale_key-1) + self.kb.curr_octave*12
  return {self.kb:restrict_pitch_to_scale(pitch)}
  --return {pitch}

end
