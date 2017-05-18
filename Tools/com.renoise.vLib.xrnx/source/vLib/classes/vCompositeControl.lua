--[[============================================================================
vCompositeControl
============================================================================]]--

--[[

  Extend vControl with 'views', to support the main class with 
  features that are not bound to any specific layout 
  
  ## How to use

  -- Use a table to describe the expected views 
  vCompositeControl.VIEWS = {
    'my_view'
  }

  -- Register the names like this
  self:register_views(vCompositeControl.VIEWS)

  -- Then add/remove views as needed
  self:add_view(some_external_view,'my_view')
  self:remove_view('my_view')

--]]

--------------------------------------------------------------------------------

require (_vlibroot.."vControl")

class 'vCompositeControl' (vControl)

function vCompositeControl:__init(...)
  TRACE("vCompositeControl:__init(t)")

  -- table<string> viewbuilder/vLib component names
  self.views = {}

  self.__vb_views = {}
  self.__vb_owners = {}

  vControl.__init(self,...)

end


--------------------------------------------------------------------------------
-- @param t (table), 

function vCompositeControl:register_views(t)
  TRACE("vCompositeControl:register_views(t)",t,rprint(t))

  for k,v in ipairs(t) do
    if not table.is_empty(self.views) 
      and table.find(self.views,v) 
    then
      -- skip entry, already registered
    else
      table.insert(self.views,v)
    end
  end

end

--------------------------------------------------------------------------------
-- @param view (View)
-- @param vb_owner (Viewbuilder)

function vCompositeControl:add_view(view,vb_owner)
  TRACE("vCompositeControl:add_view(view,vb_owner)",view,vb_owner)

  local idx = table.find(self.views,view)
  local view = self.views[idx]
  assert(view,"Expected one of the registered views: "..self:concat_views())

  local vb_view = self[self.views[idx]]
  vb_owner:add_child(vb_view)
  self.__vb_owners[idx] = vb_owner
  self.__vb_views[idx] = vb_view

end

--------------------------------------------------------------------------------
-- @param vb_owner (Viewbuilder)
-- @param view (View)

function vCompositeControl:remove_view(vb_owner,view)
  TRACE("vCompositeControl:remove_view(vb_owner,view)",vb_owner,view)

  local idx = table.find(self.views,view)
  local view = self.views[idx]
  assert(view,"Expected one of the registered views: "..self:concat_views())

  local vb_owner = self.view_owners[idx]
  vb_owner:remove_child(view)
  self.__vb_owners[idx] = nil
  self.__vb_views[idx] = nil

end

--------------------------------------------------------------------------------
-- @return string, e.g. "my_view,another_view"

function vCompositeControl:concat_views()

  return table.concat(self.views,",")

end

