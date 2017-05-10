--[[============================================================================
-- Duplex.Options
============================================================================]]--

--[[--

-- The Duplex tool-options dialog 

--]]

--==============================================================================

class 'Options'

--------------------------------------------------------------------------------

function Options:__init()

  self._vb = renoise.ViewBuilder()
  self._content_view = nil
  self._dialog = nil

  self.browser = nil

  -- build the GUI
  -------------------------------------
  self:_create_content_view()

end

--------------------------------------------------------------------------------

function Options:show()
  --LOG("main:show_dialog()",config, start_running)

  -- already visible? bring to front...
  if (self._dialog and self._dialog.visible) then
    self._dialog:show()
    return    
  end

  if (not self._dialog or not self._dialog.visible) then
    self._dialog = renoise.app():show_custom_dialog("Duplex Options",self._content_view)
  else 
    self._dialog:show()
  end

end

--------------------------------------------------------------------------------

function Options:_create_content_view()

  local vb = self._vb

  self._content_view = vb:column{
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_SPACING,
    width = 180,

    vb:row{
      vb:button{
        text = "Show Duplex Browser...",
        width = 180,
        notifier = function()
          show_duplex_browser() -- defined in main.lua
        end
      },

    },
    vb:column{
      style = "group",
      width = "100%",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,      
      vb:text{
        text = "Launch options",
        font = "bold",
      },
      vb:row{
        vb:checkbox{
          bind = duplex_preferences.display_browser_on_start,
        },
        vb:text{
          text = "Display Browser on startup"
        }
      },

    },

    vb:column{
      style = "group",
      width = "100%",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,      
      vb:text{
        text = "MIDI & Recording",
        font = "bold",
      },
      vb:row{
        vb:checkbox{
          bind = duplex_preferences.highres_automation,
        },
        vb:text{
          text = "High-res automation"
        }
      },
      vb:row{
        vb:checkbox{
          bind = duplex_preferences.mmc_transport_enabled,
        },
        vb:text{
          text = "Enable MMC transport"
        }
      },
    },

    vb:column{
      style = "group",
      width = "100%",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,    
      vb:text{
        text = "Internal OSC server",
        font = "bold",
      },
      vb:row{
        vb:text{
          text = "Protocol",
          width = 50,
        },
        vb:text{
          text = "Udp only",
          width = 50,
          font = "italic",
        },
      },
      vb:row{
        vb:text{
          text = "Host",
          width = 50,
        },
        vb:textfield{
          bind = duplex_preferences.osc_server_host,
          width = 108,
        },
      },
      vb:row{
        vb:text{
          text = "Port",
          width = 50,
        },
        vb:valuebox{
          width = 96,
          bind = duplex_preferences.osc_server_port,
          min = xOscClient.MIN_PORT,
          max = xOscClient.MAX_PORT,
        },
      },
      vb:row{
        vb:button{
          text = "Test now",
          notifier = function()
            if self.browser then
              local obs = self.browser._osc_client._test_passed_observable
              if not obs:has_notifier(passed_osc_test) then
                obs:add_notifier(passed_osc_test)  
              end
              self.browser:run_server_test()
            else
              renoise.app():show_message("Please show the browser before testing")
            end
          end,
        },        
        vb:checkbox{
          bind = duplex_preferences.run_server_test,
        },
        vb:text{
          text = "Check on startup"
        }
      },
      
    },

    -- debug and logging 
    vb:column{
      style = "group",
      width = "100%",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,      
      vb:text{
        text = "Debug & logging",
        font = "bold",
      },
      vb:row{
        vb:checkbox{
          bind = duplex_preferences.dump_midi,
          
        },
        vb:text{
          text = "Dump MIDI to console"
        }
      },
      vb:row{
        vb:checkbox{
          bind = duplex_preferences.dump_osc,
        },
        vb:text{
          text = "Dump OSC to console"
        }
      },
    },

    -- links and resources 
    vb:column{
      style = "group",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,      
      vb:text{
        text = "Links & Resources",
        font = "bold",
      },
      vb:column{
        vb:button{
          text = "Source & Documentation",
          width = 170,
          notifier = function()
            renoise.app():open_url("https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.Duplex.xrnx")
          end,
        },
        vb:button{
          text = "Discussion & Bug Reports",
          width = 170,
          notifier = function()
            renoise.app():open_url("http://forum.renoise.com/index.php?/topic/27886-duplex-beta-versions/")
          end,
        },

      },
    },
    

  }

end
