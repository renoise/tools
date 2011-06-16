--[[----------------------------------------------------------------------------
-- Duplex.Device
----------------------------------------------------------------------------]]--

--[[
Requires: ControlMap

About

The Device class is the base class for any device. Both the MIDIDevice and 
OSCDevice extend this class.

The Device class also contains methods for managing basic device settings

--]]


--==============================================================================

class 'Device'

function Device:__init(name, message_stream, protocol)
  TRACE('Device:__init()',name, message_stream, protocol)

  ---- initialzation
  
  assert(name and message_stream and protocol, 
    "Internal Error. Please report: " ..
    "expected a valid name, stream and protocol for a device")

  -- this is the 'friendly name' of the device
  -- (any/all characters are supported)
  self.name = name

  -- MIDI or OSC?
  self.protocol = protocol  

  -- transmit messages through this stream
  self.message_stream = message_stream

  -- create our control-map
  self.control_map = ControlMap()
  
  
  ---- configuration
  
  -- specify a color-space like this: (r, g, b) or empty
  -- example#1 : {4,4,0} - four degrees of red and grees
  -- example#2 : {1,1,1} - monochrome display (black/white)
  -- example#3 : {0,0,1} - monochrome display (blue)
  -- example#4 : {} - no colors, display as text
  self.colorspace = {}
  
  -- allow sending back the same messages we got from the device as answer 
  -- to the device. some controller which cannot deal with message feedback,
  -- may want to disable this in its device class...
  self.loopback_received_messages = true


  -- private stuff

  self._vb = nil
  self._settings_view = nil
  --self._settings_dialog = nil
  
  
  ---- MIDI port setup changed
  -- 0.95
  --[[
  renoise.Midi.devices_changed_observable():add_notifier(
    Device._available_device_ports_changed, self
  )
  ]]
  
end


--------------------------------------------------------------------------------

function Device:get_protocol()
  TRACE("Device:get_protocol()")

  return self.protocol
end

--------------------------------------------------------------------------------

function Device:set_control_map(xml_file)
  TRACE("Device:set_control_map()",xml_file)
  
  self.control_map.load_definition(self.control_map,xml_file)
end


--------------------------------------------------------------------------------

-- Convert a display/canvas point to an actual value
-- (always overridden with device-specific implementation)

function Device:point_to_value()
  TRACE("Device:point_to_value()")
  return 0
end


--------------------------------------------------------------------------------

function Device:quantize_color(color,colorspace)
  TRACE("Device:quantize_color()",color,colorspace)

  local function quantize_color(value, depth)
    if (depth and depth > 0) then
      assert(depth <= 256, "invalid device colorspace value")
      local a = 256/(depth+1)
      local b = a*(math.floor(value/a))
      return math.min(math.floor(b*256/(256-b)),255)
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


  -- check if monochrome, then apply the average value 
  if (colorspace[1]) then
    local range = math.max(colorspace[1],colorspace[2],colorspace[3])
    if(range<2)then
      local avg = (color[1]+color[2]+color[3])/3
      color = {avg,avg,avg}
    end
  end

  return {
    quantize_color(color[1], colorspace[1]),
    quantize_color(color[2], colorspace[2]),
    quantize_color(color[3], colorspace[3])
  } 
end



--------------------------------------------------------------------------------
--[[
-- returns true when the device settings dialog is visible 

function Device:settings_dialog_visible()
  TRACE("Device:settings_dialog_visible()")

  return (self._settings_dialog and self._settings_dialog.visible)
end
]]

--------------------------------------------------------------------------------

-- open the device settings, includes a reference to the browser so that we
-- can update the browser state when releasing a device
-- @param process : reference to the BrowserProcess

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


    if (self.protocol == DEVICE_MIDI_PROTOCOL) then
      
      -- collect MIDI ports
      
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
      if (self.protocol == DEVICE_MIDI_PROTOCOL) then
        self._vb.views.dpx_device_protocol.text = "Type: MIDI Device"
      elseif (self.protocol == DEVICE_OSC_PROTOCOL) then
        self._vb.views.dpx_device_protocol.text = "Type: OSC Device"
      end
    end


    -- update thumbnail

    local bitmap = "./Duplex/Controllers/unknown.bmp"

    if (self._vb.views.dpx_device_thumbnail_root) then
      -- !!! this is not exactly smart. I want to know the device
      -- folder, so I am extracting the control-map path - but
      -- if the control-map is not located in that folder (which
      -- is quite possible), it will not work...
      
      local extract_device_folder = function(filename)
        local _, _, name, extension = filename:find("(.+)[/\\](.+)$")
        if (name ~= nil) then
          return "./Duplex/" .. name
        end
      end

      local device_path = extract_device_folder(self.control_map.file_path)

      if (process.configuration) and
         (process.configuration.device) and
         (process.configuration.device.thumbnail) 
      then
        local config_bitmap = ("%s/%s"):format(device_path,
          process.configuration.device.thumbnail)
          
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


    if (self.protocol == DEVICE_MIDI_PROTOCOL) then

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

    elseif (self.protocol == DEVICE_OSC_PROTOCOL) then

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

-- construct the device settings view (for both MIDI and OSC devices)

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

--[[
-- handle device hot-plugging (ports changing while Renoise is running)
function Device:_available_device_ports_changed()
  TRACE("Device:_available_device_ports_changed()")

  -- close the device setting dialogs on MIDI port changes 
  -- so we don't have to bother updating them
  
  if (self:settings_dialog_visible()) then
      self:close_settings_dialog()
  end
end
]]
--------------------------------------------------------------------------------

-- construct & send internal messages (for both MIDI and OSC devices)

function Device:_send_message(message,xarg)
  TRACE("Device:_send_message()",message,xarg)

  -- determine input method
  if (xarg.type == "button") then
    message.input_method = CONTROLLER_BUTTON
  elseif (xarg.type == "togglebutton") then
    message.input_method = CONTROLLER_TOGGLEBUTTON
  elseif (xarg.type == "pushbutton") then
    message.input_method = CONTROLLER_PUSHBUTTON
  elseif (xarg.type == "fader") then
    message.input_method = CONTROLLER_FADER
  elseif (xarg.type == "dial") then
    message.input_method = CONTROLLER_DIAL
  else
    error(("Internal Error. Please report: " ..
      "unknown message.input_method %s"):format(xarg.type or "nil"))
  end

  -- include meta-properties
  message.name = xarg.name
  message.group_name = xarg.group_name
  message.max = tonumber(xarg.maximum)
  message.min = tonumber(xarg.minimum)
  message.id = xarg.id
  message.index = xarg.index
  message.column = xarg.column
  message.row = xarg.row
  message.timestamp = os.clock()

  -- send the message
  self.message_stream:input_message(message)
 
  -- immediately update the display after having received a message
  -- to improve response of the display
  if (self.display) then
    self.display:update()
  end

end

--------------------------------------------------------------------------------

function Device:__tostring()
  return type(self)
end  


