notes = { 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#' };
scales = {
	major = {
		name = 'Major',
		pattern = "101011010101"
	},
	minor = {
		name = 'Minor',
		pattern = '101101011010'
	}
}

chords = {
	maj = {
		name = 'Major',
		code = 'maj',
		pattern = '10001001'
	},
	min = {
		name = 'Minor',
		code = 'min',
		pattern = '10010001'
	},
	aug = {
		name = 'Augmented',
		code = 'aug',
		pattern = '10010001'
	},
	dim = {
		name = 'Diminished',
		code = 'maj',
		pattern = '10010010'
	}	

}


------------------------------------------------------
local root  = 2
local scale = scales['major']

local spat = scale['pattern'];
local rpat = {false,false,false,false,false,false,false,false,false,false,false}
-- Finds scale notes
for i = 0,11 do
	local note = ((root - 1 + i) % 12) + 1
	if spat:sub(i+1, i+1) == '1' then
		rpat[note] = true
	end
end

------------------------------------------------------


local chord = chords['dim']
local root = 1
local scale_pattern = rpat

local cpat = chord['pattern'];
for i = 0,11 do
	local note = ((root - 1 + i) % 12) + 1
	if cpat:sub(i+1, i+1) == '1' then
		print(i)
		print(notes[note])
		if not scale_pattern[note] then
			print('doesnt match!')
		end
	end
end

