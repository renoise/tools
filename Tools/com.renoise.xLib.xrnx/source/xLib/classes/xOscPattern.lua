--[[============================================================================
-- xLib.xOscPattern
============================================================================]]--

--[[--

This class defines a syntax for matching/extracting/generating OSC messages.
.
#

To start with, you define an "input pattern" for matching values - either a literal value (number or string), or a "wildcard". For example:

      -- Match message with four integers, third one equal to 48
      "/renoise/trigger/note_on %i %i 48 %i"

## Wildcard and literal values

A wildcard is one of the supported OSC tags preceded by a percent sign. For example, the wildcard `%f` will match any floating point value. It's possible to mix literal values and wildcards. 

Depending on how literal values are specified, and whether `strict` is set to true, they are interpreted as specific types:

    "/some/integer 1"   <-- integer(strict)/number
    "/some/integer 0x1" <-- integer(strict)/number
    "/some/float 1.0"   <-- float(strict)/number
    "/some/string true" <-- string

## Strict mode and caching

Strict mode will look "more closely" at the literal values. This makes it possible to define a more restrictive/precise pattern and by default, is turned on. 

A special tag (NUMBER) exists, which can accept any type of value which can be translated into a number. An example would be if you have a device which transmit integers as floating point, or vice versa. 

Disabling strict interpretation will basically set all numeric tags to NUMBER instead of their more `strict` counterpart. The downside is that using a NUMBER will make the pattern unable to use caching.


--]]

--==============================================================================

class 'xOscPattern' 

xOscPattern.uid_counter = 0

--------------------------------------------------------------------------------

function xOscPattern:__init(...)

	local args = cLib.unpack_args(...) 

  --- string, pattern used for matching the input
  self.pattern_in = property(self.get_pattern_in,self.set_pattern_in)
  self.pattern_in_observable = renoise.Document.ObservableString("")

  --- string, pattern for constructing new messages
  self.pattern_out = property(self.get_pattern_out,self.set_pattern_out)
  self.pattern_out_observable = renoise.Document.ObservableString("")

  --- boolean, true when message contain functioning patterns
  self.complete = property(self.get_complete)

  --- called when patterns are changed
  self.before_modified_observable = renoise.Document.ObservableBang()

  --- boolean, whether to interpret literal values strictly or not
  --  (if false, use xOscValue.TAG.NUMBER to represent all numbers)
  self.strict = (type(args.strict)~="boolean") and true or args.strict 

  --- number, avoid rounding errors when comparing floats
  self.precision = (type(args.precision)=="number") and args.precision or 10000

  --- string, unique identifier for the pattern
  self.uid = nil

  -- internal --

  xOscPattern.uid_counter = xOscPattern.uid_counter + 1
  self.uid = "uid_"..tostring(xOscPattern.uid_counter)

  --- boolean, true when we can cache the incoming message
  self.cacheable = false

  --- table<xOscValue>, value is undefined when wildcard
  self.arguments = {}

  --- renoise.Document.ObservableStringList
  -- (this is just a convenience method for getting/setting the
  --  'name' part of our xOscValues)
  self.arg_names = property(self.get_arg_names,self.set_arg_names)
  self._arg_names = renoise.Document.ObservableStringList()

  --- string, input pattern (set via 'pattern_in')
  self.osc_pattern_in = nil

  --- string, output pattern (set via 'pattern_in' or 'pattern_out')
  self.osc_pattern_out = nil

  --- table<int> output arguments/order
  -- e.g. "/some/pattern $3 $1 $2" --> {3,1,2}
  self.output_args = nil

  -- initialize --

  if args.pattern_in then
    self:set_pattern_in(args.pattern_in)
  end
  if args.pattern_out then
    self:set_pattern_out(args.pattern_out)
  end
  if args.arg_names then
    self:set_arg_names(args.arg_names)
  end

end

--==============================================================================
-- Getters and Setters
--==============================================================================

-- get/set the input pattern

function xOscPattern:get_pattern_in()
  return self.pattern_in_observable.value
end

function xOscPattern:set_pattern_in(val)
  local modified = (val ~= self.pattern_in_observable.value) and true or false
  if modified then
    self.before_modified_observable:bang()
  end
  self.pattern_in_observable.value = val
  self:parse_input_pattern()
  self:parse_output_pattern()
end

--------------------------------------------------------------------------------

-- get/set the output pattern

function xOscPattern:get_pattern_out()
  return self.pattern_out_observable.value
end

function xOscPattern:set_pattern_out(val)
  local modified = (val ~= self.pattern_out_observable.value) and true or false
  if modified then
    self.before_modified_observable:bang()
  end
  self.pattern_out_observable.value = val
  self:parse_output_pattern() 

end

