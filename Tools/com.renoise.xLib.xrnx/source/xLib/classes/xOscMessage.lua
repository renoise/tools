--[[============================================================================
-- xLib.xOscMessage
============================================================================]]--

--[[--

A higher-level OSC message 
.
#

See also:
@{xMessage}
@{xOscDevice}

--]]

--==============================================================================

class 'xOscMessage' (xMessage)

--------------------------------------------------------------------------------

function xOscMessage:__init(...)

  -- native OSC message
	local args = cLib.unpack_args(...) 

  xMessage.__init(self,...)

  -- string, name of source/target device
  self.device_name = property(self.get_device_name,self.set_device_name)
  self.device_name_observable = renoise.Document.ObservableString(xOscDevice.DEFAULT_DEVICE_NAME)

  -- xOscPattern, how to interpret messages
  self.pattern = nil

  -- renoise.Osc.Message
  self.raw_message = nil

  -- initialize

  -- apply message/arguments
  if (type(args)=="Message") then
    self.raw_message = args
    --self.pattern = nil
    self._values = table.rcopy(args.arguments)
  else
    self.device_name_observable.value = args.device_name and args.device_name or xOscDevice.DEFAULT_DEVICE_NAME
    self.raw_message = args.osc_msg 
    self.pattern = args.pattern 
  end


end

-------------------------------------------------------------------------------
-- Getters/Setters
--------------------------------------------------------------------------------

function xOscMessage:get_device_name()
  return self.device_name_observable.value
end

function xOscMessage:set_device_name(val)
  assert(type(val)=="string","Expected device_name to be a string")
  self.device_name_observable.value = val
end

-------------------------------------------------------------------------------
-- Class Methods
--------------------------------------------------------------------------------
-- construct a new message based on current values
-- @return renoise.Osc.Message

function xOscMessage:create_raw_message()

  -- use pattern arguments as blueprint
  local arguments = table.rcopy(self.pattern.arguments)
  for k,v in ipairs(self.values) do
    if arguments[k] then
      arguments[k].value = v
    end
  end

  local osc_msg = self.pattern:generate(arguments)

  return osc_msg

end

-------------------------------------------------------------------------------

function xOscMessage:get_definition()

  local def = xMessage.get_definition(self)
  def.device_name = self.device_name
  def.pattern = self.pattern
  
  return def

end

--------------------------------------------------------------------------------

function xOscMessage:__tostring()

  return type(self) 
    ..", #values:"..tostring(#self.values) 
    ..", device_name:"..tostring(self.device_name)

end

