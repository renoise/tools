--[[----------------------------------------------------------------------------
-- Duplex.PatternMatrix
----------------------------------------------------------------------------]]--

--[[

A functional pattern-matrix (basic mute/unmute operations)

Recommended hardware: a monome/launchpad-style grid controller 

--]]

module("Duplex", package.seeall);

--==============================================================================


class 'PatternMatrix' (Application)

function PatternMatrix:__init(
    display,
    matrix_group_name,
    position_group_name)
  TRACE("PatternMatrix:__init",
    display,
    matrix_group_name,
    position_group_name)

  Application.__init(self)

  -- options, when current pos is pressed again

  self.PLAY_MODE_CONTINUE = 0  -- nothing happens
  self.PLAY_MODE_TOGGLE = 1    -- toggle start & stop
  self.PLAY_MODE_RETRIG = 2    -- retrig the pattern

  -- options, when triggering a pattern "outside" the song

  self.BOUNDS_MODE_STOP = 3     -- stop playback 
  self.BOUNDS_MODE_IGNORE = 4   -- nothing happens

  -- apply arguments 

  self.play_mode = self.PLAY_MODE_RETRIG
  self.out_of_bounds = self.BOUNDS_MODE_STOP

  self.display = display
  self.matrix_group_name = matrix_group_name
  self.position_group_name = position_group_name

  self.width = 8
  self.height = 8

  self.blink_rate = 20


  -- internal stuff

  self.buttons = nil  -- [UIToggleButton,...]
  self.position = nil -- UISlider

  self.__playing = nil
  self.__play_page = nil  -- the currently playing page
  self.__edit_page = nil  -- the currently editing page
  self.__track_offset = 0  -- the track offset (0-#tracks)

  -- the number of lines is used for determining the playback- 
  -- position within the currently playing pattern (in lines)
  --self.__num_lines = nil    -- 

  -- the playback position is updated whenever we enter a pattern
  self.__playback_pos = nil

  -- 
  self.__update_slots_requested = false
  self.__update_tracks_requested = false

  -- todo: stuff that blinks!
  --self.__blinks = {}
  --self.__blink_count = 0


  -- final steps

  self:build_app()
  self:__attach_to_song(renoise.song())

end


--------------------------------------------------------------------------------

function PatternMatrix:build_app()
  TRACE("PatternMatrix:build_app()")

  Application.build_app(self)

  local observable = nil

  -- page selector

  self.switcher = UISpinner(self.display)
  self.switcher.group_name = "Controls"
  self.switcher.index = 0
  self.switcher.minimum = 0
  self.switcher.maximum = 1 
  self.switcher.palette.foreground_dec.text = "▲"
  self.switcher.palette.foreground_inc.text = "▼"
  self.switcher.on_press = function(obj) 
    if(self.__edit_page~=obj.index)then
      self.__edit_page = obj.index
      self:update()
      if(self.__edit_page~=self.__play_page) then
        self:update_position(self.__playback_pos.sequence)
      end
      return true
    end
    return false
  end
  self.display:add(self.switcher)

  -- track scrolling 

  self.scroller = UISpinner(self.display)
  self.scroller.group_name = "Controls"
  self.scroller.index = 0
  self.scroller.step_size = 2
  self.scroller.minimum = 0
  self.scroller.maximum = 10
  self.scroller.x_pos = 3
  self.scroller.palette.foreground_dec.text = "◄"
  self.scroller.palette.foreground_inc.text = "►"
  self.scroller.on_press = function(obj) 
print("self.scroller.on_press:",obj.index)
    self.__track_offset = obj.index
    self:update()
    return true
  end
  self.display:add(self.scroller)

  -- play-position

  -- quick hack to make a UISlider appear like a selector
  -- (TODO make into proper/custom class, capable of displaying
  --  the current position, looped range and scheduled pattern(s))
  self.position = UISlider(self.display)
  self.position.group_name = self.position_group_name
  self.position.x_pos = 1
  self.position.y_pos = 1
  self.position.toggleable = true
  self.position.flipped = true
  self.position.ceiling = self.height
  self.position.palette.foreground.text="►"
  self.position.palette.medium.text="·"
  self.position.palette.medium.color={0x00,0x00,0x00}
  self.position:set_size(self.height)
  self.position.on_change = function(obj) 

    -- position changed from controller

    local seq_index = obj.index + (self.height*self.__edit_page)
    local seq_offset = self.__playback_pos.sequence%self.height

    if not self.active then
      return false
    elseif obj.index==0 then
      
      -- the position was "toggled off"

      if (self.play_mode == self.PLAY_MODE_RETRIG) then
        self:retrigger_pattern()

      elseif (self.play_mode == self.PLAY_MODE_TOGGLE) then
        renoise.song().transport:stop()
      end

    elseif not renoise.song().sequencer.pattern_sequence[seq_index] then

      -- position out of bounds

      if (self.out_of_bounds == self.BOUNDS_MODE_STOP) then
        renoise.song().transport:stop()
        return true -- allow the button to flash briefly 
      end
      return false

    elseif(self.__playback_pos.sequence==seq_index)then

      -- position toggled back on

      if (self.play_mode == self.PLAY_MODE_RETRIG) then
        self:retrigger_pattern()

      end

    else
      -- switch to new position
      if (not renoise.song().transport.playing) then
        -- start playback if stopped
        if renoise.song().sequencer.pattern_sequence[seq_index] then
          renoise.song().transport:trigger_sequence(seq_index)
        end
      else
        -- already playing, instantly switch position
        local new_pos = renoise.song().transport.playback_pos
        new_pos.sequence = seq_index
        -- if the desired pattern-line does not exist,start from 0
        local patt_idx = renoise.song().sequencer.pattern_sequence[seq_index]
        local num_lines = renoise.song().patterns[patt_idx].number_of_lines
        if(new_pos.line>num_lines)then
          new_pos.line = 1
        end
        renoise.song().transport.playback_pos = new_pos
      end
    end
    return true
  end
  self.display:add(self.position)

  -- grid buttons

  self.buttons = {}
  for x=1,self.width do
    self.buttons[x] = {}

    for y=1,self.height do
      self.buttons[x][y] = UIToggleButton(self.display)
      self.buttons[x][y].group_name = self.matrix_group_name
      self.buttons[x][y].x_pos = x
      self.buttons[x][y].y_pos = y
      self.buttons[x][y].active = false

      -- controller button pressed and held
      self.buttons[x][y].on_hold = function(obj) 
        TRACE("controller button pressed and held")
        --table.insert(self.__blinks,#self.__blinks,obj)
        obj:toggle()
        -- bring focus to pattern/track
        if (#renoise.song().tracks>=x) then
          renoise.song().selected_track_index = x
        end
        if renoise.song().sequencer.pattern_sequence[y] then
          renoise.song().selected_sequence_index = y
        end
      end

      -- controller button was pressed
      self.buttons[x][y].on_change = function(obj) 

        local seq = renoise.song().sequencer.pattern_sequence
        local master_idx = get_master_track_index()
        local seq_offset = self.__edit_page*self.height

        if not self.active then
          return false
        elseif x+self.__track_offset == master_idx then
          print('Notice: Master-track cannot be muted')
          return false
        elseif not renoise.song().tracks[x+self.__track_offset] then
          print('Notice: Track is outside bounds')
          return false
        elseif not seq[y+seq_offset] then
          print('Notice: Pattern is outside bounds')
          return false
        else
          renoise.song().sequencer:set_track_sequence_slot_is_muted(
            (x+self.__track_offset),(y+seq_offset),(not obj.active))-- "active" is negated
        end
        return true
      end

      self.display:add(self.buttons[x][y])

    end  
  end
end

--------------------------------------------------------------------------------

-- update slots visual appeareance 

function PatternMatrix:update()
 
  if self.__update_slots_requested then
    -- do lazy updates in idle...
    return
  end

  TRACE("PatternMatrix:update_slots()",self.__update_slots_requested)

  local sequence = renoise.song().sequencer.pattern_sequence
  local tracks = renoise.song().tracks

  local seq_offset = self.__edit_page*self.height
  local master_idx = get_master_track_index()
  
  local patt_idx = nil
  local button = nil
  local slot_muted = nil
  local slot_empty = nil

  -- loop through matrix

--  for track_idx = (1+self.__track_offset),(math.min(#tracks, self.width)+self.__track_offset) do
  for track_idx = (1+self.__track_offset),(self.width+self.__track_offset) do
    for seq_index = (1+seq_offset),(self.height+seq_offset) do

      button = self.buttons[track_idx-self.__track_offset][seq_index-seq_offset]

      if((sequence[seq_index]) and (renoise.song().tracks[track_idx]))then

        patt_idx = sequence[seq_index]
        slot_muted = renoise.song().sequencer:track_sequence_slot_is_muted(
          track_idx, seq_index)

        slot_empty = renoise.song().patterns[patt_idx].tracks[track_idx].is_empty

        if (not slot_empty) then
          -- slot with content
          button.palette.foreground.text="■"
          button.palette.foreground.color={0xff,0xff,0x00}
          button.palette.foreground_dimmed.text="■"
          button.palette.foreground_dimmed.color={0xff,0xff,0x00}
          button.palette.background.text="□"
          button.palette.background.color={0x80,0x40,0x00} 

          if (track_idx==master_idx)then
            button.palette.foreground.color={0x40,0xff,0x00}
          end

        else
          -- empty slot 
          button.palette.foreground.text="·"
          button.palette.foreground.color={0x00,0x00,0x00}
          button.palette.foreground_dimmed.text="·"
          button.palette.background.text="▫"
          --button.palette.background.color={0x40,0x00,0x00}

          if (track_idx==master_idx)then -- master track
            button.palette.foreground_dimmed.color={0x00,0x40,0x00}
            button.palette.background.color={0x00,0x40,0x00}
          --elseif(track_idx>master_idx)then -- send track
          else -- normal track
            button.palette.foreground_dimmed.color={0x00,0x00,0x00}
            button.palette.background.color={0x40,0x00,0x00}
          end

        end

        button:set_dimmed(slot_empty)
        button.active = (not slot_muted)

      elseif button then

--print("out of bounds",track_idx,seq_index)

        -- out-of-bounds space (below/next to song)

        button.palette.background.text=""
        button.palette.background.color={0x40,0x40,0x00}
        button.active = false
        button:set_dimmed(false)

      end
    end
  end
end

--------------------------------------------------------------------------------

-- update scroller (when tracks have been changed)
-- + no event fired

function PatternMatrix:update_track_offset()
print("PatternMatrix:update_track_offset")

  if((self.scroller.maximum>self.width) and (#renoise.song().tracks>self.width))then
    -- single page to multiple pages
print("single page to multiple pages")
    self.scroller:invalidate()
--  elseif((self.scroller.maximum>self.width) and (#renoise.song().tracks<self.width))then
--    -- multiple to single
--print("multiple to single")
--    self.scroller:invalidate()
  end
  -- allow scrolling "a bit into the void"
  self.scroller.maximum = #renoise.song().tracks  -- -math.floor(self.width/2)

  -- adjust the index, if the current position is out-of-bounds
  if(self.scroller.index>=#renoise.song().tracks)then
print("got here")
    self.scroller:set_index(#renoise.song().tracks-1)
    --self:update()
  end

end

--------------------------------------------------------------------------------

-- update page switcher index 
-- + no event fired

function PatternMatrix:update_page_switcher()
  TRACE("PatternMatrix:update_page_switcher()")

  self.switcher:set_index(self.__play_page,true)
  self.__edit_page = self.__play_page

end

--------------------------------------------------------------------------------

-- update the switcher (when the number of pattern have changed)
-- + no event fired

function PatternMatrix:update_page_count()

  local idx = self.switcher.index
  local seq_len = #renoise.song().sequencer.pattern_sequence
  local page_count = math.floor((seq_len-1)/self.height)

  if((self.switcher.maximum==0) and (page_count>0))then
    -- from single to multiple pages 
    self.switcher:invalidate()
  elseif((self.switcher.maximum>0) and (page_count==0))then
    -- from multiple to single page  
    self.switcher:invalidate()
  --elseif 
    -- sequence extended to more pages,
    -- and we are not at the first

  end
  self.switcher.maximum = page_count
  -- adjust the index, if the current position is out-of-bounds
  if(self.switcher.index>page_count)then
    self.switcher:set_index(page_count)
  end
end

--------------------------------------------------------------------------------

-- update position in sequence
-- @idx: (integer) the index, 0 - song-end

function PatternMatrix:update_position(idx)
  local pos_idx = nil
  local play_page = self:get_play_page()
  -- we are at a visible page?
  if(self.__edit_page == play_page)then
    pos_idx = idx-(self.__play_page*self.height)
  else
    pos_idx = 0 -- no, hide playback 
  end
  self.position:set_index(pos_idx,true)
  self.position:invalidate()

end

--------------------------------------------------------------------------------

-- retrigger the current pattern

function PatternMatrix:retrigger_pattern()

  local play_pos = self.__playback_pos.sequence
  if renoise.song().sequencer.pattern_sequence[play_pos] then
    renoise.song().transport:trigger_sequence(play_pos)
    self:update_position(play_pos)
  end
end

--------------------------------------------------------------------------------

function PatternMatrix:get_play_page()

  local play_pos = renoise.song().transport.playback_pos
  return math.floor((play_pos.sequence-1)/self.height)

end

--------------------------------------------------------------------------------

function PatternMatrix:start_app()
  TRACE("PatternMatrix.start_app()")

  Application.start_app(self)

  self.__playing = renoise.song().transport.playing
  self.__playback_pos = renoise.song().transport.playback_pos
  self.__play_page = self:get_play_page()
  -- update everything!
  self:update_page_count()
  self:update_page_switcher()
  self:update_track_offset()
  self:update_position(self.__playback_pos.sequence)
  self:update()

end


--------------------------------------------------------------------------------

function PatternMatrix:destroy_app()
  TRACE("PatternMatrix:destroy_app")

  Application.destroy_app(self)

  self.position:remove_listeners()
  for i=1,self.width do
    for o=1,self.height do
      self.buttons[i][o]:remove_listeners()
      self.buttons[i][o]:set(false)

    end
  end

end


--------------------------------------------------------------------------------

-- periodic updates: handle "un-observable" things here

function PatternMatrix:idle_app()
  TRACE("PatternMatrix:idle_app()",self.__update_slots_requested)
  
  if (not self.active) then 
    return false 
  end

--[[

  -- sketch code for blinking elements 

  if(self.__blink_count > self.blink_rate)then

    for _,__ in ipairs(self.__blinks) do
        --__blink_count

    end

    self.__blink_count = 0

  end
]]

  -- updated tracks/slots?
  if (self.__update_tracks_requested) then
    -- note: __update_slots_requested is true as well
    self.__update_tracks_requested = false
    self:update_track_offset()
  end
  -- 
  if (self.__update_slots_requested) then
    self.__update_slots_requested = false
    self:update()
    self:update_page_count()
  end


  if renoise.song().transport.playing then


    local pos = renoise.song().transport.playback_pos
--[[
    if(self.__num_lines)then
      -- figure out the progress
      local complete = (pos.line/self.__num_lines)
      local counter = math.floor(complete*self.height)
      if (self.position.index == counter) then
print("counter",counter)
        self.progress:set_index(0,true)
        self.progress:invalidate()
      else
        self.progress:set_index(counter,true)
        self.progress:invalidate()
      end

    end
]]

    -- ??? playback_pos might briefly contain the wrong value
    if (pos.sequence ~= self.__playback_pos.sequence)then

      -- changed pattern
      self.__playback_pos = pos

      -- update number of lines (used for progress)
      --local patt_idx = renoise.song().sequencer.pattern_sequence[renoise.song().selected_sequence_index]
      --self.__num_lines = renoise.song().patterns[patt_idx].number_of_lines

      -- check if we need to change page
      local play_page = self:get_play_page()
      if(play_page~=self.__play_page)then
        self.__play_page = play_page
        if(renoise.song().transport.follow_player)then
          if(self.__play_page~=self.__edit_page)then
            -- update only when following play-pos
            self:update_page_switcher()
            self:update()
          end
        end
      end
      self:update_position(pos.sequence)
    elseif (not self.__playing) then
      -- playback resumed
      self:update_position(self.__playback_pos.sequence)
    elseif (self.position.index == 0) and 
      (self.__play_page==self.__edit_page) then
      -- position now in play-range
      self:update_position(self.__playback_pos.sequence)      
    end

    self.__playing = true

  else
    -- if we stopped playing, turn off position
    if(self.__playing) then
      self:update_position(0)
      self.__playing = false
    end
  end
end

--------------------------------------------------------------------------------

-- called when a new document becomes available

function PatternMatrix:on_new_document()
  TRACE("PatternMatrix:on_new_document()")
  self:__attach_to_song(renoise.song())
  self:update_page_count()
  self:update()

end

--------------------------------------------------------------------------------

-- adds notifiers to slot relevant states

function PatternMatrix:__attach_to_song(song)
  TRACE("PatternMatrix:__attach_to_song()")
  
  -- song notifiers

  song.sequencer.pattern_assignments_observable:add_notifier(
    function()
      TRACE("PatternMatrix: pattern_assignments_observable fired...")
      self.__update_slots_requested = true
    end
  )
  
  song.sequencer.pattern_sequence_observable:add_notifier(
    function(e)
      TRACE("PatternMatrix: pattern_sequence_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.sequencer.pattern_slot_mutes_observable:add_notifier(
    function()
      TRACE("PatternMatrix:pattern_slot_mutes_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.tracks_observable:add_notifier(
    function()
      TRACE("PatternMatrix:tracks_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("PatternMatrix:patterns_observable fired...")
      self.__update_slots_requested = true
    end
  )

  
  -- slot notifiers
  
  local function slot_changed()
    TRACE("PatternMatrix:slot_changed fired...")
    self.__update_slots_requested = true
  end

  local function attach_slot_notifiers()
    local patterns = song.patterns

    for _,pattern in pairs(patterns) do
      local pattern_tracks = pattern.tracks
      
      for _,pattern_track in pairs(pattern_tracks) do
        local observable = pattern_track.is_empty_observable
        
        if (not observable:has_notifier(slot_changed)) then
          observable:add_notifier(slot_changed)
        end
      end
    end
  end

  -- attach to the initial slot set
  attach_slot_notifiers()
  
  -- and to new slots  
  song.tracks_observable:add_notifier(
    function()
      TRACE("PatternMatrix:tracks_changed fired...")
      self.__update_slots_requested = true
      self.__update_tracks_requested = true
      attach_slot_notifiers()
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("PatternMatrix:patterns_changed fired...")
      self.__update_slots_requested = true
      attach_slot_notifiers()
    end
  )
end