--------------------------------------------------------------------------------
--- get/set "display name" for each captured part, e.g. {"x","y","z"}
-- (always matching the number of arguments - undefined names are left empty)
-- @return table<string>

function xOscPattern:get_arg_names()
  --TRACE("xOscPattern:get_arg_names()")
  local rslt = {}
  for k,v in ipairs(self.arguments) do
    table.insert(rslt,v.name or "")
  end
  return rslt
end

function xOscPattern:set_arg_names(val)
  --TRACE("xOscPattern:set_arg_names(val)",val)
  for k,v in ipairs(self.arguments) do
    v.name = val[k] and tostring(val[k])  or ""
  end
end

--------------------------------------------------------------------------------
--- test the input/output pattern and return the result (validate)

function xOscPattern:get_complete()
  local is_complete = xOscPattern.test_pattern(self.pattern_in)
  if is_complete and (self.pattern_out ~= "") then
    is_complete = xOscPattern.test_pattern(self.pattern_out)
  end
  return is_complete
end


--==============================================================================
-- Class Methods
--==============================================================================

-- compare message against pattern
-- @param osc_msg, renoise.Osc.Message
-- @return boolean,string

function xOscPattern:match(msg)

  if not self.osc_pattern_in then
    return false, "No pattern defined"
  end

  -- check if same header
  if not (msg.pattern == self.osc_pattern_in) then
    return false,"Pattern didn't match:"..tostring(msg.pattern)..","..tostring(self.osc_pattern_in)
  else

    -- check if same number of values
    if not (#msg.arguments == #self.arguments) then
      return false,"Wrong number of arguments, expected "..tostring(#self.arguments)
    else

      -- check if argument types match
      for k,v in ipairs(self.arguments) do
        local arg = self.arguments[k]
        if (arg.value~=nil) then
          -- literal value match
          local value_match = false
          local val1,val2 = msg.arguments[k].value,arg.value
          if self.precision and (arg.tag == xOscValue.TAG.FLOAT) then
            value_match = cLib.float_compare(val1,val2,self.precision)
          else
            value_match = (val1 == val2)
          end
          if not value_match then
            return false,"Literal value didn't match:"..tostring(arg.value)..","..tostring(msg.arguments[k].value)
          elseif self.strict then
            if (msg.arguments[k].tag ~= arg.tag) then
              return false,"Strict mode: tags didn't match"
            end
          end
        else
          -- wildcard 
          if (arg.tag == "n") 
            and ((msg.arguments[k].tag == "i") 
            or (msg.arguments[k].tag == "f"))
          then
            -- passed
          elseif (msg.arguments[k].tag ~= arg.tag) then
            return false,"Argument tags didn't match:"..tostring(msg.arguments[k].tag)..","..tostring(arg.tag)
          end
        end
      end

      -- the message was matched
      return true
    end
  end

end

--------------------------------------------------------------------------------
--- Define the OSC pattern and wildcards/literal values
-- + also determines if pattern is cacheable

function xOscPattern:parse_input_pattern()
  
  self.arguments = {}
  local parts = {}

  local str_vars = string.gmatch(self.pattern_in,"[^%s]+")
  local count = 0
  for var,_ in str_vars do
    if (count == 0) then
      self.osc_pattern_in = var
    else
      if not string.match(var,"^%%%a") then
        -- literal value
        local tag,value = self:interpret_literal(var)
        table.insert(self.arguments,xOscValue{
          tag = tag,
          value = value
        })
      else
        -- wildcard, extract tag (%d,%f,etc), optionally name and properties:
        -- "%d:some_int{min=0,max=64}"
        local str_tag,str_name,str_props
        local comma_index = string.find(var,":",nil,true)
        if comma_index then
          str_tag = string.sub(var,2,comma_index-1)
          str_name = string.sub(var,comma_index+1,#var)
        else
          str_tag = string.sub(var,2)
        end

        table.insert(self.arguments,xOscValue{
          tag = str_tag,
          name = str_name,
        })
      end
    end
    count = count+1
  end

  -- reject when pattern contain floats, or we would end up 
  -- with an endless/useless amount of cached entries...
  local cacheable = true
  for k,v in ipairs(self.arguments) do
    if (v.tag == xOscValue.TAG.FLOAT) 
      or (v.tag == xOscValue.TAG.NUMBER)
    then
      cacheable = false
      break
    end
  end
  self.cacheable = cacheable

end

--------------------------------------------------------------------------------
-- Decide how outgoing messages are constructed 
-- + define a new "osc pattern"
-- + rearrange the order of values via "$n" tokens

function xOscPattern:parse_output_pattern()

  local rslt = {}

  if (self.pattern_out == "") then
    -- no output pattern, base on input
    self.osc_pattern_out = self.osc_pattern_in
    for k,v in ipairs(self.arguments) do
      table.insert(rslt,k)
    end
  else
    local str_vars = string.gmatch(self.pattern_out,"[^%s]+")
    for k,_ in str_vars do
      self.osc_pattern_out = k
      break
    end
    local matches = string.gmatch(self.pattern_out,"$(%d)")
    for k,v in matches do
      -- TODO support labels, e.g. $foo instead of $1
      table.insert(rslt,tonumber(k))
    end
  end

  self.output_args = rslt

end

--------------------------------------------------------------------------------
--- Check if the pattern contains only literal values (no wildcards/tokens)
--- return boolean

function xOscPattern:purely_literal()

  if (self.arguments == 0) then
    return true
  end

  for k,v in ipairs(self.arguments) do
    if (type(v.value)=="nil") then
      return false
    end
  end

  return true

end

--------------------------------------------------------------------------------
--- Create a new OSC message from internal or provided values
-- @param args (table<xOscValue>)
-- @return renoise.Osc.Message or nil when failed
-- @return string, message when failed

function xOscPattern:generate(args)

  if not self.osc_pattern_out then
    return nil, "Can't generate message without an output pattern"
  end

  args = args or self.arguments

  -- TODO check if all values are defined

  local osc_args = {}
  for k,v in ipairs(self.output_args) do
    local osc_tag = self.arguments[v].tag
    local osc_value = args[v] and args[v].value or self.arguments[v].value
    if (osc_tag == xOscValue.TAG.NUMBER) then
      osc_tag = self:interpret_literal(tostring(osc_value),true)
    end
    table.insert(osc_args,{
      tag = osc_tag,
      value = osc_value
    })
  end

  return renoise.Osc.Message(self.osc_pattern_out,osc_args)

end

--------------------------------------------------------------------------------

-- make an educated guess about the value-type 
-- @param str (string), e.g. "1", "1.0" or "0x1"
-- @param force_strict (boolean) 
-- @return xOscValue.TAG
-- @return string or number 

function xOscPattern:interpret_literal(str,force_strict)

  local as_number = tonumber(str)
  if as_number then
    if self.strict or force_strict then
      if string.find(str,".",nil,true) then
        return xOscValue.TAG.FLOAT,as_number
      else
        return xOscValue.TAG.INTEGER,as_number
      end
    else
      return xOscValue.TAG.NUMBER,as_number
    end
  else
    return xOscValue.TAG.STRING,str
  end

end

--------------------------------------------------------------------------------

function xOscPattern:__tostring()

  return type(self) .. ": "
    .. "pattern_in="..self.pattern_in
    .. ", pattern_out="..self.pattern_out
    .. ", osc_pattern_in="..self.osc_pattern_in
    .. ", osc_pattern_out="..self.osc_pattern_out
    .. ", strict="..tostring(self.strict)
    .. ", precision="..tostring(self.precision)
    .. ", uid="..tostring(self.uid)

end

--------------------------------------------------------------------------------
-- Static methods
--------------------------------------------------------------------------------
-- Check if the syntax is fundamentally flawed
-- @return boolean,string

function xOscPattern.test_pattern(str_pattern)

  -- check for initial forward slash
  if (string.sub(str_pattern,0,1) ~= "/") then
    return false,"An OSC pattern should start with a forward slash"
  end

  -- check pattern/value parts
  local str_vars = string.gmatch(str_pattern,"[^%s]+")
  local count = 0
  for var,_ in str_vars do

    -- TODO 
    if (count == 0) then
      -- check if pattern is valid
    else
      if string.match(var,"^%%%a") then
        -- check if wildcards are valid
      else
        -- check if literal values are valid
      end
    end
  end
  
  return true

end

--------------------------------------------------------------------------------
--- Check if pattern is matching same type of values as another pattern,
-- disregarding any literal values being set - only look for the type/tag. 
-- For example, "/test %i" would match "/test 42" as they have the same path
-- and are both matching an integer value...
-- @param this (xOscPattern)
-- @param that (xOscPattern)
-- @return boolean,string

function xOscPattern.types_are_matching(this,that)

  if not (#this.arguments == #that.arguments) then
    return false, "Number of arguments does not match:"
      ..tostring(#this.arguments)..","..#that.arguments
  end

  if (this.osc_pattern_in ~= that.osc_pattern_in) then
    return false, "Pattern does not match:"
      ..tostring(this.osc_pattern_in)..","..that.osc_pattern_in
  end

  for k,v in ipairs(this.arguments) do
    if not (v.tag == that.arguments[k].tag) then
      return false, "Tags does not match:"
        ..tostring(v.tag)..","..tostring(that.arguments[k].tag)
    end
  end

  return true

end

