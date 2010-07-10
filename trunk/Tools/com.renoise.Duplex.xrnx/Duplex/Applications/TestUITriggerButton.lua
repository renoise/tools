--[[----------------------------------------------------------------------------
-- Duplex.TestUITriggerButton
----------------------------------------------------------------------------]]--

--[[

About

This class is for testing the UITriggerButton functionality

Requires an 8x8 grid for testing


--]]

--==============================================================================


class 'TestUITriggerButton' (Application)

function TestUITriggerButton:__init(display,mappings,options)
  print("TestUITriggerButton:__init(",display,mappings,options)

rprint(mappings)

  self.display = display

  -- default button, yellow fade
	local c = UITriggerButton(display)
  c.group_name = mappings.grid.group_name
  c.x_pos = 1
  c.y_pos = 1
  c:set_size(4,4)
  c.sequence = {
    {color={0xff,0xff,0xff}},
    {color={0x80,0x80,0xff}},
    {color={0x40,0x40,0xff}},
    {color={0x00,0x00,0x00}}
  }
  c.on_change = function(obj)
    return self.active
  end
  self.display:add(c)

  -- long delay time
	local c = UITriggerButton(display)
  c.group_name = mappings.grid.group_name
  c.x_pos = 5
  c.y_pos = 1
  c.interval = 5
  c:set_size(4,4)
  c.sequence = {
    {color={0xff,0xff,0xff},text="■"},
    {color={0x00,0x00,0x00}}
  }
  c.on_change = function(obj)
    return self.active
  end
  self.display:add(c)
  c:trigger() -- trigger immidiately

  -- 4x4 grid of defaults
  for col=1,4 do
    for row=5,8 do
      local c = UITriggerButton(display)
      c.group_name = mappings.grid.group_name
      c.x_pos = col
      c.y_pos = row
      c.on_change = function(obj)
        return self.active
      end
      self.display:add(c)
    end
  end

  -- green columns
  for col=5,8 do
    local c = UITriggerButton(display)
    c.group_name = mappings.grid.group_name
    c.x_pos = col
    c.y_pos = 5
    c:set_size(1,4)
    c.sequence = {
      {color={0x80,0xff,0xff}},
      {color={0x40,0x80,0xff}},
      {color={0x00,0x40,0xff}},
      {color={0x00,0x00,0x00}}
    }
    c.on_change = function(obj)
      return self.active
    end
    self.display:add(c)
  end


end

