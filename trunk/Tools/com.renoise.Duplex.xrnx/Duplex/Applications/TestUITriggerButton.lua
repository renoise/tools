--[[----------------------------------------------------------------------------
-- Duplex.TestUITriggerButton
----------------------------------------------------------------------------]]--

--[[

About

This class is for testing the UITriggerButton functionality

Mappings

grid  8x8 buttons
row   1x8 buttons

--]]

--==============================================================================


class 'TestUITriggerButton' (Application)

function TestUITriggerButton:__init(display,mappings,options)
  TRACE("TestUITriggerButton:__init(",display,mappings,options)

  self.mappings = {
    grid = {},
    row = {},
  }

  self.display = display

  self:__apply_mappings(mappings)

  if(self.mappings.grid.group_name)then

    -- default button, yellow fade
    local c = UITriggerButton(display)
    c.group_name = self.mappings.grid.group_name
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
    c.group_name = self.mappings.grid.group_name
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
        c.group_name = self.mappings.grid.group_name
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
      c.group_name = self.mappings.grid.group_name
      c.x_pos = col
      c.y_pos = 5
      c:set_size(1,4)
      c.loop = true
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

  -- row of default buttons
  -- for testing with LED based buttons
  if(self.mappings.row.group_name)then
    for col=1,8 do
      local c = UITriggerButton(display)
      c.group_name = self.mappings.row.group_name
      c.x_pos = col
      c.y_pos = 1
      if(col>4)then
        --c.loop = true
      else

      end
      c.on_change = function(obj)
        return self.active
      end
      self.display:add(c)
    end
  end


end

