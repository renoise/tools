--[[============================================================================
vArrowButton 
============================================================================]]--
--[[

A button which emulates the 'toggle arrow' button in Renoise

]]

--==============================================================================

require (_vlibroot.."vToggleButton")

class 'vArrowButton' (vToggleButton)

vArrowButton.ORIENTATION = {
  HORIZONTAL = 1,
  VERTICAL = 2,
}

vArrowButton.BUTTONS = {
  HORIZONTAL = {"◂","▸"},
  VERTICAL = {"▾","▴"},
}

vArrowButton.BITMAPS = {
  HORIZONTAL = {"ArrowLeft.bmp","ArrowRight.bmp"},
  VERTICAL = {"ArrowDown.bmp","ArrowUp.bmp"},
}

--------------------------------------------------------------------------------

function vArrowButton:__init(...)
  TRACE("vArrowButton:__init()")

  local args = cLib.unpack_args(...)

  -- properties -----------------------

  self.orientation = property(self.get_orientation,self.set_orientation)
  self.orientation_observable = renoise.Document.ObservableNumber(args.orientation or vArrowButton.ORIENTATION.VERTICAL)

  self.flipped = property(self.get_flipped,self.set_flipped)
  self.flipped_observable = renoise.Document.ObservableBoolean(args.flipped or true)

  -- override default value
  args.width = args.width or vLib.CONTROL_H
  args.height = args.height or vLib.CONTROL_H
  args.color_enabled = vLib.COLOR_SELECTED
  args.color_disabled = vLib.COLOR_NORMAL

  -- internal -------------------------

	vToggleButton.__init(self,...)
  self:update_text()

  self:update()

end

--------------------------------------------------------------------------------

function vArrowButton:update_text()

  local buttons = (self.orientation == vArrowButton.ORIENTATION.HORIZONTAL) 
    and vArrowButton.BUTTONS.HORIZONTAL or vArrowButton.BUTTONS.VERTICAL
  self.text_enabled = self.flipped and buttons[2] or buttons[1]
  self.text_disabled = self.flipped and buttons[1] or buttons[2]

  self:request_update()

end

--------------------------------------------------------------------------------

function vArrowButton:set_orientation(val)
  self.orientation_observable.value = val
  self:update_text()
end

function vArrowButton:get_orientation()
  return self.orientation_observable.value
end

--------------------------------------------------------------------------------

function vArrowButton:set_flipped(val)
  self.flipped_observable.value = val
  self:update_text()
end

function vArrowButton:get_flipped()
  return self.flipped_observable.value
end


