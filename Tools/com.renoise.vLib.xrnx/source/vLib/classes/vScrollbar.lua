--[[============================================================================
vScrollbar
============================================================================]]--

require (_vlibroot.."vControl")

class 'vScrollbar' (vControl)

--------------------------------------------------------------------------------
--- An emulated scrollbar widget (using a minislider)

vScrollbar.ORIENTATION = {
  HORIZONTAL = 1,
  VERTICAL = 2
}

--- Placement of buttons
vScrollbar.BUTTON_LAYOUT = {
  HIDDEN = 1, -- do not show buttons
  ABOVE = 2,  -- show buttons above track
  BELOW = 3,  -- show buttons below track
  BOTH = 4,   -- show buttons on either side 
}

-- Default values
vScrollbar.DEFAULT_H = 100
vScrollbar.DEFAULT_W = 20
vScrollbar.DEFAULT_BUTTON_H = 20
vScrollbar.DEFAULT_STEP_SIZE = 1
vScrollbar.MINIMUM_TRACK_H = 20

local function flip(val)
  return math.abs(val - 1)
end


function vScrollbar:__init(...)
  TRACE("vScrollbar:__init()")

  local args = cLib.unpack_args(...)

  -- properties -----------------------

  --- (int) 
  self.button_height = property(self.get_button_height,self.set_button_height)
  self._button_height = args.button_height or vScrollbar.DEFAULT_BUTTON_H

  --- (number) scroll position, between 0-1
  self.position = property(self.get_position,self.set_position)
  self._position = args.position or 0

  --- (vScrollbar.BUTTON_LAYOUT) 
  self.button_layout = vScrollbar.BUTTON_LAYOUT.BOTH

  --- (vScrollbar.ORIENTATION)
  self.orientation = args.orientation or vScrollbar.ORIENTATION.VERTICAL

  --- (int) 1-[step_count] derived from position
  self.index = property(self.get_index,self.set_index)

  --- (int) the number of "steps"
  self.step_count = 10
  
  --- (int) how far to travel when navigation button is pressed
  self.step_size = args.step_size or vScrollbar.DEFAULT_STEP_SIZE

  --- (function) callbacks for when changed
  -- @param elm (vScrollbar)
  self.do_change = args.do_change or nil
 
  -- internal -------------------------

  -- (string) unique identifier for views
  self.uid = vLib.generate_uid()

  self.bt1 = nil
  self.bt2 = nil
  self.track = nil

  vControl.__init(self,...)
  self:build()

  self.width = args.width or vScrollbar.DEFAULT_W
  self.height = args.height or vScrollbar.DEFAULT_H

end

--------------------------------------------------------------------------------

function vScrollbar:build()
  TRACE("vScrollbar:build()")

  local vb = self.vb

  if (self.orientation == vScrollbar.ORIENTATION.VERTICAL) then

    self.view = vb:vertical_aligner {
      id = self.id,
      margin = 0,
      spacing = 0,
      mode = "justify",
    }

    self.bt1 = vb:button {
      height = self._button_height,
      width = self._width,
      text = "▲",
      notifier = function()
        self:on_arrow_up()
      end,
    }

    self.bt2 = vb:button {
      height = self._button_height,
      width = self._width,
      text = "▼",
      notifier = function()
        self:on_arrow_down()
      end,
    }

    self.track = vb:minislider {
      height = self._height,
      width = self._width,
      notifier = function()
        self:on_track_change()
      end,
      value = flip(self._position),
    }

    if (self.button_layout == vScrollbar.BUTTON_LAYOUT.NONE) then
      self.view:add_child(self.track)
    elseif (self.button_layout == vScrollbar.BUTTON_LAYOUT.ABOVE) then
      self.view:add_child(self.bt1)
      self.view:add_child(self.bt2)
      self.view:add_child(self.track)
    elseif (self.button_layout == vScrollbar.BUTTON_LAYOUT.BELOW) then
      self.view:add_child(self.track)
      self.view:add_child(self.bt1)
      self.view:add_child(self.bt2)
    elseif (self.button_layout == vScrollbar.BUTTON_LAYOUT.BOTH) then
      self.view:add_child(self.bt1)
      self.view:add_child(self.track)
      self.view:add_child(self.bt2)
    end

  else
    error("Not implemented")
  end

end

--------------------------------------------------------------------------------

function vScrollbar:set_width(val)
  TRACE("vScrollbar:set_width(val)",val)

  self.track.width = val
  self.bt1.width = val
  self.bt2.width = val

  vControl.set_width(self,val)

end

--------------------------------------------------------------------------------

function vScrollbar:set_height(val)
  TRACE("vScrollbar:set_height(val)",val)

  local track_h = val
  if (self.button_layout ~= vScrollbar.BUTTON_LAYOUT.NONE) then
    track_h = track_h - (self._button_height * 2)
  end

  if (track_h < vScrollbar.MINIMUM_TRACK_H) then
    -- divide the size equally among the three
    self.track.height = val/3
    self.bt1.height = val/3
    self.bt2.height = val/3
  else
    self.track.height = track_h
    self.bt1.height = self._button_height
    self.bt2.height = self._button_height
  end

  vControl.set_height(self,val)

end

--------------------------------------------------------------------------------

function vScrollbar:set_button_height(val)
  TRACE("vScrollbar:disable()")

  self._button_height = val
  if self.bt1 then
    self.bt1.height = val
  end
  if self.bt2 then
    self.bt2.height = val
  end

  self:set_height(val)

end

function vScrollbar:set_button_height(val)
  return self._button_height
end

--------------------------------------------------------------------------------

function vScrollbar:set_position(num)
  TRACE("vScrollbar:set_position(num)",num)

  self._position = math.max(0,math.min(1,num))
  self.track.value = flip(self._position)

end

function get_position()
  return self._position
end

--------------------------------------------------------------------------------

function vScrollbar:on_arrow_up()
  TRACE("vScrollbar:on_arrow_up()")

  local step_increment = 1 / self.step_count
  local pos = self._position - (step_increment*self.step_size)
  pos = math.max(0,pos)
  self:set_position(pos)

end

--------------------------------------------------------------------------------

function vScrollbar:on_arrow_down()
  TRACE("vScrollbar:on_arrow_down()")

  local step_increment = 1 / self.step_count
  local pos = self._position + (step_increment*self.step_size)
  pos = math.min(1,pos)
  self:set_position(pos)

end

--------------------------------------------------------------------------------

function vScrollbar:on_track_change()
  TRACE("vScrollbar:on_track_change()")

  self._position = flip(self.track.value)

  if self.do_change then
    self.do_change(self)
  end

end

--------------------------------------------------------------------------------

function vScrollbar:set_active(val)
  TRACE("vScrollbar:disable()")

  self.track.visible = val
  --self.track.active = val
  self.bt1.active = val
  self.bt2.active = val

  vControl.set_active(self,val)

end

--------------------------------------------------------------------------------


function vScrollbar:set_index(idx)
  TRACE("vScrollbar:set_index(idx)",idx)

  local val = idx/self.step_count
  self:set_position(val)
  
end

function vScrollbar:get_index()
  TRACE("vScrollbar:get_index()")
  
  local inc = 1 / self.step_count
  return math.max(0,math.floor((self._position/inc)+0.5))
  
end

