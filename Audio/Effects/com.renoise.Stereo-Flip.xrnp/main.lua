--[[---------------------------------------------------------------------------
  com.renoise.Example-Recombinator.xrnp/main.lua
---------------------------------------------------------------------------]]--


local parameters = {
  
}

-------------------------------------------------------------------------------

-- __init (parameter setup)

-- register parameters for the device. can only be done here

function __init(device)
  
end


-------------------------------------------------------------------------------

-- __process_input (parameter changes)

-- name: name of the parameter as it was registered
-- value: new value name of the parameter

function __process_input(name, value)
	if name == "Chunks" then
		parameters.amount = value;		
	end
end


-------------------------------------------------------------------------------

-- __process_audio

-- left, right: table of floats for inplace procesing
-- num_frames: number of frames that are valid in left/right

function __process_audio(left, right, num_frames)

	local tmp_left;
	
	for i=1,num_frames do

		tmp_left = left[i];

		left[i] = right[i];
		
		right[i] = tmp_left;
		
	end

end

-------------------------------------------------------------------------------

-- __flush_audio

-- called on panic and when suspending the plugin. flush all your buffers here

function __flush_audio()
  -- nothing to do in this example
end



--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
