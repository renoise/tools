--[[===============================================================================================
cConvert
===============================================================================================]]--

--[[--

Various static conversion methods
.

NB: Renoise finetuning is expressed as a value between -127 and 127. 

]]

--=================================================================================================

class 'cConvert'

---------------------------------------------------------------------------------------------------
-- [Static] Convert note to hertz
-- @param note (number)
-- @param hz_ini (number) [optional]
-- @return number 

function cConvert.note_to_hz(note,hz_ini)
  TRACE('cConvert.note_to_hz(note,hz_ini)',note,hz_ini)
  hz_ini = hz_ini or 440
  return math.pow(2, (note-57)/12) * hz_ini;
end

---------------------------------------------------------------------------------------------------
-- [Static] convert hertz to note value 
-- @param freq (number)
-- @param hz_ini (number) [optional]
-- @return note (number), cents (number between 0 and 1)

function cConvert.hz_to_note(freq,hz_ini)
  TRACE('cConvert.hz_to_note(freq,hz_ini)',freq,hz_ini)
  hz_ini = hz_ini or 440
  local lnote = (math.log(freq)-math.log(hz_ini))/math.log(2)+4;
	local oct = math.floor(lnote);
	local cents = 1200*(lnote-oct);
  local note_num = math.floor(cents/100)%12;
  cents = cents - note_num*100;
	if (cents > 50) then
		cents = cents-100;
    note_num = note_num+1 
  end 

  return (note_num + 9) + (oct*12), cents

end

---------------------------------------------------------------------------------------------------
-- [Static] Note to frames - e.g. 48 (C-4) -> 169
-- @param note (number)
-- @param sample_rate (number)
-- @param hz_ini (number)
-- @return number (floor), number (with fractional part)

function cConvert.note_to_frames(note,sample_rate,hz_ini)
  TRACE("cConvert.note_to_frames(note,sample_rate,hz_ini)",note,sample_rate,hz_ini)
  hz_ini = hz_ini or 440
  local frame = ((1/2)^((note-57)/12)) * (sample_rate/hz_ini)
  return math.floor(frame),frame
end

---------------------------------------------------------------------------------------------------
-- [Static] Note to frames - e.g. 48 (C-4) -> 169
-- @param note (number)
-- @param sample_rate (number)
-- @param hz_ini (number)
-- @return number (rounded), number (with fractional part)

function cConvert.frames_to_note(frames,sample_rate,hz_ini)
  TRACE("cConvert.frames_to_note(frames,sample_rate,hz_ini)",frames,sample_rate,hz_ini)
  local hz = cConvert.frames_to_hz(frames,sample_rate,hz_ini)
  --print("*** hz",hz)
  return cConvert.hz_to_note(hz,hz_ini)

end

---------------------------------------------------------------------------------------------------
-- [Static] Frames to hertz
-- @param frames (frames)
-- @param sample_rate (number)
-- @param transpose (number), optional transpose amount (defaults to C-4/48)
-- @return number, value in hertz

function cConvert.frames_to_hz(frames,sample_rate,transpose)
  TRACE("cConvert.frames_to_hz(frames,sample_rate,transpose)",frames,sample_rate,transpose)
  local frames_srate = sample_rate/frames
  if transpose then
    local base_hz = cConvert.note_to_hz(48)   
    local transp_hz = cConvert.note_to_hz(transpose)
    return (transp_hz / base_hz) * frames_srate
  else
    return frames_srate
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Hertz to frames 
-- @param hz (frames)
-- @param sample_rate (number)
-- @param transpose (number), optional transpose amount (defaults to C-4/48)
-- @return number (rounded), number (with fractional part)

function cConvert.hz_to_frames(hz,sample_rate,transpose)
  TRACE("cConvert.hz_to_frames(hz,sample_rate,transpose)",hz,sample_rate,transpose)

  local frames = sample_rate/hz 
  if transpose then
    local base_hz = cConvert.note_to_hz(48)   
    local transp_hz = cConvert.note_to_hz(transpose)
    frames = frames * (transp_hz / base_hz) 
  end

  return cLib.round_value(frames),frames

end

