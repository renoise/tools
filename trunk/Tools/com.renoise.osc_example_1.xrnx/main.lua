--[[============================================================================
gui.lua
============================================================================]]--

local client = nil
local note_map_dialog = nil
local OscMessage = renoise.Osc.Message
local host = "localhost"
local port = 8000
local protocol = renoise.Socket.PROTOCOL_TCP

--[[
Take care your OSC server in the Renoise preferences is set to port 8000, using TCP
Or simply change the above host, port and protocol parameters to match your Renoise 
OSC server settings.
]]--

--------------------------------------------------------------------------------
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:OSC example...",
  invoke = function() 
     main_dialog()
  end
}

function main_dialog()
 
  local vb = renoise.ViewBuilder()
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN



  local TEXT_ROW_WIDTH = 80
  local title = "OSC example" 
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = 5,

    vb:row {
      style = 'group',
      margin = DEFAULT_MARGIN,

      vb:text {
        width = 40,
        text = "Loop mode"
      },

      vb:button {
        width = 40,
        text = "Block Loop on",
        notifier = function()
          set_block_loop("T")
        end
      },
      vb:button {
        width = 40,
        text = "Block Loop off",
        notifier = function()
          set_block_loop("F")
        end
      },

    },

  }  

  if not note_map_dialog or not note_map_dialog.visible then
    note_map_dialog = renoise.app():show_custom_dialog(
      title, dialog_content)
  else
    note_map_dialog:show()
  end

  
end

function set_block_loop(mode)
  if client == nil then
    connect_to_server()
  end
  
  local o_message = OscMessage(
    "/renoise/transport/loop/block",{
      {tag=mode}
    }
  )
  
  
  if o_message ~= nil and client ~= nil then
    if client.is_open == true then
      client:send(o_message)
    end
  end
  
  
end


function connect_to_server()
  local client_error = nil
  
  client, client_error = renoise.Socket.create_client(host, port, protocol)
  
  if client ~= nil then

    if client.is_open then

      print("Server connected")
    else

     
      if client_error then

        local err_msg = "Could not connect to server reason: ["..client_error.."]\n\nPlease check your network connection and try again "
        local choice = renoise.app():show_prompt("Network error",err_msg,{'close'})

      end

    end

  else

    local cl_err = "Client connection-establishment failed."

    if client_error ~= nil then
      cl_err = client_error
    end

    local err_msg = "Could not connect to server reason: "..cl_err.."\n\nPlease check your network connection and try again "
    local choice = renoise.app():show_prompt("Network error",err_msg,{'close'})
  end  
  

  
end

