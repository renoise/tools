--[[============================================================================
-- NTrap
============================================================================]]--

--[[--

# Noodletrap

Noodletrap lets you record notes while bypassing the recording process in Renoise. Instead, your recordings ("noodlings") are stored into the instrument itself, using phrases as the storage mechanism.

## Links

Renoise: [Tool page](http://www.renoise.com/tools/noodletrap/)

Renoise Forum: [Feedback and bugs](http://forum.renoise.com/index.php/topic/43047-new-tool-30-noodletrap/)

Github: [Documentation and source](https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.Noodletrap.xrnx) 



--]]

--==============================================================================


local function unpack_args(...)
  local args = {...}
  if not args[1] then
    return {}
  else
    return args[1]
  end
end



class 'NTrapEvent'

function NTrapEvent:__init(...)

	local args = unpack_args(...)
  
	-- (number)
	self.timestamp = args.timestamp

	-- (bool)
	self.is_note_on = args.is_note_on

	-- (int) between 0 and 119
	self.pitch = args.pitch

	-- (int) between 0x00 and 0x7F
	self.velocity = args.velocity

	-- (int) renoise octave offset
	self.octave = args.octave     

	-- (renoise.SongPos) 
	self.playpos = args.playpos

end


function NTrapEvent:__tostring()

  return ("%s(timestamp = %s,"
    .."is_note_on = %s,"
    .."pitch = %s,"
    .."velocity = %s,"
    .."octave = %s,"
    .."playpos = %s)"):format(
      type(self),
      self.timestamp,
      tostring(self.is_note_on),
      tostring(self.pitch),
      tostring(self.velocity),
      tostring(self.octave),
      tostring(self.playpos)) 


end


