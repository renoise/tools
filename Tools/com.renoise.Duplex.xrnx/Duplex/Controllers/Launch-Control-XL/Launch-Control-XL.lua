--[[----------------------------------------------------------------------------
-- Duplex.LaunchControlXL 
----------------------------------------------------------------------------]]--

--[[

Inheritance: LaunchControlXL > MidiDevice > Device

Based on the Launchpad class

--]]


--==============================================================================

class "LaunchControlXL" (MidiDevice)

function LaunchControlXL:__init(display_name, message_stream, port_in, port_out)
  TRACE("LaunchControlXL:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  -- this device has a color-space with 4 degrees of red and green
  -- (note: this is stuff left over from the launchpad. In this config 
  -- we do not specify a global colorspace, instead the control-map is used)
  --self.colorspace = {4, 4, 0}

end

--------------------------------------------------------------------------------

-- clear display before releasing device:
-- all LEDs are turned off, and the mapping mode, buffer settings, 
-- and duty cycle are reset to defaults

function LaunchControlXL:release()
  TRACE("LaunchControlXL:release()")

  self:send_cc_message(0,0) 
  MidiDevice.release(self)

end

--------------------------------------------------------------------------------
-- override default Device method
-- @see Device.output_value

function LaunchControlXL:output_boolean(pt,xarg,ui_obj)
  TRACE("LaunchControlXL:output_boolean(pt,xarg,ui_obj)",pt,xarg,ui_obj)
  
    -- default color is light/yellow
    local rslt = 127
    local red = pt.color[1]
    local green = pt.color[2]
    red = math.floor(red/64)
    green = math.floor(green/64)
    -- 12 for standard flags
    rslt = 16*green+red+12

    return rslt


end

