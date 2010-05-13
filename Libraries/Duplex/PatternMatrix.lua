--[[----------------------------------------------------------------------------
-- Duplex.PatternMatrix
----------------------------------------------------------------------------]]--

--[[

A functional pattern-matrix (basic mute/unmute operations)

Recommended hardware: a monome/launchpad-style grid controller 


--]]

module("Duplex", package.seeall);


class 'PatternMatrix' (Application)


function PatternMatrix:__init(display)
print("PatternMatrix:__init",display)

	-- constructor 
	Application.__init(self)
	
	self.buttons = nil
	self.position = nil
	self.display = display
	self.build_app(self)

	self.observable_firing = false


	--self.offset = 0

	-- observables tell only a little bit, 
	-- search for changes manually?

	local function pattern_assignment(e)
		print("pattern_assignments_observable fired...",e)
		--self.update_slots(self)
		self.observable_firing = true

	end
	self.observable = renoise.song().sequencer.pattern_assignments_observable
	self.observable:add_notifier(pattern_assignment)

	local function pattern_sequence(e)
		print("pattern_sequence_observable fired...",e)
		--self.update_slots(self)
		self.observable_firing = true

	end
	self.observable2 = renoise.song().sequencer.pattern_sequence_observable
	self.observable2:add_notifier(pattern_sequence)

	self.observable3 = renoise.song().sequencer.pattern_slot_mutes_observable 
	local function mute_state_changed(e)
		print("pattern_slot_mutes_observable fired...",e)
		--self.update_slots(self)
		self.observable_firing = true
	end
	self.observable3:add_notifier(mute_state_changed)

	local function tracks(e)
		print("tracks_observable fired...",e)
		--self.update_slots(self)
		self.observable_firing = true
	end
	self.observable4 = renoise.song().tracks_observable
	self.observable4:add_notifier(tracks)
	
	local function patterns(e)
		print("patterns_observable fired...",e)
		--self.update_slots(self)
		self.observable_firing = true
	end
	self.observable5 = renoise.song().patterns_observable
	self.observable5:add_notifier(patterns)
	

--[[
	self.palette = {
		empty = {
			text="▪",
			color={0x00,0x00,0x00},
		},
		empty_muted = {
			text="▫",
			color={0xc0,0xc0,0x00},
		},
		track = {
			text="■",
			color={0xc0,0xc0,0x00},
		},
		track_muted = {
			text="□",
			color={0xc0,0xc0,0x00},
		}

	}
]]

end



function PatternMatrix:build_app()
--print("PatternMatrix:build_app(")

	Application.build_app(self)

	local observable = nil

	-- TODO quick hack to make a Slider appear like a selector
	-- (make proper Selector class)
	self.position = Slider(self.display)
	self.position.group_name = "Triggers"
	self.position.x_pos = 1
	self.position.y_pos = 1
	--self.position.toggleable = true
	self.position.flipped = true
	self.position.ceiling = 8
	self.position.palette.medium.text="·"
	self.position.palette.medium.color={0x00,0x00,0x00}
	self.position.set_size(self.position,8)
	self.position.on_change = function(obj) 
--print("position.on_change",obj.selected_index)
		if not self.active then
			print('Application is sleeping')
		elseif obj.selected_index==0 then
			-- turn off playback
			renoise.song().transport.stop(renoise.song().transport)
		elseif not renoise.song().sequencer.pattern_sequence[obj.selected_index] then
			print('Pattern is out of bounds')
		else
			-- instantly change to new song pos
			local new_pos = renoise.song().transport.playback_pos
			new_pos.sequence = obj.selected_index
			renoise.song().transport.playback_pos = new_pos
			-- start playback if not playing
			if not renoise.song().transport.playing then
				renoise.song().transport.start(renoise.song().transport,renoise.Transport.PLAYMODE_RESTART_PATTERN)
			end
		end
	end
	self.display.add(self.display,self.position)

	self.buttons = {}

	for x=1,8 do

		self.buttons[x] = {}

		for y=1,8 do


			self.buttons[x][y] = ToggleButton(self.display)
			self.buttons[x][y].group_name = "Grid"
			self.buttons[x][y].x_pos = x
			self.buttons[x][y].y_pos = y
			self.buttons[x][y].active = false

			-- mute state changed from controller
			self.buttons[x][y].on_change = function(obj) 

				local seq = renoise.song().sequencer.pattern_sequence

				if not self.active then
					print('Application is sleeping')
				elseif not renoise.song().tracks[x] then
					print('Track is outside bounds')
				elseif not seq[y] then
					print('Pattern is outside bounds')
				else
					renoise.song().sequencer.set_track_sequence_slot_is_muted(renoise.song().sequencer,x,y,(not obj.active))-- "active" is negated
				end
			end

			self.display.add(self.display,self.buttons[x][y])

		end	
	end

