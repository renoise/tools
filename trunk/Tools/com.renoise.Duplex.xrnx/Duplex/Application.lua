--[[----------------------------------------------------------------------------
-- Duplex.Application
----------------------------------------------------------------------------]]--

--[[

A generic application class for Duplex

--]]


--==============================================================================

class 'Application'

-- constructor 
function Application:__init()
  TRACE("Application:__init()")
  
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

  -- define a default palette for the application
  -- todo: this will enable color-picker support
  self.palette = {}


  -- private stuff

  -- true when content (UIComponents etc.) have been created
  self.__created = false
  
  -- the options dialog and view

  self.__vb = renoise.ViewBuilder()

  self.__options_view = nil
  self.__options_dialog = nil
end


--------------------------------------------------------------------------------

-- start/resume application

function Application:start_app()
  TRACE("Application:start_app()")
  
  if (self.active) then
    return
  end

  self.active = true
end


--------------------------------------------------------------------------------

-- stop application

function Application:stop_app()
  TRACE("Application:stop_app()")
  
  if (not self.active) then
    return
  end

  self.active = false
end


--------------------------------------------------------------------------------

-- create application

function Application:__build_app()
  TRACE("Application:__build_app()")
  
  self.__created = true
end


--------------------------------------------------------------------------------

-- destroy application

function Application:destroy_app()
  TRACE("Application:destroy_app()")
  
  self:hide_options_dialog()
  self:stop_app()
  
  self.__created = false
end


--------------------------------------------------------------------------------

-- display application options

function Application:show_options_dialog()
  TRACE("Application:show_options_dialog()")
  
  if (not self.__options_dialog or not self.__options_dialog.visible) then
    self.__options_dialog = renoise.app():show_custom_dialog(
      type(self), self.__options_view)
  else
    self.__options_dialog:show()
  end
end


--------------------------------------------------------------------------------

-- hide application options

function Application:hide_options_dialog()
  TRACE("Application:hide_options_dialog()")
  
  if (self.__options_dialog) and (self.__options_dialog.visible) then
    self.__options_dialog:close()
    self.__options_dialog = nil
  end
end


--------------------------------------------------------------------------------

-- handle periodic updates (many times per second)
-- nothing is done by default

function Application:on_idle()
  -- TRACE("Application:on_idle()")
  
--[[
  -- it's a good idea to include this check when doing complex stuff:
  if (not self.active) then 
    return 
  end
]]

end


--------------------------------------------------------------------------------

-- called when a new document becomes available

function Application:on_new_document()
  TRACE("Application:on_new_document()")
  
  -- nothing done by default
end


--------------------------------------------------------------------------------

-- assign matching group-names

function Application:__apply_mappings(mappings)
  TRACE("Application:__apply_mappings",mappings)
  
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

-- assign matching options

function Application:__apply_options(options)
  TRACE("Application:__apply_options",options)

  for v,k in pairs(self.options) do
    local matched = false
    for v2,k2 in pairs(options) do
      if (v==v2) then
        if(#self.options[v].items>=options[v])then
          self.options[v].value = options[v]
          matched = true
        end
      end
    end
    if (not matched) then
      -- apply default value
      self.options[v].value = self.options[v].default
    end
  end

end


--------------------------------------------------------------------------------

-- create application options dialog

function Application:__build_options()
  TRACE("Application:__build_options")
  
  if (self.__options_view)then
    return
  end
 
  local vb = self.__vb 
  
  -- create basic dialog 
  self.__options_view = vb:column{
    id = 'dpx_app_rootnode',
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_MARGIN,
    style = "body",
    width=400,
    vb:column{
      style = "group",
      width="100%",
      vb:column{
        margin = DEFAULT_MARGIN,
        spacing = DEFAULT_SPACING,
        id = "dpx_app_mappings",
        vb:row{
          vb:text{
            id="dpx_app_mappings_header",
            font="bold",
            text="",
          },
        },
        -- mappings are inserted here
      },
      vb:space{
        width=18,
      },
    },
    vb:column{
      style = "group",
      width="100%",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,
      id = "dpx_app_options",
      vb:text{
        id="dpx_app_options_header",
        font="bold",
        text="",
      },
      -- options are inserted here
    },

    vb:horizontal_aligner{
      mode = "justify",

      vb:row{
        vb:button{
          text="Reset",
          width=60,
          height=24,
          notifier = function(e)
            self:__set_default_options()
          end
        },
        vb:button{
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
  elm_group = vb.views.dpx_app_mappings
  elm_header = vb.views.dpx_app_mappings_header

  if (self.mappings) then
    -- update header text
    if (table_count(self.mappings)>0) then
      elm_header.text = "Control-map assignments"
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
  elm_group = vb.views.dpx_app_options
  elm_header = vb.views.dpx_app_options_header
  if (self.options)then
    -- update header text
    if (table_count(self.options)>0) then
      elm_header.text = "Other options"
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
--                         Private Helper Functions
--------------------------------------------------------------------------------

-- build a row of mapping controls
-- @return ViewBuilder view

function Application:__add_mapping_row(t,key)

  local vb = self.__vb
  local row = vb:row{}

  local elm

  -- leave out checkbox for required maps
  if(t.required)then 
    elm = vb:space{
      width=18,
    }
  else
    elm = vb:checkbox{
      value=(t.group_name~=nil),
      tooltip="Set this assignment as active/inactive",
      width=18,
    }
  end
  row:add_child(elm)
  elm = vb:row{
    vb:text{
      text=key,
      tooltip=("Assignment description: %s"):format(t.description),
      width=70,
    },
    vb:row{
      style="border",
      vb:text{
        text=t.group_name,
        tooltip="The selected control-map group",
        font="mono",
        width=110,
      },
      vb:button{
        text="Choose",
        tooltip="Click here to choose a control-map group for this assignment",
        width=60,
        notifier = function()
          renoise.app():show_warning("Mapping dialog not yet implemented")
        end
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

  local vb = self.__vb
  local row = vb:row{}

  local elm

  if (t.items) and (type(t.items[1])=="boolean") then
    -- boolean option
    elm = vb:row{
      vb:checkbox{
        value=t.items[t.value],
        id=('dpx_app_options_%s'):format(key),
        width=18,
        --id = checkbox_id,
        notifier = function(val)
          self:__set_option(key,val)
        end
      },
      vb:text{
        text=t.label,
        tooltip=t.description,
      },
    }
  
  else
    -- choice
      elm = vb:row{
        vb:text{
          text=t.label,
          --tooltip=t.label,
          width=90,
        },
        vb:popup{
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
      local elm = vb.views[("dpx_app_options_%s"):format(k)]
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

function Application:__set_option(name, value)

  -- set local value
  for k,v in pairs(self.options) do
    if (k == name) then
      self.options[k].value = value
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

