--[[----------------------------------------------------------------------------
-- Duplex.LaunchpadMiniMK3
----------------------------------------------------------------------------]]--

--[[

Inheritance: Launchpad > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

cLib.require(_clibroot.."cTable")

class "LaunchpadMiniMK3" (MidiDevice)

LaunchpadMiniMK3.COLOR_OFF     = {0x00,0x00,0x00}
LaunchpadMiniMK3.COLOR_WHITE   = {0xff,0xff,0xff}
LaunchpadMiniMK3.COLOR_GREEN   = {0x00,0xff,0x00}
LaunchpadMiniMK3.COLOR_YELLOW  = {0xff,0xff,0x00}
LaunchpadMiniMK3.COLOR_BLUE    = {0x00,0x00,0xff}
LaunchpadMiniMK3.COLOR_RED     = {0xff,0x00,0x00}
LaunchpadMiniMK3.COLOR_MAGENTA = {0xff,0x00,0xff}
LaunchpadMiniMK3.COLOR_CYAN    = {0x00,0xff,0xff}


function LaunchpadMiniMK3:__init(display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

  self:send_sysex_message(0x00,0x20,0x29,0x02,0x0D,0x0E,0x01)

  -- TODO this device has a full RGB support via the LED lighting SysEx message,
  -- this is a cheap workaround for now, using the color palette...
  self.colorspace = {1, 1, 1}
end

--------------------------------------------------------------------------------

-- clear display before releasing device:
-- all LEDs are turned off, and the mapping mode, buffer settings, 
-- and duty cycle are reset to defaults

function LaunchpadMiniMK3:release()

  -- self:send_cc_message(0,0) 
  self:send_sysex_message(0x00,0x20,0x29,0x02,0x0D,0x0E,0x00)
  MidiDevice.release(self)

end

--------------------------------------------------------------------------------

--- override default Device method
-- @see Device.output_value

function LaunchpadMiniMK3:output_value(pt,xarg,ui_obj)
  if (xarg.type == "button") then
    -- all buttons are colored 

    local color = self:quantize_color(pt.color)
    local rslt = nil

    if cLib.table_compare(color,LaunchpadMiniMK3.COLOR_OFF) then
      rslt = 0
    elseif cLib.table_compare(color,LaunchpadMiniMK3.COLOR_WHITE) then
      rslt = 3
    elseif cLib.table_compare(color,LaunchpadMiniMK3.COLOR_GREEN) then
      rslt = 21
    elseif cLib.table_compare(color,LaunchpadMiniMK3.COLOR_YELLOW) then
      rslt = 13
    elseif cLib.table_compare(color,LaunchpadMiniMK3.COLOR_BLUE) then
      rslt = 45
    elseif cLib.table_compare(color,LaunchpadMiniMK3.COLOR_RED) then
      rslt = 5
    elseif cLib.table_compare(color,LaunchpadMiniMK3.COLOR_MAGENTA) then
      rslt = 81
    elseif cLib.table_compare(color,LaunchpadMiniMK3.COLOR_CYAN) then
      rslt = 37
    end

    --print("pt.color",rprint(pt.color))
    --print("rslt",rslt)
    --rprint(xarg)
    return rslt
  else
    -- otherwise, echo back
    --print("echo back",rprint(pt),MidiDevice.output_value(self,pt,xarg,ui_obj))
    return MidiDevice.output_value(self,pt,xarg,ui_obj)
  end
end

