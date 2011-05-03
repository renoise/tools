  --[[============================================================================
main.lua
============================================================================]]--

-- internal state

local dialog = nil
local vb = nil


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Scripting Menu:File:Create New Tool...",
  invoke = function()
    show_create_tool_dialog()
  end
}

renoise.tool():add_menu_entry {
  name = "Scripting Menu:File:Export to XRNX file...",
  invoke = function()
    show_export_dialog()
  end
}

--[[
 require ("formbuilder")

renoise.tool():add_menu_entry {
  name = "Scripting Menu:File:Build Form...",
  invoke = function()
    show_builder()
  end
}
--]]


--------------------------------------------------------------------------------
-- Preferences (form defaults)
--------------------------------------------------------------------------------

local options = renoise.Document.create("ScriptingToolPreferences") {    
  ConfirmOverwrite = true,  
  Domain = "YourDomain",
  DefaultDomain = true,
  TLD = "com", 
  TLD_id = 1, 
  Email = "you@yourdomain.xyz",
  
  -- export options
  ExportOverwrite = true,
  ExportDefaultDestination = true,
  ExportIncludeVersion = true,  
  ExportIncludeRenoiseVersion = true,  
  ExportExcludePreferencesXml = true,
  -- export filters
  ExportFilterByFolder = true,
  ExportFilterFolderValue = "__MyTools__",
  ExportFilterByAuthor = false,
  ExportFilterAuthorValue = "My Name",
}
options:add_property("Name", "The Tool Name")
options:add_property("Id", "com.myorg.ToolName")        
options:add_property("Author", "My Name")
options:add_property("Category", "In Progress")
options:add_property("Description",  "")
options:add_property("Homepage", "http://tools.renoise.com")
options:add_property("Icon", "")  

local categories = {"Pattern Editor", "Sample Editor", "Instruments", "Algorithmic composition"}

renoise.tool().preferences = options


--------------------------------------------------------------------------------
-- Manifest Document Structure
--------------------------------------------------------------------------------

class "RenoiseScriptingTool"(renoise.Document.DocumentNode)

  function RenoiseScriptingTool:__init()
  
    renoise.Document.DocumentNode.__init(self)     
    
    self:add_property("Name", "")
    self:add_property("Id", "")        
    self:add_property("Version", 1)
    self:add_property("ApiVersion", renoise.API_VERSION)
    self:add_property("Author", "")
    self:add_property("Category", "")
    self:add_property("Description", "")
    self:add_property("Homepage", "")
    self:add_property("Icon", "")
  end
  
  function RenoiseScriptingTool:validate()
  end
  
  function RenoiseScriptingTool:update()      
    
    -- pre-processed fields
    self.Id.value = vb.views.name_preview.text:sub(1,-6)
    self.ApiVersion = renoise.API_VERSION       
    if (trim(options.Email.value) ~= "" and 
      options.Email.value ~= "you@yourdomain.xyz") then
      self.Author.value = options.Author.value .. " | " .. options.Email.value      
    else
      self.Author.value = options.Author.value    
    end
    
    -- copied fields
    self.Name.value = options.Name.value    
    self.Description.value = options.Description.value
    self.Category.value = options.Category.value    
    self.Homepage.value = options.Homepage.value
    self.Icon.value = options.Icon.value        
  end
  

local manifest = RenoiseScriptingTool()

  
--------------------------------------------------------------------------------
-- I/O and file system functions
--------------------------------------------------------------------------------

local MYTOOLS = "__MyTools__"

local SEP = "/"
if (os.platform() == "WINDOWS") then
  SEP = "\\"
end

-- Return the path of the "Tools" folder
-- The behavior of this function in situations involving symlinks 
--  or junctions was not determined.
function get_tools_root()    
  local dir = renoise.tool().bundle_path
  return dir:sub(1,dir:find("Tools")+5)      
end

local function create_folder(parent, child)
  if (parent == nil) then
    renoise.app():show_error("Parent folder was empty: " .. child)  
    return
  end
  local sep = ""
  if (parent:sub(-1) ~= SEP) then  
    sep = SEP
  end
  local path = parent..sep..child
  if (not io.exists(path)) then  
    if (not os.mkdir(path)) then
      renoise.app():show_error("Could not create the folder: " .. path)
      return
    end
  end    
  return path
end

