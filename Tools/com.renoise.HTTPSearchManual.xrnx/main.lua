-------------------------------------------------------------------------------
--  Requires
-------------------------------------------------------------------------------

require "renoise.http"


-------------------------------------------------------------------------------
--  Menu registration
-------------------------------------------------------------------------------

local entry = {}

entry.name = "Main Menu:Help:Search Online Manual..."
entry.active = function() return true end
entry.invoke = function() search_start() end
renoise.tool():add_menu_entry(entry)


-------------------------------------------------------------------------------
--  Main functions
-------------------------------------------------------------------------------

local search_cache = ""
local results = table.create()
local vb = nil
local dialog = nil
local START_TEXT = "Start typing a keyword..."


-- Don't query the derivative string if the search_cache
-- didn't return any results;
local function no_results(str)
  rprint(results)
  return (type(str) ~= "string" or #results == 0 or
     str:match(string.format("^%s[.+]",search_cache))
   )
end

local function autocomplete(str, callback)
  local my_callback = callback or function(data) rprint(data) end
  if (#str ~= 1 and (#str == 0 or no_results(str))) then
    return
  end
  
  HTTP:get("http://tutorials.renoise.com/api.php", 
    {action="opensearch",search=str}, 
    function( res, status, xhr )          
      search_cache = str
      results = table.create()
      if (type(res)=="table" and #res > 1) then
        results = res[2]        
      end        
      my_callback(res)
    end, "json")    
end


local function set_input(str)
  vb.views.input.text = str  
end


local function get_input()
  return vb.views.input.text
end


local function show_results(data)
  data = data or ""
  local len = #data
  vb.views.results_chooser.items = {"",""}
  if (len == 0) then
    vb.views.results_text.text = "No results."
  elseif (len == 1) then    
    vb.views.results_text.text = data[1]
  elseif (len > 1) then
    -- TODO limit list size
    vb.views.results_chooser.items = data
  end
  vb.views.results_text.visible = len < 2
  vb.views.results_chooser.visible = len >= 2 
end


local function get_selected_result()
  local index = vb.views.results_chooser.value
  return vb.views.results_chooser.items[index]
end


local function search_callback(text)
  autocomplete(text,
    function(data)
      show_results(data[2])
    end)
end


local function open_url(str)
   if (str ~= "---" and str ~= "") then
     renoise.app():show_status("Opening help page for " .. str .. "...")
     renoise.app():open_url("http://tutorials.renoise.com/wiki/"
       .. get_selected_result())
   end
end


function search_start()
  
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  vb = renoise.ViewBuilder()
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local buttons = table.create{"Go"}
  local dialog_content =vb:horizontal_aligner {
    margin = DEFAULT_MARGIN,
    vb:column {
      style = "group",
      margin = DEFAULT_MARGIN,
      width = "100%",
      
      vb:text {
        id = "input",
      },

      vb:text {
         id = "results_text",
         visible = false,
         text = ""
      },

      vb:chooser {
          id = "results_chooser",
          visible = false,
          notifier = function(value)
            set_input(get_selected_result())
          end
      },

      vb:button {
        text = "Go",
        notifier = function() 
          open_url(get_selected_result())
        end
      }
    }
  }

  local function reset_input()
    set_input(START_TEXT)
    show_results{}
  end

  local function keyhandler(dialog, mod_string, key_string)
    local str = get_input()
    local index = vb.views.results_chooser.value  
   
    if (key_string == "return") then
      open_url(get_selected_result())
      return
    end

    if (key_string == "up") then    
      index = index - 1
    elseif (key_string == "down") then
      index = index + 1
    end
    
    if (index < 1) then
      vb.views.results_chooser.value = 1
    elseif (index > #vb.views.results_chooser.items) then
      vb.views.results_chooser.value = #vb.views.results_chooser.items
    else 
      vb.views.results_chooser.value = index
    end
    
    if (key_string == "up" or key_string == "down") then    
      return
    end 
    
    if (str == START_TEXT or key_string == "esc") then
        str = ""
    end        
    
    if (key_string == "back") then
      str = str:sub(1,-2)    
    end
    
    if (#key_string == 1) then      
      if (mod_string == "shift") then
        key_string = key_string:upper()
      end
      str = str .. key_string
    end        
    
    set_input(str)
    
    if (#str == 0) then
      reset_input()
    else
      search_callback(str)
    end    
  end

  set_input(START_TEXT)

  dialog = renoise.app():show_custom_dialog("Search Online Manual",
    dialog_content, keyhandler);
  
end
