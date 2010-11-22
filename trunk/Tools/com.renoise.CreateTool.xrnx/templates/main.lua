--[[============================================================================
main.lua
============================================================================]]--

-- internal state

local dialog = nil
local vb = nil

_AUTO_RELOAD_DEBUG = function()
  dialog = nil
  vb = nil
end

-- Get Tool Name

class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
  function RenoiseScriptingTool:__init()    
    renoise.Document.DocumentNode.__init(self) 
    self:add_property("Name", "Untitled Tool")
  end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

local function get_greeting()
  local words = {"Hello world!", "Nice to meet you :)", "Hi there!"}
  local id = math.random(#words)
  return words[id]
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  vb = renoise.ViewBuilder()
  
  local content = vb:column {
    margin = 10,
    vb:text {
      text = get_greeting()
    }
  } 
  
  dialog = renoise.app():show_custom_dialog(tool_name, content)  
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = function()
    show_dialog()
  end
}
