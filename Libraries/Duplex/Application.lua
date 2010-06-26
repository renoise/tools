--[[----------------------------------------------------------------------------
-- Duplex.Application
----------------------------------------------------------------------------]]--

--[[

A generic application class for Duplex
- extend this class to build applications for the Duplex Browser
- provides globally accessible configuration options 
- o start/stop applications
- o edit control-map groups, change built-in options 
- o browser integration: control autorun, aliases, pinned status
- 


--]]


--==============================================================================

class 'Application'

-- constructor 
function Application:__init()
  TRACE("Application:__init()")
  
  -- the application is considered created 
  -- once build_app() has been called
  self.created = false

  -- when the application is inactive, it should 
  -- sleep during idle time and ignore any user input
  self.active = false

  -- mappings allows us to choose where to put controls,
  -- see actual application implementations for examples
  -- 
  -- @group_name: the control-map group-name
  -- @required: you have to specify a group name
  -- @index: when nil, mapping is considered "greedy",
  -- and will use the entire group
  -- 
  -- example_mapping = {
  --  group_name = "Main",
  --  required = true,
  --  index = nil
  -- }
  self.mappings = {}

  -- you can choose to expose your application's options here
  -- the values can be edited using the options dialog
  -- 
  -- example_option = {
  --  label = "My option",
  --  items = {"Choice 1", "Choice 2"},
  --  default = 1 -- this is the default value ("Choice 1")
  -- }
  self.options = {}

  -- define a palette to enable color-picker support
  self.palette = {}

  -- global app settings (reference to the browser)
  self.browser = nil

  -- browser config app branch, e.g. "MyDevice"
  -- (needed in order to update the global config)
  self.device_display_name = nil -- 

  -- this is the app name, such as it appears in the browser
  -- (needed in order to update the global config)
  -- the name is the class name, with an optional postfix that
  -- tell us that it's an alias (e.g. "MixConsole_2")
  self.app_display_name = nil 

  -- the options dialog
  self.dialog = nil

  -- internal stuff
  self.view = nil
  self.vb = renoise.ViewBuilder()

end


--------------------------------------------------------------------------------

-- (run once) create view and members

function Application:build_app()
  TRACE("Application:build_app()")
  
  --local vb = renoise.ViewBuilder()
--[[  
  self.view = self.vb:text {
    text = "this is a blank application",
  }
]]  
  self.created = true
end


--------------------------------------------------------------------------------

-- start/resume application

function Application:start_app()
  TRACE("Application:start_app()")
  
  if not (self.created) then 
    return 
  end

  if (self.active) then
    return
  end

  if (self.dialog) then 
    local elm = self.vb.views.dpx_app_options_running
    elm.value = true
  end

  self.active = true
end


--------------------------------------------------------------------------------

-- stop application

function Application:stop_app()
  TRACE("Application:stop_app()")
  
  if not (self.created) then 
    return 
  end

  if (not self.active) then
    return
  end

  if (self.dialog) then 
    local elm = self.vb.views.dpx_app_options_running
    elm.value = false
  end

  self.active = false
end


--------------------------------------------------------------------------------

-- display application options

function Application:show_app()
  TRACE("Application:show_app()")
  
  if (not self.dialog) or (not self.dialog.visible) then
    self:__create_dialog()
  else
    self.dialog:show()
  end
end


--------------------------------------------------------------------------------

-- hide application options

function Application:hide_app()
  TRACE("Application:hide_app()")
  
  if (self.dialog) and (self.dialog.visible) then
    self.dialog:close()
    self.dialog = nil
  end

end


--------------------------------------------------------------------------------

-- destroy application

function Application:destroy_app()
  TRACE("Application:destroy_app()")
  self:hide_app()
  self:stop_app()
end


--------------------------------------------------------------------------------

-- handle periodic updates (many times per second)
-- nothing is done by default

function Application:idle_app()
  --[[
  -- it's a good idea to include this check 
  -- when doing complex stuff:
  if (not self.active) then 
    return 
  end
  ]]


end


--------------------------------------------------------------------------------

-- assign matching group-names

function Application:apply_mappings(mappings)

  for v,k in pairs(self.mappings) do
    for v2,k2 in pairs(mappings) do
      if (v==v2) then
        self.mappings[v].group_name = mappings[v].group_name
        self.mappings[v].index = mappings[v].index
      end
    end
  end

end


--------------------------------------------------------------------------------

-- todo: assign matching options

function Application:apply_options(options)

--[[
  for v,k in pairs(self.options) do

    for v2,k2 in pairs(options) do

  self.options.play_mode.value = options.play_mode.value
  self.options.switch_mode.value = options.switch_mode.value
  self.options.out_of_bounds.value = options.out_of_bounds.value
      if (v==v2) then

        self.options[v].value = options[v].value

      end

    end

  end

]]

