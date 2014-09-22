--[[============================================================================
-- Duplex.Device
============================================================================]]--

--[[--

The Device class is the base class for any OSC or MIDI device. 
It also contains methods for managing basic device settings


### Changes

  0.99.4
    - Changed the interpretation of "colorspace": monochrome devices are 
      now specified as {1} instead of {1,1,1}

  0.99.2
    - output_to_value now split into submethods (output_number/boolean/text)
      (including ability to produce completely custom output to device)

  0.9
    - First release


--]]

--==============================================================================

class 'Device'

--------------------------------------------------------------------------------

--- Initialize the Device class
-- @param name (String) the 'friendly name' of the device
-- @param message_stream (@{Duplex.MessageStream}) 
-- @param protocol (@{Duplex.Globals.DEVICE_PROTOCOL})

function Device:__init(name, message_stream, protocol)
  TRACE('Device:__init()',name, message_stream, protocol)

  assert(name and message_stream and protocol, 
    "Internal Error. Please report: " ..
    "expected a valid name, stream and protocol for a device")

  --- this is the 'friendly name' of the device
  -- (any/all characters are supported)
  self.name = name

  --- MIDI or OSC?
  self.protocol = protocol  

  --- transmit messages through this stream
  self.message_stream = message_stream

  --- create our control-map
  self.control_map = ControlMap()
  
  
  ---- configuration
  
  --- (@{Duplex.Globals.PARAM_MODE}) the default parameter mode
  self.default_parameter_mode = "abs"

  --- specify a color-space like this: (r, g, b) or empty
  --    example#1 : {4,4,0} - four degrees of red and green (Launchpad)
  --    example#3 : {1,1,1} - one degree of red/green/blue (Ohm RGB)
  --    example#3 : {0,0,1} - monochrome display (with blue LEDs)
  --    example#4 : {1} - monochrome (black and white)
  --    example#4 : {} - none (using 'theme color' instead)
  if not self.colorspace then
    self.colorspace = {}
  end
  
  --- allow sending back the same messages we got from the device as answer 
  -- to the device. some controller which cannot deal with message feedback,
  -- may want to disable this in its device class...(see also "skip_echo", which 
  -- is similar but per-parameter instead of being set for the whole device)
  self.loopback_received_messages = true

  --- allow Duplex to transmit MIDI note-on messages with zero velocity 
  -- (normally, such a message is converted to note-off just before being sent)
  self.allow_zero_velocity_note_on = false

  --- (bool) feedback prevention: when connected to an external source that 
  -- simply echoes anything back, this will help us avoid getting bogged down
  -- ignore messages that bounce back within a certain time window - 
  -- only applies to messages that can be reconstructed (no wildcards)
  self.feedback_prevention_enabled = false

  --- (bool) memoize previously matched parameters (more efficient)
  self.parameter_caching = true

  ---- private members

  --- (table) indexed table of the most recent messages, stored as strings...
  -- (This is part of a simple mechanism for avoiding message feedback)
  self._feedback_buffer = {}

  --- renoise.Viewbuilder
  self._vb = nil

  --- renoise.Views.View
  self._settings_view = nil
  
  
end


--------------------------------------------------------------------------------

--- Retrieve the protocol of this device.
-- @return @{Duplex.Globals.DEVICE_PROTOCOL}

function Device:get_protocol()
  TRACE("Device:get_protocol()")

  return self.protocol
end

--------------------------------------------------------------------------------

--- Set the device to the provided control-map, including memoizing 
-- of patterns (making pattern-matching a lot more efficient)
-- @param xml_file (String) path to file

function Device:set_control_map(xml_file)
  TRACE("Device:set_control_map()",xml_file)
  
  local cm = self.control_map
  cm.load_definition(self.control_map,xml_file,self)
  cm:memoize()

end


--------------------------------------------------------------------------------

