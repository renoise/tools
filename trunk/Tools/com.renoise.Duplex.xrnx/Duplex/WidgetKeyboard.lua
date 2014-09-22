--[[============================================================================
-- Duplex.WidgetKeyboard
============================================================================]]--

--[[--

A custom widget for visualizing an on-screen keyboard 

--]]

--==============================================================================

local KEYS_COLOR_WHITE            = {0x9F,0x9F,0x9F}
local KEYS_COLOR_WHITE_PRESSED    = {0xCF,0xCF,0xCF}
local KEYS_COLOR_WHITE_DISABLED   = {0x5F,0x5F,0x5F}
local KEYS_COLOR_BLACK            = {0x00,0x00,0x00}
local KEYS_COLOR_BLACK_PRESSED    = {0x6F,0x6F,0x6F}
local KEYS_COLOR_BLACK_DISABLED   = {0x3F,0x3F,0x3F}
local KEYS_COLOR_OUT_OF_BOUNDS    = {0x46,0x47,0x4B}

local KEYS_WIDTH = 28
local KEYS_MIN_WIDTH = 18 
local KEYS_HEIGHT = 64


class 'WidgetKeyboard'


function WidgetKeyboard:__init(...)

  local display,param,width,height,tooltip = select(1,...)

	--- (OscVoiceMgr) this is where we get our active voices from
	self.voicemgr = nil

	--- (table) the control-map parameter that define this widget
  self.param = param

	--- (Display) where we direct our messages
  self.display = display

  --- viewbuilder id
  self.id = param.xarg.id

  --- transpose down
  self.oct_dn = nil

  --- transpose up
  self.oct_up = nil

	--- (int) number of keys 
  self.range = param.xarg.range

	--- (bool) add octave buttons on either side
  self.show_octave = true

	--- (int) upper boundary
  self.upper_note = nil  

	--- (int) lower boundary
  self.lower_note = nil  

	--- (int) current octave (as seen in the left side)
  self.octave = 4

	--- (number) relative width 
  self.width = width

  --- (number) relative height
  self.height = height

  --- (string) 
  self.tooltip = tooltip

  --- (int) the channel used when generating output
  self.channel = 1

  --- (table) list of pressed keys
  self.pressed_keys = {}

  --- (table) list of disabled keys
  self.disabled_keys = {}

  --- (table) visual state for each key, indexed by pitch
  -- if not specified, defaults to KEYS_COLOR_WHITE etc.
  -- {
  --  white           = {r,g,b},
  --  white_pressed   = {r,g,b},
  --  white_disabled  = {r,g,b},
  --  black           = {r,g,b},
  --  black_pressed   = {r,g,b},
  --  black_disabled  = {r,g,b},
  -- }
  self.keystates = {}

end


function WidgetKeyboard:build()

	local keys_width = KEYS_WIDTH
	local keys_height = KEYS_HEIGHT

  local param = self.param
  local vb = self.display.vb
  local content_id = ("%s_content"):format(self.id)
  local oct_up_id = ("%s_octave_up"):format(self.id)
  local oct_dn_id = ("%s_octave_down"):format(self.id)

	if param.xarg.size then
    keys_width = KEYS_WIDTH * param.xarg.size
    keys_height = KEYS_HEIGHT * param.xarg.size
	end

	if param.xarg.aspect then
    keys_height = keys_height*param.xarg.aspect
	end

	-- the keyboard parts
  local kb_self = self
	local view = vb:column {
    id  = self.id,
    vb:row{
      vb:button{
        height = keys_height*2,
        id = oct_dn_id,
        pressed = function()
          kb_self:set_octave(kb_self.octave-1)
        end,
        text = "◄",
      },
      vb:column{
        id = content_id,
      },
      vb:button{
        height = keys_height*2,
        id = oct_up_id,
        pressed = function()
          kb_self:set_octave(kb_self.octave+1)
        end,
        text = "►",
      }
    }
	}

	local black_keys = vb:row {
    style = "panel",
	}

	local white_keys = vb:row {
    style = "border",
	}

	for i = 1,param.xarg.range do

    local press_notifier = function(value) 
      local val = self:index_to_midi_msg(i-1)
      self.display:generate_message(val,param)
    end

    local release_notifier = function(value) 
      local val = self:index_to_midi_msg(i-1)
      self.display:generate_message(val,param,true)
    end

    local make_white_key = function(i)
      return vb:button {
        id = self.id.."_"..i,
        width = keys_width,
        height = keys_height,
        color = KEYS_COLOR_WHITE,
        pressed = press_notifier,
        released = release_notifier,
      }
    end

    local make_black_key = function(i)
      return vb:button {
        id = self.id.."_"..i,
        width = keys_width,
        height = keys_height,
        color = KEYS_COLOR_BLACK,
        pressed = press_notifier,
        released = release_notifier,
      }
    end

    local make_space = function()
      return vb:space {
        width = keys_width/2,
        height = keys_height
      }
    end

    local make_space2 = function(scale)
      return vb:space {
        width = keys_width/scale,
        height = keys_height
      }
    end

    if (i%12==1) then
      if (i==1) then
        local scale = (i==1) and 2 or 1
        black_keys:add_child(make_space2(scale))
      elseif (i==param.xarg.range) then
        black_keys:add_child(make_space())
      end
      white_keys:add_child(make_white_key(i))
    elseif (i%12==2) then
      black_keys:add_child(make_black_key(i))
    elseif (i%12==3) then
      if (i==param.xarg.range) then
        black_keys:add_child(make_space())
      end
      white_keys:add_child(make_white_key(i))
    elseif (i%12==4) then
      black_keys:add_child(make_black_key(i))
    elseif (i%12==5) then
      local scale = (i==param.xarg.range) and 2 or 1
      black_keys:add_child(make_space2(scale))
      white_keys:add_child(make_white_key(i))
    elseif (i%12==6) then
      if (i==param.xarg.range) then
        black_keys:add_child(make_space())
      end
      white_keys:add_child(make_white_key(i))
    elseif (i%12==7) then
      black_keys:add_child(make_black_key(i))
    elseif (i%12==8) then
      if (i==param.xarg.range) then
        black_keys:add_child(make_space())
      end
      white_keys:add_child(make_white_key(i))
    elseif (i%12==9) then
      black_keys:add_child(make_black_key(i))
    elseif (i%12==10) then
      if (i==param.xarg.range) then
        black_keys:add_child(make_space())
      end
      white_keys:add_child(make_white_key(i))
    elseif (i%12==11) then
      black_keys:add_child(make_black_key(i))
    elseif (i%12==0) then
      local scale = (i==param.xarg.range) and 2 or 1
      black_keys:add_child(make_space2(scale))
      white_keys:add_child(make_white_key(i))
    end

	end

	-- assemble the parts
  local content_view = vb.views[content_id]
  self.oct_up = vb.views[oct_up_id]
  self.oct_dn = vb.views[oct_dn_id]

	content_view:add_child(black_keys)
	content_view:add_child(white_keys)

  self:update_all_keys()

	return view