-- If file exists, popup a modal dialog asking permission to overwrite.
local function may_overwrite(path)
  local overwrite = true
  if (io.exists(path) and options.ConfirmOverwrite.value) then
    local buttons = {"Overwrite", "Keep existing file" ,"Always Overwrite"}
    local choice = renoise.app():show_prompt("File exists", "The file\n\n " ..path .. " \n\n"
      .. "already exists. Overwrite existing file?", buttons)
    if (choice==buttons[3]) then 
       options.ConfirmOverwrite.value = false
    end
    overwrite = (choice~=buttons[2])
  end  
  return overwrite
end

-- Reads entire file into a string
-- (this function is binary safe)
local function file_get_contents(file_path)
  local mode = "rb"  
  local file_ref,err = io.open(file_path, mode)
  if not err then
    local data=file_ref:read("*all")        
    io.close(file_ref)    
    return data
  else
    return nil,err;
  end
end

-- Writes a string to a file
-- (this function is binary safe)
local function file_put_contents(file_path, data)
  local mode = "w+b" -- all previous data is erased
  local file_ref,err = io.open(file_path, mode)
  if not err then
    local ok=file_ref:write(data)
    io.flush(file_ref)
    io.close(file_ref)    
    return ok
  else
    return nil,err;
  end
end


local ERROR = {OK=1, FATAL=2, USER=3}
-- Copies the contents of one file into another file.
local function copy_file_to(source, target)      
  local error = nil
  local code = ERROR.OK
  if (not io.exists(source)) then    
    error = "The source file\n\n" .. source .. "\n\ndoes not exist"
    code = ERROR.FATAL
  end
  if (not error and may_overwrite(target)) then
    local source_data = file_get_contents(source, true)    
    local ok,err = file_put_contents(target, source_data)        
    error = err          
  else 
    code = ERROR.USER
  end
  return not error, error, code
end


--------------------------------------------------------------------------------
-- Tool creation functions
--------------------------------------------------------------------------------

local function create_tool()
  local root = get_tools_root()  
  local folder_name = vb.views.name_preview.text
  local my_tools = create_folder(root, MYTOOLS)
  local target_folder = create_folder(my_tools, folder_name)
  if (not target_folder) then
    return
  end
  
  manifest:update()
  
  if (may_overwrite(target_folder..SEP.."manifest.xml") and 
    not manifest:save_as(target_folder..SEP.."manifest.xml")) then
      renoise.app():show_error ("Could not create the manifest.xml file") 
      return
  end
  
  local lua_template = renoise.tool().bundle_path ..SEP.. "templates"..SEP.."main.lua"
  
  local ok, err, code = copy_file_to(lua_template, target_folder..SEP.."main.lua")
  if (err and code ~= ERROR.USER) then 
      renoise.app():show_error(err)  
      return
  end
  renoise.app():show_message("Your new Tool has been created: \n\n" .. target_folder)
end

function trim(s)
  if (type(s) ~= "String") then
    return s
  end
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function clean_component(str)
  --str = str:gsub("[/\\%.;:%*%?%<%|%z=\"%[%]'&]+", "")
  str = str:gsub("[^%s%w-_!]", "")  
  return str
end

local function camel_case(str)  
  str = str or ""    
  local function tchelper(first, rest)
    return first:upper()..rest:lower()
  end
  -- Add extra characters to the pattern if you need to. _ and ' are
  --  found in the middle of identifiers and English words.
  -- We must also put %w_' into [%w_'] to make it handle normal stuff
  -- and extra stuff the same.
  -- This also turns hex numbers into, eg. 0Xa7d4  
  str = str:gsub("(%a)([%w_']*)", tchelper)
    
    -- Remove spaces
  str = str:gsub("%s+", "")
  return str
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
local TEXTFIELD_WIDTH = 180

local function is_form_complete()
  local ok = false  
  ok = (nil ~= vb.views.name_preview.text:match("^[%w]+%.[%w%-_!]+%.[%w%-_!]+%.xrnx$"))  
  ok = ok and (trim(options.Description.value) ~= "")
  return ok
end