end


-- function to update all slots' visual appeareance

function PatternMatrix:update_slots()
	if self.observable_firing then
		return
	end
--print("PatternMatrix:update_slots()",self.observable_firing)

	--local master_idx = get_master_track_index() 
	local seq = renoise.song().sequencer.pattern_sequence
	local patt_idx = nil
	local muted = nil
	local empty = nil
	local bt = nil
	local value = nil


	for track_idx=1,8 do
		if renoise.song().tracks[track_idx] then
			for seq_index=1,8 do
				
				if seq[seq_index] then
					patt_idx = seq[seq_index]
					muted = renoise.song().sequencer.track_sequence_slot_is_muted(renoise.song().sequencer,track_idx, seq_index)
					empty = renoise.song().patterns[patt_idx].tracks[track_idx].is_empty
					bt = self.buttons[track_idx][seq_index]

					-- custom palettes for toggle-buttons: 
					if not empty then
						bt.palette.foreground.text="■"
						bt.palette.foreground.color={0xff,0xff,0x00}
						bt.palette.foreground_dimmed.text="■"
						bt.palette.foreground_dimmed.color={0xff,0xff,0x00}
						bt.palette.background.text="□"
						bt.palette.background.color={0x80,0x40,0x00}
					else
						bt.palette.foreground.text="·"
						bt.palette.foreground.color={0x00,0x00,0x00}
						bt.palette.foreground_dimmed.text="·"
						bt.palette.foreground_dimmed.color={0x00,0x00,0x00}
						bt.palette.background.text="▫"
						bt.palette.background.color={0x40,0x00,0x00}
					end

					bt.set_dimmed(bt,empty)
					bt.active = (not muted)
				end
			end
		end
	end

end


-- locate a sequencer slot that differ from our representation ...
--[[
function PatternMatrix:get_changed_slot()

	for seq_index,v in ipairs(renoise.song().patterns) do
		for track_idx,val in ipairs(v.tracks) do
			-- do something clever...
		end
	end
end
]]

-- playback-pos changed in renoise

function PatternMatrix:set_offset(val)
--print("PatternMatrix:set_offset",val)
	self.position.set_index(self.position,val,true)

end

function PatternMatrix:start_app()
--print("PatternMatrix.start_app()")

	Application.start_app(self)
	self.update_slots(self)

end




function PatternMatrix:destroy_app()
--print("PatternMatrix:destroy_app")
	Application.destroy_app(self)

	self.position.remove_listeners(self.position)
	for i=1,8 do
		for o=1,8 do
			self.buttons[i][o].remove_listeners(self.buttons[i][o])
		end
	end

end


-- periodic updates: handle "un-observable" things here

function PatternMatrix:idle_app()
--print("PatternMatrix:idle_app()",self.observable_firing)
	if not self.active then return false end

	--if not self.dirty then return false end
	if self.observable_firing then
		self.observable_firing = false
		self.update_slots(self)
	end

	local pos = renoise.song().transport.playback_pos
	-- changed pattern?
	if not (pos.sequence==self.position.selected_index)then
		self.set_offset(self,pos.sequence)
	end
	self.playback_line = pos.line

end
