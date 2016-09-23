--[[============================================================================
vFileBrowser 
============================================================================]]--

--[[

A UI component for selecting/display a filesystem (file-)path

#
.

## Features

  * Specify a file or folder location ("mode")
  * Ability to copy/paste/edit path manually ("editable")
  * Validate as path is edited ("path_is_valid") 
  * Additional views ("browse_button")  

## Events

  


--]]

--==============================================================================

require (_vlibroot.."vControl")

class 'vPathSelector' (vControl)

vPathSelector.MODE = {
  FILE = 1,
  FOLDER = 2,
}

vPathSelector.BROWSE_BUTTON_W = 55

--------------------------------------------------------------------------------

function vPathSelector:__init(...)
  TRACE("vPathSelector:__init(...)")

  local args = cLib.unpack_args(...)

  --print("args",rprint(args))

  --- vPathSelector.MODE
  self.mode = property(self.get_mode,self.set_mode)
  self._mode = args.mode or vPathSelector.MODE.FOLDER
  
  --- bool, set when path can be manually edited
  self.editable = property(self.get_editable,self.set_editable)
  self._editable = args.editable or true

  --- string, the current (file-)path
  self.path = property(self.get_path,self.set_path)
  self._path = args.path or ""

  self.path_token = property(self.get_path_token,self.set_path_token)
  self._path_token = args.path_token or "(unspecified)"

  --- function
  self.notifier = args.notifier or nil

  --- bool, when true the component will not accept invalid locations
  -- TODO 
  self.require_existing = args.require_existing or true

  -- internal --

  self.vb_textfield = nil
  self.vb_browse_button = nil

  -- initialize --

  vControl.__init(self,...)

  self._height = args.height or vLib.CONTROL_H

  -- done --

  self:build()

end

--------------------------------------------------------------------------------

function vPathSelector:build()
  TRACE("vPathSelector:build()")

  local vb = self.vb

  self.vb_textfield = vb:textfield{
    text = "Path goes here...",
    notifier = function(val)
      self:set_path(val)
    end
  }
  self.vb_browse_button = vb:button{
    text = "Browse",
    notifier = function()
      self:browse_for_path()
    end
  }

  self.view = vb:row{
    id = self.id,
    self.vb_textfield,
    self.vb_browse_button,
  }

  self:request_update()

  vControl.build(self)

end

--------------------------------------------------------------------------------
-- (overridden)

function vPathSelector:set_width(val)
  TRACE("vPathSelector:set_width(val)",val)

  if (val < vPathSelector.BROWSE_BUTTON_W) then
    val = vPathSelector.BROWSE_BUTTON_W
  end

  if self.vb_textfield then
    self.vb_textfield.width = val-vPathSelector.BROWSE_BUTTON_W
  end
  
  if self.vb_browse_button then
    self.vb_browse_button.width = vPathSelector.BROWSE_BUTTON_W
  end

  vControl.set_width(self,val)

end

--------------------------------------------------------------------------------
-- (overridden)

function vPathSelector:set_height(val)
  TRACE("vPathSelector:set_height(val)",val)

  if self.vb_textfield then
    self.vb_textfield.height = val
  end
  
  if self.vb_browse_button then
    self.vb_browse_button.height = val
  end

  vControl.set_height(self,val)

end

--------------------------------------------------------------------------------
-- (overridden)

function vPathSelector:update()
  TRACE("vPathSelector:update()")

  if self.vb_textfield then
    if (self._path == "") then
      self.vb_textfield.text = self._path_token 
    else
      self.vb_textfield.text = self._path 
    end
  end

  self:set_height(self._height)
  self:set_width(self._width)

end

--------------------------------------------------------------------------------

function vPathSelector:browse_for_path()
  TRACE("vPathSelector:browse_for_path()")

  local str_path = renoise.app():prompt_for_path("Select a folder")
  if (str_path ~= "") then
    self:set_path(str_path)
  end

end

--------------------------------------------------------------------------------
--- @return bool, true if path is not malformed or otherwise invalid

function vPathSelector:path_is_valid()

  -- TODO include check for "require_existing"

  return true

end

--------------------------------------------------------------------------------

function vPathSelector:get_mode()

end

function vPathSelector:set_mode()

end

--------------------------------------------------------------------------------

function vPathSelector:get_editable()

end

function vPathSelector:set_editable()

end

--------------------------------------------------------------------------------

function vPathSelector:get_path()

  return self._path

end

function vPathSelector:set_path(val)
  TRACE("vPathSelector:set_path(val)",val)

  assert(type(val)=="string")
  self._path = val

  if self.notifier then
    self.notifier(val)
  end

  self:request_update()

end

--------------------------------------------------------------------------------

function vPathSelector:get_path_token()

  return self._path_token

end

function vPathSelector:set_path_token(val)

  assert(type(val)=="string")
  self._path_token = val

  self:request_update()

end