function autocomplete(text)  
  if (true or #text < 1) then return end
  local i = 1  
  while (categories[i]) do    
    local c = categories[i]    
    if (c:match("^"..text)) then
      --print(text .. " resembles " .. c)
      --vb.views.category_text:add_line(c)  
    end
    i = i+1
  end
end

function show_create_tool_dialog()

  if dialog and dialog.visible then
    dialog:show()
    return
  end

  vb = renoise.ViewBuilder()

  local dialog_title = "Create New Tool"
  local dialog_buttons = {"Close"};
  
  -- view functions
  
  local function get_tld()
    local raw = nil
    if (vb.views.tld_text.visible) then
      raw = vb.views.tld_text.text
    else
      local id = vb.views.tld_popup.value      
      raw = vb.views.tld_popup.items[id]
    end
    raw = clean_component(raw)
    return trim(raw:gsub("[%s%-]+", ""):lower())
  end
  
  local function get_domain()
    local raw = nil
    if (not options.DefaultDomain.value) then
      raw = vb.views.domain_text.text  
    else 
      raw = vb.views.author_text.text
    end
    raw = clean_component(raw)
    return trim(raw:gsub("%s+", ""):lower())
  end
  
  local function get_tool_name()
    local raw = vb.views.tool_name_text.text  
    raw = clean_component(raw)    
    return camel_case(raw)
  end
  
  local function get_email()
    local raw = trim(vb.views.email_text.text)    
    if (raw ~= "" and not raw:match(
      "[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?"
      )) then
      renoise.app():show_warning("Invalid e-mail address")
    end
    return raw
  end
  
  local function update_preview()    
    vb.views.email_text.value = get_email()
    vb.views.author_text.value = trim(options.Author.value)      
    vb.views.tool_name_text.value = trim(options.Name.value)
    
    vb.views.name_preview.text = ("%s.%s.%s.xrnx"):format(                   
      get_tld(),
      get_domain(),
      get_tool_name()
    )
    
    options.TLD.value = get_tld()
    options.Domain.value = get_domain()
    options.Homepage.value = trim(vb.views.homepage_text.text)
    options.Category.value = trim(vb.views.category_text.text)
    options.Description.value = trim(vb.views.description_text.text)
    vb.views.save_button.active = is_form_complete()
  end


  -- dialog content

  local dialog_content = vb:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,
    uniform = true,      
    
    vb:column {            
      style = "panel",
      margin = 5,
      
      vb:text { 
        font = "bold",
        text = "Preview Package Name"       
      },     
      vb:text {
        id = "name_preview",
        text = "",
        font = "mono"
      },
       vb:text { 
        font = "italic", 
        text = "(Any disallowed characters are filtered out)" 
      }
    }, 
     
    vb:column {
      style = "group",
      spacing = DEFAULT_CONTROL_SPACING,
      margin = 5,                   
        
      vb:text {
        text = "Give your new Tool a name",
        font = "bold"
      },
      
      vb:text { 
        text = "Tool Name", 
        width = 220 
      },
      vb:textfield {         
        width = TEXTFIELD_WIDTH,
        id = "tool_name_text", 
        bind = options.Name, 
        notifier = update_preview,                
      },
      
      vb:text {text= "Author"},
      vb:textfield {         
        width = TEXTFIELD_WIDTH,      
        id = "author_text",
        notifier = update_preview,
        bind = options.Author
      }, 
      
      vb:row {
        vb:text { text = "Domain/Organisation" },            
        vb:bitmap {bitmap = "images/info.bmp",  mode = "body_color"},
        tooltip = 
[[Companies use their reversed Internet domain name to begin their package 
names—for example, com.example.orion for a package named orion created by 
a programmer at example.com. 

The name of a package is not meant to imply where the package is stored within 
the Internet; for example, a package named edu.cmu.cs.bovik.cheese is not 
necessarily obtainable from Internet address cmu.edu or from cs.cmu.edu or 
from bovik.cs.cmu.edu. The suggested convention for generating unique package 
names is merely a way to piggyback a package naming convention on top of an 
existing, widely known unique name registry instead of having to create a 
separate registry for package names.]]
      },
      vb:row{
        vb:textfield { 
          id = "domain_text", 
          bind = options.Domain,
          visible = not options.DefaultDomain.value,
          notifier = update_preview,          
        },
        vb:checkbox { 
          id = "domain_checkbox",
          bind = options.DefaultDomain,
          notifier = function(c)
           vb.views.domain_text.visible = not options.DefaultDomain.value   
           update_preview()
          end 
        },      
        vb:text { text = "Same as Author"},              
           
      },
      
      vb:row { 
        vb:text {text= "Top Level Domain (TLD)"},
        vb:bitmap {bitmap = "images/info.bmp", mode = "body_color"},
        tooltip =  
[[The first component of a unique package name is always written in 
all-lowercase ASCII letters and should be one of the top level domain names, 
currently com, edu, gov, mil, net, org, or one of the English two-letter 
codes identifying countries as specified in ISO Standard 3166, 1981. For more 
information, refer to the documents stored at ftp://rs.internic.net/rfc, for 
example, rfc920.txt and rfc1032.txt.]]
      },
      vb:row {
        vb:textfield { 
          id ="tld_text", 
          visible = false,
          notifier = update_preview,          
          bind = options.TLD,
        },      
        vb:popup { id = "tld_popup", items = 
          {"com", "org", "net", "edu", "de", "nl", "fr", "it", "es", "uk", "Other..."},
          notifier = function(i)            
            vb.views.tld_text.visible = (i==#vb.views.tld_popup.items)                        
            update_preview()            
          end,
          bind = options.TLD_id
        },
      },      
    },      
    
    vb:column {
      style = "group",
      margin = 5,
      uniform = true,
    
      vb:text { 
        font = "bold",
        text = "Mandatory Manifest Fields",        
      },    
    
      vb:text { text = "Description" },
      vb:multiline_textfield  {
        id = "description_text",      
        height = 60, 
        width = "100%",
        text = options.Description.value,
        notifier = function()           
           update_preview()
        end 
        --text = options.Description.value,               
      }    
    },
    
    vb:column {
      style = "group",
      margin = 5,
      uniform = true,
    
      vb:text { 
        font = "bold",
        text = "Optional Manifest Fields",        
      },    
      
      vb:text { text = "E-Mail" },
      vb:textfield {
        id = "email_text",
        bind = options.Email,
        notifier = update_preview,
        width = TEXTFIELD_WIDTH
      },
      
      vb:text { text = "Homepage" },
      vb:textfield {
        id = "homepage_text",
        bind = options.Homepage,
        notifier = update_preview,
        width = TEXTFIELD_WIDTH
      },     
      
      vb:text { text = "Category" },
      vb:textfield {        
        id = "category_text",        
        bind = options.Category,
        notifier = function(text)         
          autocomplete(text)
          update_preview()
        end,
        width = TEXTFIELD_WIDTH
      }
    },
    vb:row {
      spacing = DEFAULT_CONTROL_SPACING,      
      vb:button {
        id = "save_button",
        text = "Save and Create Tool",
        height = DIALOG_BUTTON_HEIGHT,
        active = is_form_complete(),
        notifier = function()        
          create_tool()
        end        
      },
      vb:button {
        text = "Preferences",
        height = DIALOG_BUTTON_HEIGHT,
        notifier = function()
          local vb = renoise.ViewBuilder()
          local content = vb:column {
            margin = 5,
            vb:horizontal_aligner {
              spacing = 5,              
              vb:checkbox {                
                bind = options.ConfirmOverwrite
              },
              vb:text { 
                text = "Ask before overwriting files and folders"
              }
            }
          }
          renoise.app():show_custom_prompt(
            "Preferences for the 'Create New Tool' Tool", content, {"Save and Close"})
        end        
      }
    }
  }
  
  
  -- init    
  if (options.TLD_id.value == #vb.views.tld_popup.items) then
    table.insert(vb.views.tld_popup.items, 1, options.TLD.value)    
    vb.views.tld_text.visible = true
  end        
  
  update_preview()

  -- key_handler
  local function key_handler(dialog, key)

  end


  -- show
  dialog = renoise.app():show_custom_dialog(
    dialog_title, dialog_content, key_handler)

end


--------------------------------------------------------------------------------
-- Export Tool folder to XRNX file (ZIP)
--------------------------------------------------------------------------------

require "zip"

local zip_dialog = nil
local confirm_dialog = nil

local vbz = nil
local vbc = nil

local function load_manifest(path)  
  local mf = RenoiseScriptingTool()
  local ok, err = mf:load_from(path)
  return mf  
end

-- Create an XRNX file by ZIP'ing the Tool within the __MyTools__ folder
local function zip_tool(tool, version)      
  local source_folder = tool.bundle_path 
  local target_folder = get_tools_root()..MYTOOLS..SEP.."XRNX"
  
  -- browse to custom output folder 
  if (not options.ExportDefaultDestination.value) then
    target_folder = renoise.app():prompt_for_path("Choose")      
    print(type(target_folder), target_folder)
    if (not target_folder or target_folder == "") then
       return false, "Export operation was cancelled."
    end          
  end
  
  -- create output folder if it does not exist
  if (not io.exists(target_folder)) then
    os.mkdir(target_folder)
  end  
  
  -- strip trailing slash
  if (target_folder:sub(-1) == SEP) then
    target_folder = target_folder:sub(1,-2)
  end  
  
  -- assemble filename
  local filename = ""
  local renoise_version = ""
  if (options.ExportIncludeRenoiseVersion.value) then
    if (renoise.API_VERSION == 1) then
      renoise_version = "_Rns260"
    elseif (renoise.API_VERSION == 2) then
      renoise_version = "_Rns270"
    end
  end
  if (version) then
    version = "_V".. tostring(version)
  end
  filename = ("%s%s%s"):format(tool.id, renoise_version, version)
  
  -- construct absolute output file path
  local destination = target_folder..SEP..filename..".xrnx"  
  
  -- ask to overwrite
  if (options.ExportOverwrite.value == false and io.exists(destination)) then
    local choice = renoise.app():show_prompt(
      "File exists", 
      "The file\n\n"..destination.."\n\nalready exists. Overwrite existing file?", 
      {"Overwrite", "Cancel"})
    if (choice ~= "Overwrite") then
      return false, "Export operation was cancelled."
    end
  end
  
  -- exclude files
  local excludes = table.create()
  if (options.ExportExcludePreferencesXml.value) then
    excludes:insert("preferences.xml")
  end
  
  -- zip
  local ok, err = zip(source_folder, destination, excludes)
  if (not ok) then                      
    renoise.app():show_error(err)
  else
    local msg = "The XRNX file was succesfully created at the following location:\n\n"
      .. destination 
    local choices = {"Close","Show file"}
    local choice = renoise.app():show_prompt("Export was succesful", msg, choices)
    if (choice == choices[2]) then
      renoise.app():open_path(destination)
    end
  end
  return ok, err
end


-- Is the path in the given location?
local function in_folder(needle, haystack)
  local haystack = haystack:gsub("\\", "/"):lower()
  local needle = needle:gsub("\\", "/"):lower()
  return (haystack:find(needle) ~= nil)
end


-- Get a table of tools filtered by author
local function filter_tools_by_author(tools, author)  
  local found = table.create()
  
  if (type(tools) ~= "table" or not author or #author < 1) then
    return found
  end
  
  author = author:lower()
  
  for k,tool in ipairs(tools) do
    if (tool.author:lower():find(author)) then
      found:insert(tool)
    end    
  end
  return found
end


-- Get a table of tools filtered by folder
local function filter_tools_by_folder(tools, folder)  
  local found = table.create()
  
  if (type(tools) ~= "table" or not folder or #folder < 1) then
    return found
  end    
    
  for k,tool in ipairs(tools) do        
    if (in_folder(folder, tool.bundle_path)) then
      found:insert(tool)
    end    
  end
  return found  
end


-- Returns a list of Tool folders in the __MyTools__ folder
local function get_mytools()
  local path = get_tools_root() .. MYTOOLS
  if (not io.exists(path)) then
    return {}
  end
  local t = os.dirnames(path)
  mytools = table.create()
  for _,v in ipairs(t) do
    if (v:match("xrnx$")) then
      mytools:insert(v)
    end
  end      
  return mytools
end

-- GUI -----------

-- Confirm Export Dialog
function show_confirm_export_dialog(tool)      
  
  if (confirm_dialog and confirm_dialog.visible) then
    confirm_dialog:show()
    return
  end
  
  local title = "Check manifest.xml and Confirm Export"
  
  vbc = renoise.ViewBuilder()

  local mf_folder = tool.bundle_path
  local mf_path = mf_folder .. SEP .. "manifest.xml"
  local mf = load_manifest(mf_path)    
  
  local content = vbc:column{ 
    margin = DEFAULT_DIALOG_MARGIN, 
    spacing = DEFAULT_CONTROL_SPACING  
  }
  content:add_child(vbc:text{text="Is manifest.xml still up-to-date? Please adjust where necessary."})
  local main = vbc:row{ 
    margin = DEFAULT_DIALOG_MARGIN, 
    spacing = 20,
    style = "group"
  }
  content:add_child(main)
  local labels = vbc:column{ uniform = true, spacing = DEFAULT_CONTROL_SPACING   }
  main:add_child(labels)
  local controls = vbc:column{ uniform = true, spacing = DEFAULT_CONTROL_SPACING }  
  main:add_child(controls)
      
  local function add_field(name)
    labels:add_child(
      vbc:text {      
        text = name,
        font = "bold"
    })    
    
    local t = type(mf[name])    
    local c = nil
    
    if (name == "Id") then
      c = vbc:text {
        text = mf[name].value,  
      }       
    elseif (name == "Description") then
      c = vbc:multiline_textfield {
        height = 60,
        text = mf[name].value,
        notifier = function(text)           
          mf[name].value = trim(text)
        end
      }        
    elseif (t == "ObservableString") then
      c = vbc:textfield {
        text = mf[name].value,
        notifier = function(text)
          mf[name].value = trim(text)
        end
      }            
    elseif (t == "ObservableNumber") then      
        c = vbc:valuefield {
          tostring = function(value) 
            return ("%.2f"):format(value)
          end,
          tonumber = function(str)
            if str ~= nil then
              return tonumber(str)
            end
          end,         
          min = 0.00,
          max = 100.00, 
          bind = mf[name]         
       }         
    elseif (t == "ObservableBoolean") then      
        c = vbc:checkbox {
          bind = mf[name]          
        }
    elseif (t == "ObservableList") then
      --[[ 
      print(type(mf[name][1]))
      c = vbc:text {            
        text = mf[name].value
      }
      --]]
    end 
    
    if (name == "ApiVersion") then
      c = vbc:row { 
        c,        
        vbc:text {
          text = ("(now running API v%.2f)"):format(            
            renoise.API_VERSION)
        }
      }
    end
      
    c.width = 200   
    controls:add_child(c)        
  end
  
  local names = {"Id", "Name", "Version", "ApiVersion", "Author",
     "Homepage", "Category", "Description"}
  for _,name in ipairs(names) do
    add_field(name)
  end
  
  content.uniform = true
  content:add_child(vbc:text{text="Save to manifest.xml and export?"})  
  
  local incomplete_form = vbc:text{
    id = "incomplete_form",
    text = "Cannot export because this form is incomplete.",
    font = "italic",    
    visible = false
  }
  content:add_child(incomplete_form)
  
  local buttons = vbc:horizontal_aligner {
    spacing = DEFAULT_CONTROL_SPACING,      
    --mode = "distribute",
    vbc:button {
      height = DIALOG_BUTTON_HEIGHT, 
      text = "Save and export",
      notifier = function()
        
        for _,name in ipairs(names) do          
          mf[name].value = trim(mf[name].value)
          if (mf[name].value == "" and 
            name ~= "Homepage" and name ~= "Category") then
            vbc.views.incomplete_form.visible = true
            return
          end
        end
        
        mf:save_as(mf_path)    
                
        local version = nil
        if (options.ExportIncludeVersion.value) then
          version = mf["Version"].value
        end
        local ok,err = zip_tool(tool, version)   
        confirm_dialog:close()        
      end
    },
    vbc:button {
      height = DIALOG_BUTTON_HEIGHT,
      text = "Close", 
      notifier = function()
        confirm_dialog:close()  
      end
    }
  }
  content:add_child(buttons)
    
  confirm_dialog = renoise.app():show_custom_dialog(title, content)      
  
end

-- Turn a tools table into a table suitable for a popup list
local function to_popup_items(tools)
  local filtered = table.create()
  for k,tool in ipairs(tools) do
    filtered[k] = tool.id
  end
  return filtered
end

-- Update the Tool folder filters and the popup list
local function update_filters(tools)
  local filtered = tools
  if (options.ExportFilterByAuthor.value) then
    filtered = filter_tools_by_author(filtered, options.ExportFilterAuthorValue.value)    
  end
  if (options.ExportFilterByFolder.value) then
    filtered = filter_tools_by_folder(filtered, options.ExportFilterFolderValue.value)    
  end
  
  if (vbz) then
    vbz.views.mytools.items = to_popup_items(filtered)
  end
end

-- Export Dialog
function show_export_dialog()

  local tools = renoise.app().installed_tools  
    
  if zip_dialog and zip_dialog.visible then
    zip_dialog:show()    
    return
  end

  vbz = renoise.ViewBuilder()
  
  local dialog_title = "Export Tool folder to XRNX file"
  local dialog_content = vbz:column {
    margin = DEFAULT_DIALOG_MARGIN,
    spacing = DEFAULT_CONTROL_SPACING,              
    
    vbz:text {      
      text = "Choose a Tool to export",
      font = "bold"
    },  
    vbz:popup {
      id = "mytools",
      items = to_popup_items(tools),
      width = 260,      
    },    
    
    -- author filter
    vbz:horizontal_aligner {                
      spacing = DEFAULT_CONTROL_SPACING,
      vbz:checkbox {        
        bind = options.ExportFilterByAuthor,
        notifier = function()
          update_filters(tools)    
        end
      },
      vbz:text {
        text = "Filter by author name"
      },
      vbz:textfield {        
        id = "author_filter",
        width = 80,
        bind = options.ExportFilterAuthorValue,
        notifier = function()
          update_filters(tools)    
        end
      }       
    },
    
    -- folder filter
    vbz:horizontal_aligner {      
      spacing = DEFAULT_CONTROL_SPACING,      
      vbz:checkbox {       
        bind = options.ExportFilterByFolder,
        notifier = function(enabled)           
          update_filters(tools)    
        end
      },
      vbz:text {
        text = "Filter by folder"
      },                 
      
      vbz:textfield {
        id = "folder_filter",      
        width = 115,
        bind = options.ExportFilterFolderValue,
        notifier = function()
          update_filters(tools)    
        end
      },
      vbz:button {        
        text = "Browse",      
        notifier = function()
          local path = renoise.app():prompt_for_path(dialog_title)                    
          options.ExportFilterFolderValue.value = path
        end
      },     
    },   
   
    -- export options
    vbz:column {
      style = "group",
      margin = DEFAULT_DIALOG_MARGIN,
      spacing = DEFAULT_CONTROL_SPACING,
      width = "100%",
      
      vbz:text {
        text = "Export options",
        font = "bold"
      }, 
      vbz:row { 
        spacing = DEFAULT_CONTROL_SPACING,
        vbz:checkbox {                
          bind = options.ExportExcludePreferencesXml
        },
        vbz:text {
          text = "Exclude preferences.xml",        
        }
      },
      vbz:row { 
        spacing = DEFAULT_CONTROL_SPACING,
        vbz:checkbox {                
          bind = options.ExportIncludeVersion
        },
        vbz:text {
          text = "Add version number to filename",        
          tooltip = "Example: com.yourname.YourTool_V2.50.xrnx"        
        }
      },
      vbz:row { 
        spacing = DEFAULT_CONTROL_SPACING,
        vbz:checkbox {                
          bind = options.ExportIncludeRenoiseVersion
        },
        vbz:text {
          text = "Add Renoise version to filename",        
          tooltip = "Example: com.yourname.YourTool_Rns270_V2.xrnx"        
        }
      },
      vbz:row { 
        spacing = DEFAULT_CONTROL_SPACING,
        vbz:checkbox {                
          bind = options.ExportOverwrite
        },
        vbz:text {
          text = "Overwrite existing files",        
        }
      },
      vbz:row { 
        spacing = DEFAULT_CONTROL_SPACING,
        vbz:checkbox {                
          bind = options.ExportDefaultDestination
        },
        vbz:text {
          text = "Save files into default XRNX export folder",
        }
      }, 
    },       
    vbz:row {
      spacing = DEFAULT_CONTROL_SPACING,
      vbz:button {      
        text = "Export Tool",
        active = vbz.views.mytools.items[1] ~= "None",
        height = DIALOG_BUTTON_HEIGHT,        
        notifier = function() 
          local id = vbz.views.mytools.value          
          show_confirm_export_dialog(tools[id])
        end
      },
      vbz:button {
        text = "Browse export folder",
        active = vbz.views.mytools.items[1] ~= "None",
        height = DIALOG_BUTTON_HEIGHT,
        notifier = function()
          local path = get_tools_root()..MYTOOLS..SEP.."XRNX"
          if (not io.exists(path)) then            
            os.mkdir(path)
          end
          renoise.app():open_path(path)
        end
      }
    }
  }  
  
  update_filters(tools)
  zip_dialog = renoise.app():show_custom_dialog(
    dialog_title, dialog_content)

end


