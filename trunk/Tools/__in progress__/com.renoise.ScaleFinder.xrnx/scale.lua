notes = { 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#' };
scales = {
  {
    name = 'Major',
    pattern = "101011010101"
  },
  {
    name = 'Minor',
    pattern = '101101011010'
  }
}

chords = {
  {
    name = 'Major',
    code = 'maj',
    pattern = '10001001'
  },
  {
    name = 'Minor',
    code = 'min',
    pattern = '10010001'
  },
  {
    name = 'Augmented',
    code = 'aug',
    pattern = '100010001'
  },
  {
    name = 'Diminished',
    code = 'dim',
    pattern = '10010010'
  }  

}

------------------------------------------------------
function get_scale(root, scale)
  local spat = scale['pattern'];
  local rpat = {false,false,false,false,false,false,false,false,false,false,false}
  -- Finds scale notes
  for i = 0,11 do
    local note = ((root - 1 + i) % 12) + 1
    if spat:sub(i+1, i+1) == '1' then
      rpat[note] = true
    end
  end
  return rpat
end

------------------------------------------------------
function is_valid(root, chord, scale_pattern)
  local cpat = chords[chord]['pattern']
  for i = 0,11 do
    local note = ((root - 1 + i) % 12) + 1
    if cpat:sub(i+1, i+1) == '1' then
      if not scale_pattern[note] then
        return false;
      end
    end
  end
  return true;
end

