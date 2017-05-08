--[[----------------------------------------------------------------------------
-- Duplex.LividBase
----------------------------------------------------------------------------]]--

--[[

Inheritance: LividBase > MidiDevice > Device

A device-specific class 

--]]

--==============================================================================

class "LividBase" (MidiDevice)

LividBase.COLOR_OFF     = {0x00,0x00,0x00}
LividBase.COLOR_WHITE   = {0xff,0xff,0xff}
LividBase.COLOR_GREEN   = {0x00,0xff,0x00}
LividBase.COLOR_YELLOW  = {0xff,0xff,0x00}
LividBase.COLOR_BLUE    = {0x00,0x00,0xff}
LividBase.COLOR_RED     = {0xff,0x00,0x00}
LividBase.COLOR_MAGENTA = {0xff,0x00,0xff}
LividBase.COLOR_CYAN    = {0x00,0xff,0xff}


function LividBase:__init(display_name, message_stream, port_in, port_out)

  -- this device has 1 degree of red, green and blue
  self.colorspace = {1, 1, 1}

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)

end


--------------------------------------------------------------------------------

--- override default Device method
-- @see Device.output_value

function LividBase:output_value(pt,xarg,ui_obj)
  TRACE("LividBase:output_value(pt,xarg,ui_obj)",pt,xarg,ui_obj)


  if (xarg.type == "button") then

    -- all buttons are colored 

    local color = self:quantize_color(pt.color)
    local rslt = nil

    if cLib.table_compare(color,LividBase.COLOR_OFF) then
      rslt = 0
    elseif cLib.table_compare(color,LividBase.COLOR_WHITE) then
      rslt = 1
    elseif cLib.table_compare(color,LividBase.COLOR_GREEN) then
      rslt = 127
    elseif cLib.table_compare(color,LividBase.COLOR_YELLOW) then
      rslt = 64
    elseif cLib.table_compare(color,LividBase.COLOR_BLUE) then
      rslt = 32
    elseif cLib.table_compare(color,LividBase.COLOR_RED) then
      rslt = 16
    elseif cLib.table_compare(color,LividBase.COLOR_MAGENTA) then
      rslt = 8
    elseif cLib.table_compare(color,LividBase.COLOR_CYAN) then
      rslt = 4
    end

    -- print("pt.color",rprint(pt.color))
    -- print("rslt",rslt)
    -- rprint(xarg)

    return rslt

  else

    -- otherwise, echo back
    --print("echo back",rprint(pt),MidiDevice.output_value(self,pt,xarg,ui_obj))
    return MidiDevice.output_value(self,pt,xarg,ui_obj)

  end


end
