--[[----------------------------------------------------------------------------
-- Duplex.Device
----------------------------------------------------------------------------]]--

--[[
Requires: ControlMap

About

The Device class is the base class for any device. Both the MIDIDevice and 
OSCDevice extend this class, just as the Launchpad is based on the MIDIDevice.

The Device class also contains methods for managing the device settings.

--]]


--==============================================================================

class 'Device'

function Device:__init(name, message_stream, protocol)
  TRACE('Device:__init',name, message_stream, protocol)

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

  self.__vb = nil
  self.__settings_view = nil
  self.__settings_dialog = nil
end


--------------------------------------------------------------------------------

function Device:get_protocol()
  return self.protocol
end


--------------------------------------------------------------------------------

function Device:set_control_map(xml_file)
  TRACE("Device:set_control_map:",xml_file)
  
  self.control_map.load_definition(self.control_map,xml_file)
end


--------------------------------------------------------------------------------

-- Convert a display/canvas point to an actual value
-- (always overridden with device-specific implementation)

function Device:point_to_value()
  return 0
end


--------------------------------------------------------------------------------

-- returns true when the device settings dialog is visible 

function Device:settings_dialog_visible()
  return (self.__settings_dialog and self.__settings_dialog.visible)
end


--------------------------------------------------------------------------------

-- open the device settings, includes a reference to the browser so that we
-- can update the browser state when releasing a device
-- @param process : reference to the BrowserProcess

function Device:show_settings_dialog(process)

  -- already visible? bring to front...
  if (self.__settings_dialog and self.__settings_dialog.visible) then
    self.__settings_dialog:show()
    return    
  end


  -- create the config view skeleton
  
  self.__settings_view = self:__build_settings()
  
  
  -- and populate it with contents from the browser process / config

  if (process) then

    if (self.protocol == DEVICE_MIDI_PROTOCOL) then
      
      -- collect MIDI ports
      
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

      
      -- match name
      
      if (self.__vb.views.dpx_device_name) then
        if (process.configuration) and
           (process.configuration.device) and
           (process.configuration.device.display_name) 
        then
          self.__vb.views.dpx_device_name.text = 
            process.configuration.device.display_name
        end
      end

      
      -- update type text
      
      if (self.__vb.views.dpx_device_protocol) then
        self.__vb.views.dpx_device_protocol.text = "Type: MIDI Device"
      end


      -- update thumbnail

      if (self.__vb.views.dpx_device_thumbnail_root) then
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
  
        local bitmap = "./Duplex/Controllers/unknown.bmp"
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
        
        self.__vb.views.dpx_device_thumbnail_root:add_child(
          self.__vb:bitmap{
            bitmap = bitmap
          }
        )
      end


      -- match input port

      if (self.__vb.views.dpx_device_midi_in_root) then
        local port_idx
        
        for k,v in ipairs(ports_in) do
          if (v == process.device.port_in) then
            port_idx = k
            break
          end
        end
        
        local view = self.__vb:popup {
          id = "dpx_device_midi_in",
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
              self.port_in = self.__vb.views.dpx_device_midi_in.items[idx]
              process.settings.device_port_in.value = self.port_in
              
              if (self.port_out) then               
                
                -- open the new device
                self:open() -- assumes MidiDevice class 

                -- and restart the process to reactivate & refresh
                if (process:running()) then
                  process:stop()
                  process:start()
                end
              end
            end
          end
        }
        
        self.__vb.views.dpx_device_midi_in_root:add_child(view)
      end
      
      
      -- match output port
      
      if (self.__vb.views.dpx_device_midi_out_root) then
        local port_idx
        
        for k,v in ipairs(ports_out) do
          if (v == process.device.port_out) then
            port_idx = k
            break
          end
        end
        
        local view = self.__vb:popup {
          id = "dpx_device_midi_out",
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
              self.port_out = self.__vb.views.dpx_device_midi_out.items[idx]
              process.settings.device_port_out.value = self.port_out
              
              if (self.port_in) then 
                -- open the new device
                self:open() -- assumes MidiDevice class 
                
                -- and restart the process to reactivate & refresh
                if (process:running()) then
                  process:stop()
                  process:start()
                end
              end
            end
          end
        }

        self.__vb.views.dpx_device_midi_out_root:add_child(view)
      end
    
    elseif (self.protocol == DEVICE_OSC_PROTOCOL) then
      -- TODO: OSC settings
    end
  end


  -- and finally show the new dialog
  
  self.__settings_dialog = renoise.app():show_custom_dialog(
    "Duplex: Device Settings", self.__settings_view)
end  


--------------------------------------------------------------------------------

-- close the device settings, when open

function Device:close_settings_dialog()
  if (self.__settings_dialog and self.__settings_dialog.visible) then
    self.__settings_dialog:close()
  end

  self.__settings_dialog = nil
end
  
  
--------------------------------------------------------------------------------

-- construct the device settings dialog (for both MIDI and OSC devices)

function Device:__build_settings()
  
  -- new settings, new view_builder...
  self.__vb = renoise.ViewBuilder()  
  local vb = self.__vb


  local view = vb:column{
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
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
            text = "Type: MIDI Device",
          },
          -- list device IO setup here (MIDI or OSC)
          vb:column {
            id = "dpx_device_settings_midi",
            vb:row {
              id = "dpx_device_midi_in_root",
              vb:text {
                width = 30,
                text = "In",
              },
              -- popup added here
            },
            vb:row {
              id = "dpx_device_midi_out_root",
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

function Device:__tostring()
  return type(self)
end  


