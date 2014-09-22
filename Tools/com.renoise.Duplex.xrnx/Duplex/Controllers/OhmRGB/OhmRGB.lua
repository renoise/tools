--[[----------------------------------------------------------------------------
-- Duplex.OhmRGB
----------------------------------------------------------------------------]]--

--[[

Inheritance: OhmRGB > MidiDevice > Device

A device-specific class 

--]]


--==============================================================================

class "OhmRGB" (MidiDevice)

function OhmRGB:__init(display_name, message_stream, port_in, port_out)
  TRACE("OhmRGB:__init", display_name, message_stream, port_in, port_out)

  MidiDevice.__init(self, display_name, message_stream, port_in, port_out)


  self.colorspace = {1,1,1}

end


--------------------------------------------------------------------------------

--- override default Device method
-- @see Device.output_value

function OhmRGB:output_value(pt,xarg,ui_obj)
  TRACE("OhmRGB:output_value(pt,xarg,ui_obj)",pt,xarg,ui_obj)
  
  --if xarg.skip_echo then
    --- parameter only exist in the virtual ui
  --  return Device.output_value(self,pt,xarg,ui_obj)
  --else


    -- match with default CC value
    -- (see also http://wiki.lividinstruments.com/wiki/OhmRGB#22_:_Color_Map)

    local color = self:quantize_color(pt.color)
    --print("OhmRGB quantized color...",rprint(color))

    local rslt = nil

    if (color[1] == 0x00) then
      if (color[2] == 0x00) then
        if (color[3] == 0x00) then
          return 0  -- 0x000000/OFF
        else
          return 32 -- 0x0000FF/BLUE
        end
      else
        if (color[3] == 0x00) then
          return 127  -- 0x00FF00/GREEN
        else
          return 4  -- 0x00FFFF/CYAN
        end
      end
    else
      if (color[2] == 0x00) then
        if (color[3] == 0x00) then
          return 16  -- 0xFF0000/RED
        else
          return 8 -- 0xFF00FF/MAGENTA
        end
      else
        if (color[3] == 0x00) then
          return 64  -- 0xFFFF00/YELLOW
        else
          return 1  -- 0xFFFFFF/WHITE
        end
      end
    end

    if rslt then
      return rslt
    else
      error ("Attempted to set unsupported color for the Livid OhmRGB")
    end


  --end


end



