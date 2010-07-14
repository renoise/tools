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

  self.__vb = renoise.ViewBuilder()
  self.__settings_view = nil
  self.__settings_dialog = nil
  self.__browser_ref = nil

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

-- open the device settings, includes a reference to the browser so that we
-- can update the browser state when releasing a device

function Device:show_settings_dialog(browser_ref)

  self.__browser_ref = browser_ref

  if not self.__settings_dialog then
    self.__settings_view = self:__build_settings()
    self.__settings_dialog = renoise.app():show_custom_dialog(
      "Duplex: Device Settings",self.__settings_view)
  end

  self.__settings_dialog:show()

end  

--------------------------------------------------------------------------------

-- construct the device settings (both MIDI and OSC devices are supported)

function Device:__build_settings()
  
  local vb = self.__vb

  -- MIDI device setup
  local ports,port_idx,channels
  if (self.protocol == DEVICE_MIDI_PROTOCOL) then

    ports = table.create{"None"}
    port_idx = nil

    channels = {"All",
      "#1","#2","#3","#4",
      "#5","#6","#7","#8",
      "#9","#10","#11","#12",
      "#13","#14","#15","#16"}

    -- gather information about MIDI ports 
    local tmp = renoise.Midi.available_input_devices()
    for k,v in ipairs(tmp) do
      ports:insert(v)
      if (v==self.name) then
        port_idx = k+1
      end
    end

  end

  local controlmaps = self:__collect_control_maps()

  local view = vb:column{
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
    width=300,
    vb:row{
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      vb:row{
        style = "plain",
        --height = 180,
        vb:bitmap{
          bitmap = "./Duplex/Controllers/Launchpad/Launchpad.bmp"
        }
      },
      vb:row{
        style = "group",
        width = "100%",
        margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
        vb:column{
          vb:text{
            font = "bold",
            text = "Novation Launchpad",
          },
          vb:text{
            text = "Type: MIDI Device",
          },
          -- list device IO setup here (MIDI or OSC)
          vb:column{
            id="dpx_device_settings_midi",
            vb:row{
              vb:text{
                text = "Port",
              },
              vb:popup{
                items = ports,
                value = port_idx,
                notifier = function()
                  -- release, then open the device
                end

              },
              vb:button{
                text = "Release",
                notifier = function()
                  -- release the device, and update browser
                end
              }
            },
            vb:row{
              vb:text{
                text = "Channel",
              },
              vb:popup{
                width = 61,
                items = channels,
                value = 1
              }
            }
          
          }
        }
      },
    },
    vb:row{
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      style = "group",
      width = "100%",

      vb:column{

        vb:row{
          width = "100%",
          spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
          vb:text{
            width = 40,
            text = "Config",
            font = "bold",
          },
          vb:popup{
            -- list configurations here
            items = {"Matrix","Mixer","Matrix + Mixer"},
            value = 3,
            width = 150,
          },
          vb:button{
            text = "+",
          },
          vb:button{
            text = "-",
          },
        },

        vb:row{
          width = "100%",
          spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
          vb:space{
            width = 40,
          },
          vb:checkbox{
            value = false,
          },
          vb:text{
            text = "Autostart configuration",
          },
        },

      },

    },
    vb:row{
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      style = "group",
      width = "100%",

      vb:row{
        width = "100%",
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        vb:text{
          width = 80,
          text = "Control-map",
          font = "bold",
        },
        vb:popup{
          --width = 150,
          items = controlmaps,
          value = 1,
        },
        vb:button{
          text = "About",
        },

      }
    },
    vb:row{
      spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
      margin = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN,
      style = "group",
      width = "100%",
      vb:column{
        width = "100%",
        spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
        vb:row{
          width = "100%",
          spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,
          vb:text{
            width = 80,
            text = "Applications",
            font = "bold",
          },
          vb:button{
            text = "+",
          },
          vb:button{
            text = "-",
          },
        },
        -- add running applications here
        vb:multiline_text{
          width = 200,
          height = 40,
          text = "Nothing to display. Hit the plus sign to add an application to this device",
        },

        vb:row{
          width = "100%",
          vb:button{
            text = "Matrix",
            width = 200,
          },
          -- applications options
          vb:text{
            text = "Displaying Matrix...",
            visible = false,
          },

        },
        vb:row{
          width = "100%",
          vb:button{
            text = "Mixer",
            width = 200,
            --color = {0x01,0x01,0x01}
          },
          -- applications options
          vb:text{
            text = "Displaying Mixer...",
            visible = false,
          },

        },
      
      },
    },

  }  

  return view

end

--------------------------------------------------------------------------------

-- collect all control-maps in the device folder (files ending with .xml)
-- we extract the device folder name from the control-map path

function Device:__collect_control_maps()

  local rslt = table.create()

  local extract_device_folder = function(filename)
    local _, _, name, extension = filename:find("(.+)%/(.+)$")
    if (name ~= nil) then
      return "./Duplex/"..name
    end
  end

  local device_path = extract_device_folder(self.control_map.file_path)

  for _, filename in pairs(os.filenames(device_path, "*.xml")) do
    rslt:insert(filename)
  end

  return rslt

end

--------------------------------------------------------------------------------

function Device:__tostring()
  return type(self)
end  