end

--------------------------------------------------------------------------------

-- called when a new document becomes available

function Application:on_new_document()
  -- nothing done by default
end


--------------------------------------------------------------------------------

function Application:__create_dialog()
  TRACE("Application:__create_dialog()")
  
  self.dialog = renoise.app():show_custom_dialog(
    type(self), self.view
  )
end

--------------------------------------------------------------------------------

-- set options to default values (only locally)
-- @skip_update : don't update the dialog 
--  todo: remove the skip_update argument when we get a proper way to check 
--  if .views is defined

function Application:__set_default_options(skip_update)
  TRACE("Application:__set_default_options()")

  -- set local value
  for k,v in pairs(self.options) do
    self.options[k].value = self.options[k].default

    if(not skip_update)then
      local elm = self.vb.views[("dpx_app_options_%s"):format(k)]
      if(elm)then
        if(type(elm.value)=="boolean")then -- checkbox
          elm.value = self.options[k].items[self.options[k].default]
        else -- popup
          elm.value = self.options[k].default
        end
      end
    end

  end



end

--------------------------------------------------------------------------------

-- set option value 

function Application:__set_option(name,value)

  -- set local value
  for k,v in pairs(self.options) do
    if (k==name) then
      self.options[k].value = value
    end
  end
  -- set value in browser 
  if (self.browser) and
   (self.browser.__devices) then
    for k,v in pairs(self.browser.__devices) do
      if(v.display_name == self.device_display_name)then
        if(not v.options)then
          v.options = {}
        end
        v.options[name] = {
          value = value
        }
        break
      end
    end
  end

end

--------------------------------------------------------------------------------

function Application:__tostring()
  return type(self)
end  

--------------------------------------------------------------------------------

function Application:__eq(other)
  -- only check for object identity
  return rawequal(self, other)
end  

--------------------------------------------------------------------------------

-- create application options dialog

function Application:build_options()

  if(self.view)then
    return
  end

  -- create basic dialog 
  self.view = self.vb:column{
    id = 'dpx_app_rootnode',
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_MARGIN,
    style = "body",
    width=400,
    self.vb:column{
      style = "group",
      width="100%",
      self.vb:column{
        margin = DEFAULT_MARGIN,
        spacing = DEFAULT_SPACING,
        id = "dpx_app_mappings",
        self.vb:row{
          self.vb:text{
            id="dpx_app_mappings_header",
            text="",
            width=200,
          },
        },
        -- mappings are inserted here
      },
      self.vb:space{
        width=18,
      },
    },
    self.vb:column{
      style = "group",
      width="100%",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,
      id = "dpx_app_options",
      self.vb:text{
        id="dpx_app_options_header",
        text="",
        width=200,
      },
      -- options are inserted here
    },
    self.vb:column{
      id="dpx_app_advanced",
      visible=false,
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,

      self.vb:horizontal_aligner{
        mode = "justify",
        width = 400,
        self.vb:column{
          self.vb:row{
            self.vb:checkbox{
              value=true,
              width=18,
              notifier = function(v)
                self:set_pinned(v)
              end
            },
            self.vb:text{
              text="Pinned to menu",
            },
          },
         self.vb:row{
            self.vb:checkbox{
              value=false,
              width=18,
            },
            self.vb:text{
              text="Auto-run",
            },
          },
        },
          self.vb:space{
            width=80,
          },
        self.vb:column{
          self.vb:text{
            text="#Aliases",
          },
          self.vb:valuebox{
            value=1,
          },
        },
      },
    },
    self.vb:horizontal_aligner{
      mode = "justify",

      self.vb:row{
        self.vb:row{
          margin = DEFAULT_MARGIN,
          self.vb:checkbox{
            id="dpx_app_options_running",
            value=true,
            width=18,
            notifier = function(v)
              -- update options dialog and browser (if present, and 
              -- the current application is focused)
              local app,cb = nil,nil
              local is_current_app = false
              if(self.browser)then
                app = self.browser:__get_selected_app()
                cb = self.browser.vb.views.dpx_browser_application_checkbox
                if(app and app==self)then
                  is_current_app = true
                end
              end

              if v then
                self:start_app()
              else
                self:stop_app()
              end
              if(is_current_app)then
                -- update browser checkbox/list
                cb.value = v
              else
                -- update the browser app list only
                self.browser:__decorate_app_list()
              end
            end
          },
          self.vb:text{
            text="Running",
          },
        },
      },

      self.vb:row{
        -- toggle the advanced controls
        self.vb:row{
          margin = DEFAULT_MARGIN,
          self.vb:button{
            id="dpx_app_pin",
            text="▼",
            width=18,
            height=18,
            pressed = function(e)
              local elm = self.vb.views.dpx_app_pin
              local elm2 = self.vb.views.dpx_app_advanced
              if (elm.text == "▼") then
                elm.text="▲"
                elm2.visible=true
              else
                elm.text="▼"
                elm2.visible=false
              end
              self.vb.views.dpx_app_rootnode:resize()
            end
          },
        },
        self.vb:button{
          text="Reset",
          width=60,
          height=24,
          notifier = function(e)
            self:__set_default_options()
          end
        },
        self.vb:button{
          text="Close",
          width=60,
          height=24,
          notifier = function(e)
            self:hide_app()
          end
        },
      }
    }
  }
  
  -- populate view with data
  local elm_group,elm_header

  -- mappings
  elm_group = self.vb.views.dpx_app_mappings
  elm_header = self.vb.views.dpx_app_mappings_header

  if (self.mappings) then
    -- update header text
    if (table_count(self.mappings)>0) then
      elm_header.text = "Control-map assignments, valid for this device"
    else
      elm_header.text = "No mappings are available"
    end
    -- build rows (required comes first)
    for k,v in pairs(self.mappings) do
      if(v.required)then 
        elm_group:add_child(self:__add_mapping_row(v,k))
      end
    end
    for k,v in pairs(self.mappings) do
      if(not v.required)then 
        elm_group:add_child(self:__add_mapping_row(v,k))
      end
    end
  end

  -- options
  elm_group = self.vb.views.dpx_app_options
  elm_header = self.vb.views.dpx_app_options_header
  if (self.options)then
    -- update header text
    if (table_count(self.options)>0) then
      elm_header.text = "Other options, valid for this instance"
    else
      elm_header.text = "No options are available"
    end
    -- build rows (popups)
    for k,v in pairs(self.options) do
      if (v.items) and (type(v.items[1])~="boolean") then
        elm_group:add_child(self:__add_option_row(v,k))
      end
    end
    -- build rows (checkbox)
    for k,v in pairs(self.options) do
      if (v.items) and (type(v.items[1])=="boolean") then
        elm_group:add_child(self:__add_option_row(v,k))
      end
    end
  end