--- Function for quantizing RGB color values to a device color-space.
-- @param color (table), RGB colors
-- @param colorspace (table), colorspace
-- @return (table), the quantized color

function Device:quantize_color(color,colorspace)
  TRACE("Device:quantize_color()",color,colorspace)

  local function quantize_color(value, depth)
    if (depth and depth > 0) then
      assert(depth <= 256, "invalid device colorspace value, should be between 1 - 256")
      return math.min(255,math.floor(((value+1)/256)*depth)*( 256/depth))
    else
      return 0
    end
  end

  -- apply optional colorspace, or use device default
  colorspace = colorspace or self.colorspace

  -- if there's no colorspace, return original color
  if table.is_empty(colorspace) then
    return {color[1],color[2],color[3]}
  end


  -- if monochrome, average color above 50% is considered lit
  if ((#colorspace==1) and (colorspace[1] == 1)) then
    local avg = (color[1]+color[2]+color[3])/3
    if (avg > 0x80) then 
      return {0xff,0xff,0xff}
    else
      return {0x00,0x00,0x00}
    end
  end

  return {
    quantize_color(color[1], colorspace[1]),
    quantize_color(color[2], colorspace[2]),
    quantize_color(color[3], colorspace[3])
  } 
end


--------------------------------------------------------------------------------

function Device:collect_midi_ports()

  local ports_in = table.create{"None"}
  local ports_out = table.create{"None"}

  local input_devices = renoise.Midi.available_input_devices()
  local output_devices = renoise.Midi.available_output_devices()

  for k,v in ipairs(input_devices) do
    ports_in:insert(v)
  end

  for k,v in ipairs(output_devices) do
    ports_out:insert(v)
  end

  return ports_in,ports_out

end

--------------------------------------------------------------------------------

--- Open the device settings dialog.
-- @param process (@{Duplex.BrowserProcess}) 

function Device:show_settings_dialog(process)
  TRACE("Device:show_settings_dialog()",process)

  -- create the config view skeleton
  self._settings_view = self:_build_settings()
  
  
  -- and populate it with contents from the browser process / config
  local ports_in,ports_out,input_devices,output_devices 

  if (process) then

    local restart_process = function()
      self:open() -- assumes MIDI or OscDevice class 
      -- restart the process to reactivate & refresh
      if (process:running()) then
        process:stop()
        process:start()
      end
    end


    if (self.protocol == DEVICE_PROTOCOL.MIDI) then
      
      -- collect MIDI ports
      
      ports_in,ports_out = Device.collect_midi_ports()

      --[[
      ports_in = table.create{"None"}
      ports_out = table.create{"None"}

      input_devices = renoise.Midi.available_input_devices()
      output_devices = renoise.Midi.available_output_devices()

      for k,v in ipairs(input_devices) do
        ports_in:insert(v)
      end

      for k,v in ipairs(output_devices) do
        ports_out:insert(v)
      end
      ]]

    end
      
    -- match name
    
    if (self._vb.views.dpx_device_name) then
      if (process.configuration) and
         (process.configuration.device) and
         (process.configuration.device.display_name) 
      then
        self._vb.views.dpx_device_name.text = 
          process.configuration.device.display_name
      end
    end

    
    -- update "device type" text
    
    if (self._vb.views.dpx_device_protocol) then
      if (self.protocol == DEVICE_PROTOCOL.MIDI) then
        self._vb.views.dpx_device_protocol.text = "Type: MIDI Device"
      elseif (self.protocol == DEVICE_PROTOCOL.OSC) then
        self._vb.views.dpx_device_protocol.text = "Type: OSC Device"
      end
    end


    -- update thumbnail

    local bitmap = "./Duplex/Controllers/unknown.bmp"

    if (self._vb.views.dpx_device_thumbnail_root) then

      if (process.configuration) and
         (process.configuration.device) and
         (process.configuration.device.thumbnail) 
      then
        local config_bitmap = "./Duplex/" .. 
          process.configuration.device.thumbnail

        if (io.exists(config_bitmap)) then
          bitmap = config_bitmap
        else
          renoise.app():show_warning(
            ("Whoops! Device thumbnail '%s' does not exist. Please fix the "..
             "thumbnail filename, or do not specify a thumbnail property in "..
             "the configuration."):format(config_bitmap))
        end
      end
      
    end
    self._vb.views.dpx_device_thumbnail_root:add_child(
      self._vb:bitmap{
        bitmap = bitmap
      }
    )


    if (self.protocol == DEVICE_PROTOCOL.MIDI) then

      -- match input port

      if (self._vb.views.dpx_device_port_in_root) then
        local port_idx
        
        for k,v in ipairs(ports_in) do
          if (v == process.device.port_in) then
            port_idx = k
            break
          end
        end
        
        local view = self._vb:popup {
          id = "dpx_device_port_in",
          width = 150,
          items = ports_in,
          value = port_idx,

          notifier = function(idx)
            -- release, then re-open the device
            self:release() -- assumes MidiDevice class

            if (idx == 1) then
              self.port_in = nil -- none
              process.settings.device_port_in.value = ""

            else
              self.port_in = self._vb.views.dpx_device_port_in.items[idx]
              process.settings.device_port_in.value = self.port_in
              if (self.port_out) then               
                restart_process()
              end
            end
          end
        }
        
        self._vb.views.dpx_device_port_in_root:add_child(view)
      end
      
      
      -- match output port
      
      if (self._vb.views.dpx_device_port_out_root) then
        local port_idx
        
        for k,v in ipairs(ports_out) do
          if (v == process.device.port_out) then
            port_idx = k
            break
          end
        end
        
        local view = self._vb:popup {
          id = "dpx_device_port_out",
          width = 150,
          items = ports_out,
          value = port_idx,
          
          notifier = function(idx)
            -- release, then re-open the device
            self:release() -- assumes MidiDevice class
            
            if (idx == 1) then
              self.port_out = nil -- none
              process.settings.device_port_out.value = ""
              
            else
              self.port_out = self._vb.views.dpx_device_port_out.items[idx]
              process.settings.device_port_out.value = self.port_out
              
              if (self.port_in) then 
                 restart_process()
              end

            end
          end
        }

        self._vb.views.dpx_device_port_out_root:add_child(view)
      end

    elseif (self.protocol == DEVICE_PROTOCOL.OSC) then

      -- input port + address

      local view = self._vb:row{
        self._vb:valuebox {
          id = "dpx_device_port_in",
          width = 70,
          min = 1024, -- minimum allowed value for *nix based systems
          max = 50000,
          value = self.port_in,
          
          notifier = function(idx)
            -- release, then re-open the device
            self:release()
            
            self.port_in = self._vb.views.dpx_device_port_in.value
            process.settings.device_port_in.value = tostring(self.port_in)
            
            restart_process()
          end
        },
        self._vb:space{
          width = 6
        },
        self._vb:text{
          text = "Address",
          width = 50
        },
        self._vb:textfield {
          id = "dpx_device_address",
          width = 70,
          value = self.address,
          
          notifier = function()
            -- release, then re-open the device
            self:release()
            
            self.address = self._vb.views.dpx_device_address.value
            process.settings.device_address.value = self.address

            restart_process()
          end
        }
      }

      self._vb.views.dpx_device_port_in_root:add_child(view)

      -- output port
      local view = self._vb:row{
        self._vb:valuebox {
          id = "dpx_device_port_out",
          width = 70,
          min = 1024, -- minimum allowed value for *nix based systems
          max = 50000,
          value = self.port_out,
          
          notifier = function()
            -- release, then re-open the device
            self:release()
            
            self.port_out = self._vb.views.dpx_device_port_out.value
            process.settings.device_port_out.value = tostring(self.port_out)

            restart_process()
          end
        },
        self._vb:space{
          width = 6
        },
        self._vb:text{
          text = "Prefix",
          width = 50
        },
        self._vb:textfield {
          id = "dpx_device_prefix",
          width = 70,
          value = self.prefix,
          
          notifier = function()
            -- release, then re-open the device
            self:release()
            
            -- set_device_prefix() is called when re-opening the device,
            -- so we simply set the prefix to the new value here...
            self.prefix = self._vb.views.dpx_device_prefix.value
            process.settings.device_prefix.value = self.prefix
            
            restart_process()
          end
        }
      }

      self._vb.views.dpx_device_port_out_root:add_child(view)
    end

  end

end  

  
--------------------------------------------------------------------------------

--- Construct the device settings view (for both MIDI and OSC devices).
-- @return renoise.ViewBuilder.view

function Device:_build_settings()
  TRACE("Device:_build_settings()")

  -- new settings, new view_builder...
  self._vb = renoise.ViewBuilder()  
  local vb = self._vb


  local view = vb:column{
    --margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    --spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    width = 300,

    vb:row {
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      vb:row {
        id = "dpx_device_thumbnail_root",
        style = "plain",
        -- bitmap is added here
      },
      vb:space { 
        width = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING 
      },
      vb:row {
        style = "group",
        margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
        vb:column {
          vb:text {
            id = "dpx_device_name",
            font = "bold",
            text = "Device name",
          },
          vb:text {
            id = "dpx_device_protocol",
            text = "",
          },
          -- list device IO setup here (MIDI or OSC)
          vb:column {
            id = "dpx_device_settings_midi",
            vb:row {
              id = "dpx_device_port_in_root",
              vb:text {
                width = 30,
                text = "In",
              },
              -- popup added here
            },
            vb:row {
              id = "dpx_device_port_out_root",
              vb:text {
                width = 30,
                text = "Out",
              },
              -- popup added here
            },
          }
        }
      }
    }
  }  

  return view
end

--------------------------------------------------------------------------------

--- Construct & send internal messages (for both MIDI and OSC devices).
-- this function is invoked by the device class when a new message is received, 
-- and will populate the message with properties that are device-independent
-- before sending it off to the @{Duplex.MessageStream}
-- 
-- @param msg (@{Duplex.Message}) passed on from the device class
-- @param param (table) `Param` node attributes, see @{Duplex.ControlMap}
-- @param regex (table) regex matches, see @{Duplex.ControlMap.get_osc_params}

function Device:_send_message(msg,param,regex)
  --TRACE("Device:_send_message()",msg,param)
  --TRACE("Device:_send_message()",rprint(param.xarg))

  msg.timestamp = os.clock()
  msg.device = self
  msg.xarg = param.xarg

  local widget_hook = widget_hooks[param.xarg.type]
  if widget_hook and widget_hook.on_receive then
    widget_hook.on_receive(self,param,msg,regex)
  end

  -- send the message
  self.message_stream:input_message(msg)
 
  -- immediately update after having received a message,
  -- to improve the overall response time of the display
  if (self.display) then
    self.display:update("immediate")
  end

end

--------------------------------------------------------------------------------

--- Convert values into a something that the display & device can understand. 
--
-- Each type of value (number, boolean or text) is handled by a specific 
-- submethod: @{output_number}, @{output_boolean}, @{output_text}
-- 
-- Numbers are generally used for dials and faders, booleans are 
-- used for objects with an on/off state (buttons), and text is used for 
-- things like labels and segmented displays 
--
-- Depending on the device, you might want to override these submethods with 
-- your own implementation. For example, the Launchpad has it's own method for 
-- converting a value into a color. You can also implement your own code for 
-- direct communication with the device by overriding these methods - 
-- in such a case, adding an additional boolean return value ("skip_hardware") 
-- will update the virtual display, but skip the hardware part
--
-- @param pt (@{Duplex.CanvasPoint})
-- @param xarg (table), control-map parameter
-- @param ui_obj (@{Duplex.UIComponent})
-- @return number, table or text (the value output to the display/device)
-- @return bool (skip_hardware)

function Device:output_value(pt,xarg,ui_obj)
  TRACE("Device:output_value()",pt,xarg,ui_obj)

  local value,skip_hardware = nil,false
  local val_type = type(pt.val)

  --print("*** Device:output_value - val_type",val_type)
  --print("*** Device:output_value - self",self)
  --print("*** Device:output_value - ui_obj",ui_obj)
  --print("*** Device:output_value - pt.val",rprint(pt.val))
  --print("*** Device:output_value - pt.val",rprint(xarg))

  if (val_type == "number") then
    value,skip_hardware = self:output_number(pt,xarg,ui_obj)

  elseif (val_type == "boolean") then
    value,skip_hardware = self:output_boolean(pt,xarg,ui_obj)

  elseif (val_type == "string") then
    value,skip_hardware = self:output_text(pt,xarg,ui_obj)

  elseif (val_type == "table") then

    -- when the value is a table, we iterate through each value 
    -- and call the appropriate methods. 

    value = table.create()
    for _,v in ipairs(pt.val) do

      local pt2 = {
        text = pt.text,
        color = pt.color,
        val = v,
      }

      local value2,skip2 = nil,false
      local val_type2 = type(v)

      if (val_type2 == "number") then
        value2,skip2 = self:output_number(pt2,xarg,ui_obj)

      elseif (val_type2 == "boolean") then
        value2,skip2 = self:output_boolean(pt2,xarg,ui_obj)

      elseif (val_type2 == "text") then
        value2,skip2 = self:output_text(pt2,xarg,ui_obj)

      end
      value:insert(value2)

      if (skip2) then
        skip_hardware = true
      end

    end

    --print("*** output_value (table)")
    --rprint(value)

  end

  return value,skip_hardware

end

--------------------------------------------------------------------------------

--- output a text-based value (e.g. for segmented text displays)
-- @param pt (@{Duplex.CanvasPoint})
-- @param xarg (table), control-map parameter
-- @param ui_obj (@{Duplex.UIComponent})
-- @see Device.output_value

function Device:output_text(pt,xarg,ui_obj)
  TRACE("Device:output_text(pt,xarg,ui_obj)",pt,xarg,ui_obj)

  return pt.val

end

--------------------------------------------------------------------------------

--- represents a button's lit state and will output either min or max
-- (only relevant for basic, monochrome buttons)
-- @param pt (@{Duplex.CanvasPoint})
-- @param xarg (table), control-map parameter
-- @param ui_obj (@{Duplex.UIComponent})
-- @see Device.output_value

function Device:output_boolean(pt,xarg,ui_obj)
  TRACE("Device:output_boolean(pt,xarg,ui_obj)",pt,xarg,ui_obj)

  if (pt.val==true) then
    return xarg.maximum
  else
    return xarg.minimum
  end

end

--------------------------------------------------------------------------------

--- scale a numeric value from our UIComponent range to the range of the 
-- external device (for example, from decibel to 0-127)
-- @param pt (@{Duplex.CanvasPoint})
-- @param xarg (table), control-map parameter
-- @param ui_obj (@{Duplex.UIComponent})
-- @see Device.output_value

function Device:output_number(pt,xarg,ui_obj)
  TRACE("Device:output_number(pt,xarg,ui_obj)",pt,xarg,ui_obj)
  --print("pt.val,ui_obj.floor,ui_obj.ceiling,xarg.minimum,xarg.maximum",pt.val,ui_obj.floor,ui_obj.ceiling,xarg.minimum,xarg.maximum)

  return scale_value(pt.val,ui_obj.floor,ui_obj.ceiling,xarg.minimum,xarg.maximum)

end

--------------------------------------------------------------------------------

function Device:__tostring()
  return type(self)
end  