end

function WidgetKeyboard:set_octave(oct)
  
  local range_oct = math.ceil(self.range/12)
  if ((oct >= 0) and (oct+range_oct < 12)) then
    self.octave = oct
    self:update_all_keys()
    self.oct_dn.active = (oct ~= 0) and true or false
    self.oct_up.active = (oct+range_oct ~= 11) and true or false
    return true
  end
  
end

--- iterate through and update all visible keys

function WidgetKeyboard:update_all_keys()
  TRACE("WidgetKeyboard:update_all_keys()")

  local basenote = (self.octave*12)
  for pitch = basenote, basenote+self.range do
    self:update_key(pitch)
  end

end


--- update a given key's visual appearance
-- state is stored in keystates, also when not currently visible
-- @param pitch (int) the key we wish to update

function WidgetKeyboard:update_key(pitch)
  --print("WidgetKeyboard:update_key(pitch)",pitch)

  local key_widget = nil
  local key_idx = self:note_to_index(pitch)
  if key_idx then
    local key_id = ("%i_%i"):format(self.id,key_idx)
    key_widget = self.display.vb.views[key_id]
    --print("key_widget",key_widget,"key_idx",key_idx,"pitch",pitch)
  end

  if key_widget then


    local white           = KEYS_COLOR_WHITE
    local white_pressed   = KEYS_COLOR_WHITE_PRESSED
    local white_disabled  = KEYS_COLOR_WHITE_DISABLED
    local black           = KEYS_COLOR_BLACK
    local black_pressed   = KEYS_COLOR_BLACK_PRESSED
    local black_disabled  = KEYS_COLOR_BLACK_DISABLED
  


    -- figure out if it's a black or white key
    local is_white_key = true
    local key_pos = key_idx%12
    if (key_pos==2) or 
      (key_pos==4) or
      (key_pos==7) or
      (key_pos==9) or
      (key_pos==11) 
    then
      is_white_key = false
    end
    
    local label = ""
    local color = nil

    local transpose = (self.octave * 12)

    if (key_idx+transpose-13 > UPPER_NOTE) then
      color = KEYS_COLOR_OUT_OF_BOUNDS
      key_widget.active = false
    else
      key_widget.active = true
      -- assign every octave as label
      if (key_idx%12==1) then
        label = ("%d"):format(math.floor(transpose+key_idx)/12)
      end
      if self.disabled_keys[pitch] then
        color = is_white_key and 
          white_disabled or black_disabled
        key_widget.active = false
      else
        if not self.pressed_keys[pitch] then
          color = is_white_key and 
            white or black
        else
          color = is_white_key and 
            white_pressed or black_pressed
        end
      end
    end

    -- add text only when there's room
    if(key_widget.width<KEYS_MIN_WIDTH)then
      key_widget.text = ""
    else
      key_widget.text = label
    end

    key_widget.color = color

  end

end


--- generate output based on the pressed key

function WidgetKeyboard:index_to_midi_msg(key_idx,release)

  return {
    (release) and (127+self.channel) or (143+self.channel),
    self:index_to_note(key_idx),
    (release) and 0 or 127
  }

end


--- convert a given index to midi note (on/off)

function WidgetKeyboard:index_to_note(key_idx)
  TRACE("WidgetKeyboard:index_to_note(key_idx)",(self.octave * 12) + key_idx)

  return (self.octave * 12) + key_idx - 12

end


--- convert a pitch to an index 
-- @return int when pitch is within view, nil when not

function WidgetKeyboard:note_to_index(pitch)

  local lower_key = (self.octave*12)
  local upper_key = lower_key + self.range
  if (pitch >= lower_key) and (pitch < upper_key) then
    return pitch - lower_key + 1
  end
    
end