end

--------------------------------------------------------------------------------

-- update the "pinned" status of this application
-- (requires that the browser is present)

function Application:set_pinned(val)
  if(self.browser)then
    local matched = false
    for k,v in ipairs(self.browser.__devices)do
      if(matched)then break end
      if(v.pinned) and
        (v.display_name==self.device_display_name) then
        for k2,v2 in pairs(v.pinned) do
          if(k2==self.app_display_name)then
            matched = true
            if(not val)then
              v.pinned[k2] = nil
              break
            end
          end
        end
        if (val) and (not matched) then
          v.pinned[self.app_display_name] = ("%s %s..."):format(self.device_display_name,self.app_display_name)
          break
        end
      end
    end
    self.browser:build_menu()
  end
end

--------------------------------------------------------------------------------

-- build a row of mapping controls
-- @return ViewBuilder view

function Application:__add_mapping_row(t,key)

  local elm
  local row = self.vb:row{}

  -- leave out checkbox for required maps
  if(t.required)then 
    elm = self.vb:space{
      width=18,
    }
  else
    elm = self.vb:checkbox{
      value=(t.group_name~=nil),
      width=18,
    }
  end
  row:add_child(elm)
  elm = self.vb:row{
    self.vb:text{
      text=key,
      tooltip=t.description,
      width=70,
    },
    self.vb:row{
      style="border",
      self.vb:text{
        text=t.group_name,
        font="mono",
        width=110,
      },
      self.vb:button{
        text="Choose",
        width=60,
      }
    }
  }
  row:add_child(elm)
  return row

end

--------------------------------------------------------------------------------

-- build a row of option controls
-- @return ViewBuilder view

function Application:__add_option_row(t,key)

  local elm
  local row = self.vb:row{}

  if (t.items) and (type(t.items[1])=="boolean") then
    -- boolean option
    elm = self.vb:row{
      self.vb:checkbox{
        value=t.items[t.value],
        id=('dpx_app_options_%s'):format(key),
        width=18,
        --id = checkbox_id,
        notifier = function(val)
          self:__set_option(key,val)
        end
      },
      self.vb:text{
        text=t.label,
        tooltip=t.description,
      },
    }
  else
    -- choice
      elm = self.vb:row{
        self.vb:text{
          text=t.label,
          --tooltip=t.label,
          width=90,
        },
        self.vb:popup{
          items=t.items,
          id=('dpx_app_options_%s'):format(key),
          value=t.value,
          width=160,
          notifier = function(val)
            self:__set_option(key,val)
          end
        }
      }
  end

  row:add_child(elm)
  return row

end
