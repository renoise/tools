local TITLE = "ToolUpdater"

-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "renoise.http"


-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}

entry.name = "Main Menu:Tools:"..TITLE.."..."
entry.active = function() return true end
entry.invoke = function()   
  show_tool_updates() 
end
renoise.tool():add_menu_entry(entry)


-------------------------------------------------------------------------------
--  Main functions
-------------------------------------------------------------------------------

local dialog = nil
local MAX_TOOLS = 5

function show_tool_updates()
  local vb = renoise.ViewBuilder()
  local progress = vb:text{text="loading..."}
  local body = vb:column{ 
    margin=10,
    spacing=5, 
    uniform=true,
    vb:text{text=TITLE.." retrieves a list of applicable updates from the Renoise server.\n"..
    "Currently the complete Tool list is downloaded."},
    progress 
  }
  
  if (dialog and dialog.visible) then
    dialog:show()
  end
  
  dialog = renoise.app():show_custom_dialog(      
        TITLE, body)
        
  local settings = {
    content_type='application/json',
    url='http://tools.renoise.com/services/json-rpc',
    method=Request.POST,
    data={method='views.get',params={view_name='ToolUpdates'}},
    error=function(xml_http_request, text_status, error_thrown)
      progress.text = "Could not load update info :(\n" .. (error_thrown or "")
    end,
    success=function(d, text_status, xml_http_request)
      body:remove_child(progress)
      local data = d.result
      local page = vb:column{spacing=3,visible=true,uniform=true}
      local pages = vb:row{spacing=5}
      local page_table = table.create()
      for k,v in ipairs(data) do        
        
        -- Tool group
        local tool = vb:row{ 
          style="group",           
          margin=3,
          -- Checkbox
          vb:checkbox {
          },
          -- Tool title          
          vb:text{ 
            text=v.node_title, 
            font="bold"
          },
          -- Tool version
          vb:text{ 
            text=v.node_data_field_api_field_version_value
          }          
        }  
        page:add_child(tool)
        if (k % MAX_TOOLS == 0) then
          local pid = "page_"..k / MAX_TOOLS
          page_table[pid] = page
          pages:add_child(page_table[pid]) 
          page = vb:column{spacing=3,visible=false,uniform=true}
        end                
      end        
      local items = table.create()
      for i=1,page_table:count() do
        items:insert("Page " .. i)
      end      
      body:add_child(                
        vb:row{          
          spacing = 5, 
          vb:column{
            margin = 3,
            height = "100%",
            style = "body",
            uniform = true,                    
            vb:popup{
              items = items,
              notifier = function(item)               
                for _,v in pairs(page_table) do
                  v.visible = false
                end
                page_table["page_"..item].visible = true
                pages:resize()
              end
            },
            vb:button{
              text = "Update\n selected Tools", 
              notifier = function() 
                renoise.app():show_prompt("Not implemented", 
                  "The list should display installed Tools that can be updated.".. 
                  "The selected Tools are then downloaded and installed.", 
                  {"OK"}) 
                end
            }
          },
          pages
      })      
    end,
    data_type='json'
  }
  local new_request = Request(settings)
end
