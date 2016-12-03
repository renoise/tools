--[[============================================================================
vWaveform 
============================================================================]]--
--[[

  Waveform visulation made simple
  
  Introduces two extra display modes, suitable for stereo samples:


  |  |    |
  || | | ||
  ---------   <- DUAL, two sets of values - for example, a stereo waveform
  |    |   
  |||| | ||


  |  |    |
  || | | ||
  ---------   <- DUAL_MIRROR, two sets with the lower one flipped vertically
  |||| | |
  | |  | |




  TODO
  - stereo waveform (create dual vGraph, feed them left/right channel)
  - ability to display a range of the data (zooming)


]]

--==============================================================================

require (_vlibroot.."vGraph")

class 'vWaveform' (vGraph)

function vWaveform:__init(...)
  TRACE("vWaveform:__init()")

  local rns = renoise.song()
  local args = cLib.unpack_args(...)

  -- properties -----------------------
  
  self._instr_index = args.instr_index or rns.selected_instrument_index
  self.instrument_index = property(self.get_instr_index,self.set_instr_index)

  self._sample_index = args.sample_index or rns.selected_sample_index
  self.sample_index = property(self.get_sample_index,self.set_sample_index)

  -- callbacks ------------------------


  -- internal -------------------------

  vGraph.__init(self,...)

  self:collect_frames()
  self:update()

end

--------------------------------------------------------------------------------

function vWaveform:collect_frames()
  TRACE("vWaveform:collect_frames()")

  self:clear_selection()
  self._data = {}

  local rns = renoise.song()

  local instr = rns.instruments[self._instr_index]
  if not instr then
    return
  end

  local sample = instr.samples[self._sample_index]
  if not sample then
    return
  end

  if not sample.sample_buffer.has_sample_data then
    return
  end

  local num_frames = sample.sample_buffer.number_of_frames
  local interval = num_frames/self._width
  local f_idx = 1 -- "float/floor" index
  for pixel_h = 1,self._width do

    -- TODO channel selection
    local channel_idx = 1

    local left = sample.sample_buffer:sample_data(channel_idx,math.floor(f_idx))

    -- TODO handle this in the vGraph by means of min/max values
    left = (left/2) + 0.5

    table.insert(self._data,left)

    f_idx = f_idx + interval

  end

  -- setting data will also prepare selection, etc.
  self:set_data(self._data)


end

--------------------------------------------------------------------------------

function vWaveform:set_instr_index(val)
  TRACE("vWaveform:set_instr_index(val)",val)

  local changed = (val ~= self._instr_index)
  if not changed then
    return 
  end
  self._instr_index = val

  self:collect_frames()
  self:request_update()
end

function vWaveform:get_instr_index()
  return self._instr_index
end

--------------------------------------------------------------------------------

function vWaveform:set_sample_index(val)
  TRACE("vWaveform:set_sample_index(val)",val)

  local changed = (val ~= self._sample_index)
  if not changed then
    return 
  end
  self._sample_index = val

  self:collect_frames()
  self:request_update()
end

function vWaveform:get_sample_index()
  return self._sample_index
end


