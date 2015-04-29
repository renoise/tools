--[[----------------------------------------------------------------------------
Midi Class, Version 0.2

Author: Dac Chartrand (http://www.trotch.com)
Supports MIDI (binary) and MF2T (text) formats
Based on Valentin Schmidt's PHP MIDI CLASS
@see: http://www.dasdeck.de/staff/valentin/midi/


# Available methods:
--------------------

 * open
 * setTempo
 * getTempo
 * setBpm
 * getBpm
 * setTimebase
 * getTimebase
 * newTrack
 * getTrack
 * getMsgCount
 * addMsg
 * insertMsg
 * getMsg
 * deleteMsg
 * deleteTrack
 * getTrackCount
 * soloTrack
 * transpose
 * transposeTrack
 * importTxt
 * importTrackTxt
 * getTxt
 * getTrackTxt
 * importMid
 * getMid
 * saveTxtFile
 * saveMidFile


# MF2T textfile format:
-----------------------

File header:        MFile <format> <ntrks> <division>
Start of track:     MTrk
End of track:       TrkEnd

Note On:            On <ch> <note> <vol>
Note Off:           Off <ch> <note> <vol>
Poly Pressure:      PoPr[PolyPr] <ch> <note> <val>
Channel Pressure:   ChPr[ChanPr] <ch> <val>
Controller
parameter:          Par[Param] <ch> <con> <val>
Pitch bend:         Pb <ch> <val>
Program change:     PrCh[ProgCh] <ch> <prog>
Sysex message:      SysEx <hex>


Sequence nr:        Seqnr <num>
Key signature:      KeySig <num> <manor>
Tempo:              Tempo <num>
Time signature:     TimeSig <num>/<num> <num> <num>
SMPTE event:        SMPTE <num> <num> <num> <num> <num>

Meta text events:   Meta <texttype> <string>
Meta end of track:  Meta TrkEnd
Sequencer specific: SeqSpec <type> <hex>
Misc meta events:   Meta <type> <hex>

The <> have the following meaning:

<ch>        ch=<num>
<note>      n=<noteval>  [note=<noteval>]
<vol>       v=<num> [vol=<num>]
<val>       v=<num> [val=<num>]
<con>       c=<num> [con=<num>]
<prog>      p=<num> [prog=<num>]
<manor>     minor or major
<noteval>   either a <num> or A-G optionally followed by #,
            followed by <num> without intermediate spaces.

<texttype>  Text Copyright SeqName TrkName InstrName Lyric Marker Cue or <type>
<type>      a hex number of the form 0xab
<hex>       a sequence of 2-digit hex numbers (without 0x) separated by space
<string>    a string between double quotes (like "text").

Channel numbers are 1-based, all other numbers are as they appear in the midifile.

<division>  is either a positive number (giving the time resolution in
            clicks per quarter note) or a negative number followed by a positive
            number (giving SMPTE timing).

<format> <ntrks> <num> are decimal numbers.

The <num> in the Pb is the real value (two midibytes combined).
In Tempo it is a long (32 bits) value. Others are in the interval 0-127.
The SysEx sequence contains the leading F0 and the trailing F7.

----------------------------------------------------------------------------]]--

class "Midi"

function Midi:__init()
  -- Array of tracks, where each track is array of message strings
  self.tracks = table.create()
  -- timebase = ticks per frame (quarter note)
  self.timebase = 480
  -- tempo as integer (0 for unknown)
  self.tempo = 0
  -- position of tempo event in track 0
  self.tempoMsgNum = nil
  -- Midi file type (0 or 1)
  self.type = 0
end


-- Creates (or resets to) new empty MIDI song
function Midi:open(timebase)
  self.tempo = 0 --125000 = 120 bpm
  self.timebase = timebase or 480
  self.tracks = table.create()
end


-- Set initial tempo by replacing tempo msg in track 0 (or adding new track 0)
function Midi:setTempo(tempo)
  assert(type(tempo) == 'number')
  tempo = math.floor(tempo + .5) --Round
  if self.tempoMsgNum ~= nil then
     self.tracks[1][2] = "0 Tempo " .. tempo
  else
    local tempoTrack = table.create{
      "0 TimeSig 4/4 24 8",
      "0 Tempo " .. tempo,
      "0 Meta TrkEnd"
    }
    self.tracks:insert(1, tempoTrack)
    self.tempoMsgNum = 2
  end
  self.tempo = tempo
end


-- Returns tempo (0 if not set)
function Midi:getTempo()
  return self.tempo
end


-- Sets tempo corresponding to given bpm
function Midi:setBpm(bpm)
  local tempo = math.floor(60000000/bpm + .5) --Round
  self:setTempo(tempo)
end


-- Returns bpm corresponding to tempo
function Midi:getBpm()
  return toint(60000000/self.tempo)
end


-- Sets timebase
function Midi:setTimebase(tb)
  self.timebase = tb
end


-- Returns timebase
function Midi:getTimebase()
  return self.timebase
end


-- Adds new track, returns new track count
function Midi:newTrack()
  self.tracks:insert(table.create())
  return self.tracks:count()
end


-- Returns track as array of msg strings
function Midi:getTrack(tn)
  if type(self.tracks[tn]) == 'table' then
    return self.tracks[tn]:copy()
  else
    return nil
  end
end


-- Returns number of messages of track
function Midi:getMsgCount(tn)
  if type(self.tracks[tn]) == 'table' then
    return self.tracks[tn]:count()
  else
    return 0
  end
end


-- Adds message to end of track
function Midi:addMsg(tn, msgStr, ttype)
  if ttype == 1 then  --0:absolute, 1:delta
    local last = self:_getTime(self.tracks[tn][table.count(self.tracks[tn])])
    local msg = explode(" ", msgStr)
    local dt = toint(msg[1]);
    msg[1] = last + dt
    msgStr = table.concat(msg, " ")
  end
  self.tracks[tn]:insert(msgStr)
end


-- Adds message at adequate position of track (slower than addMsg)
function Midi:insertMsg(tn, msgStr)
  local time = self:_getTime(msgStr)
  local mc = self.tracks[tn]:count()
  local i = 1
  while i <= mc do
    local t = self:_getTime(self.tracks[tn][i])
    if t >= time then break end
    i = i + 1
  end
  self.tracks[tn]:insert(i, msgStr)
end


-- Returns message number (mn) of track (tn)
function Midi:getMsg(tn, mn)
  if self.tracks[tn] == nil or self.tracks[tn][mn] == nil then
    return ""
  else
    return self.tracks[tn][mn]
  end
end


-- Deletes message number (mn) of track (tn)
function Midi:deleteMsg(tn, mn)
  self.tracks[tn]:remove(mn)
end


-- Deletes track
function Midi:deleteTrack(tn)
  self.tracks:remove(tn)
  return self.tracks:count()
end


-- Returns number of tracks
function Midi:getTrackCount()
  return self.tracks:count()
end


-- Deletes all tracks except track (tn) (and track 1 which contains tempo info)
function Midi:soloTrack(tn)
  local tempo = self.tracks[1]:copy()
  if tn == 1 then
    self.tracks = table.create{tempo}
  else
    local track = self.tracks[tn]:copy()
    self.tracks = table.create{tempo, track}
  end
end



-- Transposes song by (dn) half tone steps
function Midi:transpose(dn)
  local tc = self.tracks:count()
  for i=1, tc do
    self:transposeTrack(i, dn)
  end
end


-- Transposes track (tn) by (dn) half tone steps
function Midi:transposeTrack(tn, dn)
  local mc = self.tracks[tn]:count()
  for i = 1, mc do
    local msg = explode(" ", self.tracks[tn][i])
    if msg[2] == 'On' or msg[2] == 'Off' then
      -- msg[] looks something like:
      -- { 1344, Off, ch=1, n=48, v=0 }
      local n = assert(loadstring('local ' .. msg[4] .. '; return n'))()
      n = math.max(0, math.min(127, n + dn))
      msg[4] = 'n=' .. n
      self.tracks[tn][i] = table.concat(msg, " ")
    end
  end
end


-- Import whole MIDI song as text (mf2t-format)
function Midi:importTxt(txt)

  txt = trim(txt)
  -- Make unix text format
  if txt:find("\r") ~= nil and txt:find("\n") == nil then
    txt = txt:gsub("\r", "\n") -- MAC
  else
    txt = txt:gsub("\r", "") -- PC?
  end
  txt = txt .. "\n" --makes things easier

  local headerStr = trim(string.match(txt, '.-\n'))
  local header = explode(' ', headerStr) --"MFile type tc timebase"
  self.type = header[2]
  self.timebase = header[4]
  self.tempo = 0

  local trackStrings = explode("MTrk\n" ,txt)
  trackStrings:remove(1)

  local tracks = table.create()
  for _,trackStr in ipairs(trackStrings) do
    local track = explode("\n", trackStr)
    track:remove()
    track:remove()
    if track[1] == "TimestampType=Delta" then
      track:remove(1)
      _delta2Absolute(track)
    end
    tracks:insert(track)
  end
  self.tracks = tracks
  self:_findTempo()

end


-- Imports track as text (mf2t-format)
function Midi:importTrackTxt(txt, tn)
  txt = trim(txt)
  -- Make unix text format
  if txt:find("\r") ~= nil and txt:find("\n") == nil then
    txt = txt:gsub("\r", "\n") -- MAC
  else
    txt = txt:gsub("\r", "") -- PC?
  end

  local track = explode("\n", txt)

  if track[1] == 'MTrk' then track:remove(1) end
  if track[track:count()] == 'TrkEnd' then track:remove() end

  if track[1] == "TimestampType=Delta" then
    track:remove(1)
    _delta2Absolute(track)
  end

  if tn ~= nil then
    self.tracks[tn] = track
  else
    self.tracks:insert(track)
  end

  if tn == 1 then self:_findTempo() end

end


-- Returns MIDI song as text (mf2t-format)
function Midi:getTxt(ttype)
  local tc = self.tracks:count()
  local type_ = 0
  if tc > 1 then type_ = 1 end
  local str = string.format("MFile %d %d %d", type_, tc, self.timebase) .. "\n"
  for i=1, tc do
    str = str .. self:getTrackTxt(i, ttype)
  end
  return str
end


-- Returns track as text
function Midi:getTrackTxt(tn, ttype)
  local str = "MTrk\n"
  if ttype == 1 then --0:absolute, 1:delta
    str = str .. "TimestampType=Delta\n"
    local last = 0
    for _,msgStr in ipairs(self.tracks[tn]) do
      local msg = explode(" ", msgStr)
      local t = toint(msg[1])
      msg[1] = t - last
      str = str .. table.concat(msg, " ") .. "\n"
      last = t
    end
  else
    for _,msg in ipairs(self.tracks[tn]) do
      str = str .. msg .. "\n"
    end
  end
  str = str .. "TrkEnd\n"
  return str
end


-- Imports Standard MIDI File (typ 0 or 1) (and RMID)
-- (if optional parameter (tn) set, only track (tn) is imported)
function Midi:importMid(smf_path, tn)

  local smf = assert(io.open(smf_path, "rb"))
  local song = smf:read("*all")
  smf:close()

  local pos = song:find("MThd")
  if  toint(pos) > 0 then
    song = song:sub(pos) --get rid of RMID header
  end

  local header = song:sub(1, 14)
  assert(header:sub(1, 8) == "MThd\0\0\0\6", "Wrong MIDI-header")

  local type_ = header:byte(10)
  assert(type_ <= 1, 'Only SMF type 0 and 1 supported')

  local timebase = header:byte(13)*256 + header:byte(14)
  self.type = type_
  self.timebase = timebase
  self.tempo = 0 --maybe (hopefully!) overwritten by _parseTrack

  local trackStrings = explode('MTrk', song)
  trackStrings:remove(1)
  local tracks = table.create()
  local tsc = trackStrings:count()
  if type(tn) == 'number' then
    assert(tn <= tsc, 'SMF has less tracks than ' .. tn)
    tracks:insert(self:_parseTrack(trackStrings[tn], tn))
  else
    for i=1, tsc do
      tracks:insert(self:_parseTrack(trackStrings[i], i))
    end
  end
  self.tracks = tracks
end

-- Returns binary MIDI string
function Midi:getMid()

  local tc = self.tracks:count()
  local type_ = 0
  if tc > 1 then type_ = 1 end
  local midStr = "MThd\0\0\0\6\0" .. string.char(type_) ..
                 _getBytes(tc, 2) .. _getBytes(self.timebase, 2)

  for i = 1, tc do
    local track = self.tracks[i]
    local mc = track:count()
    local time = 0
    midStr = midStr .. "MTrk"
    local trackStart = midStr:len()

    local last = ""
    for j = 1, mc do

      local line = track[j]
      local t = self:_getTime(line)
      local dt = t - time
      time = t
      midStr = midStr .. _writeVarLen(dt)

      --repetition, same event, same channel, omit first byte (smaller file size)
      local str = self:_getMsgStr(line)
      local start = str:byte(1)
      if start >= 0x80 and start <= 0xEF and start == last then
        str = str:sub(2)
      end

      last = start
      midStr = midStr .. str
    end
    local trackLen = midStr:len() - trackStart
    midStr = midStr:sub(1, trackStart) .. _getBytes(trackLen, 4) ..
             midStr:sub(trackStart + 1)

  end
  return midStr

end


-- Saves MIDI song as mf2t text file
function Midi:saveTxtFile(mid_path)
  if self.tracks:count() < 1 then error( "MIDI song has no tracks") end
  local out = assert(io.open(mid_path, "w"))
  out:write(self:getTxt())
  assert(out:close())
end


-- Saves MIDI song as Standard MIDI File
function Midi:saveMidFile(mid_path)
  if self.tracks:count() < 1 then error( "MIDI song has no tracks") end
  local out = assert(io.open(mid_path, "wb"))
  out:write(self:getMid())
  assert(out:close())
end


--[[----------------------------------------------------------------------------
Private methods
----------------------------------------------------------------------------]]--

-- Returns time code of message string
function Midi:_getTime(msgStr)
  local tmp = string.match(msgStr, '%w+ ')
  return toint(tmp)
end


-- Returns binary code for message string
function Midi:_getMsgStr(line)

  local msg = explode(" ", line)
  local ch, p, n, v, c, num, texttypes, byte, start, end_, txt, len,
        tempo, h, m, s, f, fh, zt, z, t, mc, vz, g, cnt, data = nil

  if ("PrCh" == msg[2]) then --0x0C
    ch = assert(loadstring('local '.. msg[3] .. 'return ch'))() --chan
    p = assert(loadstring('local ' .. msg[4] .. '; return p'))() --prog
    return string.char(0xC0+ch-1, p)

  elseif ("On" == msg[2]) then --0x09
    ch = assert(loadstring('local ' .. msg[3] .. '; return ch'))() --chan
    n = assert(loadstring('local ' .. msg[4] .. '; return n'))() --note
    v = assert(loadstring('local ' .. msg[5] .. '; return v'))() --vel
    return string.char(0x90+ch-1, n, v)

  elseif ("Off" == msg[2]) then --0x08
    ch = assert(loadstring('local ' .. msg[3] .. '; return ch'))() --chan
    n = assert(loadstring('local ' .. msg[4] .. '; return n'))() --note
    v = assert(loadstring('local ' .. msg[5] .. '; return v'))() --vel
    return string.char(0x80+ch-1, n, v)

  elseif ("PoPr" == msg[2]) then --0x0A = PolyPressure
    ch = assert(loadstring('local ' .. msg[3] .. '; return ch'))() --chan
    n = assert(loadstring('local ' .. msg[4] .. '; return n'))() --note
    v = assert(loadstring('local ' .. msg[5] .. '; return v'))() --val
    return string.char(0xA0+ch-1, n, v)

  elseif ("Par" == msg[2]) then --0x0B = ControllerChange
    ch = assert(loadstring('local ' .. msg[3] .. '; return ch'))() --chan
    c = assert(loadstring('local ' .. msg[4] .. '; return c'))() --controller
    v = assert(loadstring('local ' .. msg[5] .. '; return v'))() --val
    return string.char(0xB0+ch-1, c, v)

  elseif ("ChPr" == msg[2]) then --0x0D = ChannelPressure
    ch = assert(loadstring('local ' .. msg[3] .. '; return ch'))() --chan
    v = assert(loadstring('local ' .. msg[4] .. '; return v'))() --val
    return string.char(0xD0+ch-1, v)

  elseif ("Pb" == msg[2]) then --0x0E = PitchBend
    ch = assert(loadstring('local ' .. msg[3] .. '; return ch'))() --chan
    v = assert(loadstring('local ' .. msg[4] .. '; return v'))() --val(2 bytes!)
    local a = bit.band(v, 0x7f) -- Bits 0..6
    local b = bit.band(bit.rshift(v, 7), 0x7f) --Bits 7..13
    return string.char(0xE0+ch-1, a, b)

  -- META EVENTS
  elseif ("Seqnr" == msg[2]) then --0x00 = sequence_number
    num = string.char(msg[3])
    if msg[3] > 255 then error( "Code broken around Seqnr event") end
    return
      string.char(tonumber("FF", 16), tonumber("00", 16), tonumber("02", 16),
      tonumber("00", 16)) .. num

  elseif ("Meta" == msg[2]) then

    if
      "Text" == msg[3] or
      "Copyright" == msg[3] or
      "TrkName" == msg[3] or
      "InstrName" == msg[3] or
      "Lyric" == msg[3] or
      "Marker" == msg[3] or
      "Cue" == msg[3]
    then
      -- 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
      texttypes = {
        'Text', 'Copyright', 'TrkName', 'InstrName', 'Lyric', 'Marker', 'Cue'
       }
       byte = string.char(table.find(texttypes, msg[3]))
       start, end_ = line:find('"(.*)"')
       txt = line:sub(start + 1, end_ - 1)
       len = string.char(txt:len())
       if toint(len) > 127 then
         error( "Code broken (write varLen-Meta)")
       end
       return string.char(tonumber("FF", 16)) .. byte .. len .. txt

    elseif "TrkEnd" == msg[3] then --0x2F
      return
        string.char(tonumber("FF", 16), tonumber("2F", 16), tonumber("00", 16))

    elseif "0x20" == msg[3] then --0x20 = ChannelPrefix
      v = string.char(msg[4])
      return
        string.char(tonumber("FF", 16), tonumber("20", 16), tonumber("01", 16))
        .. v

    elseif "0x21" == msg[3] then --0x21 = ChannelPrefixOrPort
      v = string.char(msg[4])
      return
        string.char(tonumber("FF", 16), tonumber("21", 16), tonumber("01", 16))
        .. v

    else
      error( "Unknown meta event: " .. msg[3])

    end

  elseif ("Tempo" == msg[2]) then --0x51
    tempo = _getBytes(toint(msg[3]), 3)
    return
      string.char(tonumber("FF", 16), tonumber("51", 16), tonumber("03", 16))
      .. tempo

  elseif ("SMPTE" == msg[2]) then --0x54 = SMPTE offset
    h = string.char(msg[3])
    m = string.char(msg[4])
    s = string.char(msg[5])
    f = string.char(msg[6])
    fh = string.char(msg[7])
    return
      string.char(tonumber("FF", 16), tonumber("54", 16), tonumber("05", 16))
      .. h .. m .. s .. f .. fh

  elseif ("TimeSig" == msg[2]) then --0x58
    zt = explode("/", msg[3])
    z = string.char(zt[1])
    t = string.char(math.log(zt[2])/math.log(2))
    mc = string.char(msg[4])
    c = string.char(msg[5])
    return
      string.char(tonumber("FF", 16), tonumber("58", 16), tonumber("04", 16))
      .. z .. t .. mc .. c

  elseif ("KeySig" == msg[2]) then --0x59
    vz = string.char(msg[3])
    if msg[4] == "major" then
      g = string.char(0)
    else
      g = string.char(1)
    end
    return
      string.char(tonumber("FF", 16), tonumber("59", 16), tonumber("02", 16))
      .. vz .. g

  elseif ("SeqSpec" == msg[2]) then --0x7F = Sequencer specific data
    cnt = msg:count() - 2
    data = ""
    for i = 1, cnt do
      data = data .. hex2bin(msg[i+2])
    end
    len = string.char(data:len())
    if toint(len) > 127 then
      error( "Code broken (write varLen-Meta)")
    end
    return string.char(tonumber("FF", 16), tonumber("7F", 16)) .. len .. data

  elseif ("SysEx" == msg[2]) then -- 0xF0 = SysEx
    start, end_ = line:find('f0(.*)f7')
    data = line:sub(start + 2, end_ - 2)
    data = _hex2bin(data:gsub(" ", ""))
    len = string.char(data:len())
    return string.char(tonumber("F0", 16))  .. len .. data

  else
    error( "Unknown event: " .. msg[2])

  end

end


-- converts binary track string to track (list of msg strings)
function Midi:_parseTrack(binStr, tn)

  local trackLen = binStr:len()
  local p = 4
  local time = 0
  local track = table.create()
  local dt, len, byte, high, low, chan, prog, last, note, vel, val, c,
        meta, tmp, num, texttypes, type_, txt, tempo, h, n, s, f, fh, z,
        t, mc, vz, g, data, metacode, str = nil

  while p < trackLen do

    -- timedelta
    dt, p = _readVarLen(binStr, p)
    time = time + dt
    byte = binStr:byte(p + 1)
    high = bit.rshift(byte, 4)
    low = byte - high * 16

    if 0x0C == high then --PrCh = ProgramChange
      chan = low + 1
      prog = binStr:byte(p + 2)
      last = "PrCh"
      track:insert(string.format(
        "%d PrCh ch=%d p=%d", time, chan, prog
      ))
      p = p + 2

    elseif 0x09 == high then --On
      chan = low + 1
      note = binStr:byte(p + 2)
      vel = binStr:byte(p + 3)
      last = "On"
      track:insert(string.format(
        "%d On ch=%d n=%d v=%d", time, chan, note, vel
      ))
      p = p + 3

    elseif 0x08 == high then --Off
      chan = low + 1
      note = binStr:byte(p + 2)
      vel = binStr:byte(p + 3)
      last = "Off"
      track:insert(string.format(
        "%d Off ch=%d n=%d v=%d", time, chan, note, vel
      ))
      p = p + 3

    elseif 0x0A == high then --PoPr = PolyPressure
      chan = low + 1
      note = binStr:byte(p + 2)
      val = binStr:byte(p + 3)
      last = "PoPr"
      track:insert(string.format(
        "%d PoPr ch=%d n=%d v=%d", time, chan, note, val
      ))
      p = p + 3

    elseif 0x0B == high then --Par = ControllerChange
      chan = low + 1
      c = binStr:byte(p + 2)
      val = binStr:byte(p + 3)
      last = "Par"
      track:insert(string.format(
        "%d Par ch=%d c=%d v=%d", time, chan, c, val
      ))
      p = p + 3

    elseif 0x0D == high then --ChPr = ChannelPressure
      chan = low + 1
      val = binStr:byte(p + 2)
      last = "ChPr"
      track:insert(string.format(
        "%d ChPr ch=%d v=%d", time, chan, val
      ))
      p = p + 2

    elseif 0x0E == high then --Pb = PitchBend
      chan = low + 1
      val = bit.bor(
        bit.band(binStr:byte(p + 2), 0x7F),
        bit.lshift(bit.band(binStr:byte(p + 3), 0x7F), 7)
      )
      last = "Pb"
      track:insert(string.format(
        "%d Pb ch=%d v=%d", time, chan, val
      ))
      p = p + 3

    else
      -- Byte
      if 0xFF == byte then
        --Meta
        meta = binStr:byte(p + 2)
        if 0x00 == meta then --sequence_number
          tmp = binStr:byte(p + 3)
          if tmp == 0x00 then
            num = tn
            p = p + 3
          else
            num = 1
            p = p + 5
          end
          track:insert(string.format(
            "%d Seqnr %d", time, num
          ))

        elseif
          0x01 == meta or
          0x02 == meta or
          0x03 == meta or
          0x04 == meta or
          0x05 == meta or
          0x06 == meta or
          0x07 == meta
        then --text, copyright, trkname, instrname, lyric, marker, cue
          texttypes = {
          'Text', 'Copyright', 'TrkName', 'InstrName', 'Lyric', 'Marker', 'Cue'
          }
          type_ = texttypes[meta]
          p = p + 2
          len, p = _readVarLen(binStr, p)
          assert(
            len + p <= trackLen,
            string.format(
            "Meta %s has corrupt variable length field (%s) [track: %s dt: %s",
            type_, len, tn, dt
            )
          )
          txt = binStr:sub(p + 1, p + len)
          track:insert(string.format(
            '%d Meta %s "%s"', time, type_, txt
          ))
          p = p + len

        elseif 0x20 == meta then --ChannelPrefix
          if binStr:byte(p + 3) == 0 then
            p = p + 3
          else
            chan = binStr:byte(p + 4)
            last = "MetaChannelPrefix"
            track:insert(string.format(
              "%d Meta 0x20 %02d", time, chan
            ))
            p = p + 4
          end

        elseif 0x21 == meta then --ChannelPrefixOrPort
          chan = binStr:byte(p + 4)
          track:insert(string.format(
            "%d Meta 0x21 %02d", time, chan
          ))
          p = p + 4

        elseif 0x2F == meta then --Meta TrkEnd
          track:insert(string.format(
            "%d Meta TrkEnd", time
          ))
          return track --Ignore rest

        elseif 0x51 == meta then --Tempo
          tempo = binStr:byte(p + 4) * 256 * 256 +
                  binStr:byte(p + 5) * 256 +
                  binStr:byte(p + 6)
          track:insert(string.format(
            "%d Tempo %d", time, tempo
          ))
          if tn == 0 and time == 0 then
            self.tempo = tempo
            self.tempoMsgNum = track:count() - 1
          end
          p = p + 6

        elseif 0x54 == meta then --SMPTE offset
          h, m, s, f, fh = 0
          if len > 0 then h = binStr:byte(p + 4) end
          if len > 1 then m = binStr:byte(p + 5) end
          if len > 2 then s = binStr:byte(p + 6) end
          if len > 3 then f = binStr:byte(p + 7) end
          if len > 4 then fh = binStr:byte(p + 8) end
          track:insert(string.format(
            "%d SMPTE %d %d %d %d %d", time, h, m, s, f, fh
          ))
          p = p + 3 + len

        elseif 0x58 == meta then --TimeSig
          z = binStr:byte(p + 4)
          t = math.pow(2, binStr:byte(p + 5))
          mc = binStr:byte(p + 6)
          mc = binStr:byte(p + 7)
          track:insert(string.format(
            "%d TimeSig %d/%d %d %d", time, z, t, mc, c
          ))
          p = p + 7

        elseif 0x59 == meta then --KeySig
          len = binStr:byte(p + 3) -- should be: 0x02 => p+=5
          vz, g = 0, "minor"
          if len > 0 then vz = binStr:byte(p + 4) end
          if len <= 1 or binStr:byte(p + 5) == 0 then g = "major" end
          track:insert(string.format(
            "%d KeySig %d %s", time, vz, g
          ))
          p = p + 3 + len

        elseif 0x7F == meta then --Sequencer specific data
          p = p + 2
          len, p = _readVarLen(binStr, p)
          assert(len+p <= trackLen,
            string.format(
            "SeqSpec has corrupt variable length field (%d) [track: %d dt: %d]",
            len, tn, dt
          ))
          p = p - 3
          data = ""
          for i=0, len do
            data = data .. string.format(" %02x", binStr:byte(p + 4 + i))
          end
          track:insert(string.format(
            "%d SeqSpec%s", time, data
          ))
          p = p + 3 + len

        else -- accept "unknown" Meta-Events
          metacode = string.format("%02x", binStr:byte(p + 2))
          p = p + 2
          len, p = _readVarLen(binStr, p)
          assert(len+p <= trackLen,
            string.format(
            "Meta %s has corrupt variable length field (%d) [track: %d dt: %d]",
            metacode, len, tn, dt
          ))
          p = p - 3
          data = ""
          for i=0, len do
            data = data .. string.format(" %02x", binStr:byte(p + 4 + i))
          end
          track:insert(string.format(
            "%d Meta 0x%s %s", time, metacode, data
          ))
          p = p + 3 + len

        end -- meta

      elseif 0xF0 == byte then
        p = p + 1
        len, p = _readVarLen(binStr, p)
          assert(len+p <= trackLen,
            string.format(
            "SysEx has corrupt variable length field" ..
            "(%d) [track: %d dt: %d p: %d]",
            metacode, len, tn, dt, p
          ))
        str = "f0"
        for i=0, len do
          str = str .. string.format(" %02x", binStr:byte(p + 1 + i))
        end
        track:insert(string.format(
          "%d SysEx %s", time, str
        ))
        p = p + len

      else
        -- repetition of last event?
        if
          'On' == last or
          'Off' == last
        then
          note = binStr:byte(p + 1)
          vel = binStr:byte(p + 2)
          track:insert(string.format(
            "%d %s ch=%d n=%d v=%d",
            time, last, chan, note, vel or 0
          ))
          p = p + 2

        elseif 'PrCh' == last then
          prog = binStr:byte(p + 1)
          track:insert(string.format(
            "%d PrCh ch=%d p=%d",
            time, chan, prog
          ))
          p = p + 1

        elseif 'PoPr' == last then
          note = binStr:byte(p + 2)
          val = binStr:byte(p + 3)
          track:insert(string.format(
            "%d PoPr ch=%d n=%d v=%d",
            time, chan, note, val
          ))
          p = p + 2

        elseif 'ChPr' == last then
          val = binStr:byte(p + 1)
          track:insert(string.format(
            "%d ChPr ch=%d v=%d",
            time, chan, val
          ))
          p = p + 1

        elseif 'Par' == last then
          c = binStr:byte(p + 1)
          val = binStr:byte(p + 2)
          track:insert(string.format(
            "%d Par ch=%d c=%d v=%d",
            time, chan, c, val
          ))
          p = p + 2

        elseif 'Pb' == last then
          val = bit.bor(
            bit.band(binStr:byte(p + 1), 0x7F),
            bit.lshift(bit.band(binStr:byte(p + 2), 0x7F), 7)
          )
          track:insert(string.format(
            "%d Pb ch=%d v=%d",
            time, chan, val
          ))
          p = p + 2

        elseif 'MetaChannelPrefix' == last then
          last = "MetaChannelPrefix"
          track:insert(string.format(
            "%d Meta 0x20 %02d",
            time, chan
          ))
          p = p + 3

        else
          error( "Unknown repetition: " .. tostring(last))

        end --last

      end --byte

    end --high

  end --while()

  return track

end


-- Search track 1 for set tempo msg
function Midi:_findTempo()
  local mc = self.tracks[1]:count()
  for i=1,mc do
    local msg = explode(" ", self.tracks[1][i])
    if toint(msg[1]) > 0 then break end
    if msg[2] == "Tempo" then
      self.tempo = msg[3]
      self.tempoMsgNum = i
      break
    end
  end
end
