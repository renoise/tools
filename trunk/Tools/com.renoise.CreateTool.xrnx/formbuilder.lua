--[[============================================================================
formbuilder.lua
============================================================================]]--

-- internal state

local builder = nil
local vb = nil
local notifiers = table.create()
local action_notifier = function(source_id) 
  return function(action_id, source_id) 
    if (action_id > 1) then 
      handle_action(source_id, action_id) 
    end
  end 
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

--[[
[opt] [opt] [opt]
[   ] [   ] [   ] [opt]
[   ] [   ] [   ] [opt]
[   ] [   ] [   ] [opt]
 [+ new row]
--]] 

function handle_cell(source_id, action_id)
  if (action_id == 2) then
    -- vb.views."source_id".parent
  end
end

function handle_action(source_id, action_id)  
  print("Handle "..source_id .. " Action "..action_id)
  if (action_id == 1) then
  end
end
 
function show_builder()

  --[[
  if builder and builder.visible then
    builder:show()
    return
  end
  --]]
  
  vb = renoise.ViewBuilder()
  
  local dialog_content = vb:column{}

  local DEFAULT_DIALOG_MARGIN =
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING =
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local TEXT_ROW_WIDTH = 100
  local WIDE = 180

  local dialog_title = "Form Builder"
  local dialog_buttons = {"Close"};

  local p = 1
  local popup = function() 
    p=p+1
    local id = "p_"..p
    notifiers[id] = handle_cell(id)
    return vb:popup {         
      id = "p_"..p,
      items = {"_","text","textfield","checkbox","popup","button"},
      notifier = notifiers[id]
    }
  end
  
  local ro = 0
  local row_options = function()
    ro=ro+1
    local id = "ro_"..ro    
    notifiers[id] = handle_action(id)
    return vb:popup{
      id = "ro_"..ro,
      items = {"row ops","insert new row", "delete row", "resize", "align"},
      notifier = notifiers[id]
    }
  end
  
  local co = 0
  local column_options = function()    
    co = co+1    
    local id = "co_"..co    
    notifiers[id] = handle_action(id)
    return vb:popup{
      id = id,
      items = {"col ops","insert new column", "delete column", "resize", "align"},      
      notifier = notifiers[id]
    }
  end
  
  local num_columns = 3
  local num_rows = 3
  
  local column_options_row = function()  
    local row = vb:row {}
    for i=1,num_columns do 
      row:add_child(column_options(i))
    end       
    return row
  end
  
  local row = function(j)    
    local row = vb:row {}
    for i=1,num_columns do
      row:add_child( vb:column{ popup() })       
    end
    row:add_child(vb:column{ row_options(j) })
    return row
  end
  
  for i=1,4 do    
    local row = row(i)
    dialog_content:add_child(row)    
  end
  dialog_content:add_child( column_options_row() )

  -- key_handler
  
  local function key_handler(builder, key)
  
  end
  
  
  -- show
  
  builder = renoise.app():show_custom_dialog(
    dialog_title, dialog_content, key_handler)
  
end
  
