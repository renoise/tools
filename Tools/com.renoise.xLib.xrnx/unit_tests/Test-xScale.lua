--[[ 

  Testcase for xScale

--]]

_xlib_tests:insert({
    name = "xScale",
    fn = function()

        LOG(">>> xScale: starting unit-test...")

        cLib.require (_xlibroot.."xScale")
        _trace_filters = {"^xScale*"}

        -- local variables
        local scale = nil
        local scale_idx = nil

        -- has expected static properties
        assert(#xScale.KEYS,12)
        assert(#xScale.SCALES,50)

        -- has expected methods
        assert(type(xScale.restrict_to_scale),"function")
        assert(type(xScale.get_shifted_keys),"function")
        assert(type(xScale.get_scale_by_name),"function")
        assert(type(xScale.get_scale_index_by_name),"function")
        assert(type(xScale.get_scales_with_count),"function")
        assert(type(xScale.get_selected_scale),"function")
        assert(type(xScale.get_selected_key),"function")

        -- can get scale by name 
        scale = xScale.get_scale_by_name("Augmented")
        assert(scale.count == 6)
        assert(scale.name == "Augmented")

        -- restrict to Natural Major (C)
        scale_idx = xScale.get_scale_index_by_name("Natural Major")       
        assert(xScale.restrict_to_scale(48,scale_idx,1)==48) -- C-4
        assert(xScale.restrict_to_scale(49,scale_idx,1)==48) -- C-4
        assert(xScale.restrict_to_scale(50,scale_idx,1)==50) -- D-4
        assert(xScale.restrict_to_scale(51,scale_idx,1)==50) -- D-4
        assert(xScale.restrict_to_scale(52,scale_idx,1)==52) -- E-4
        assert(xScale.restrict_to_scale(53,scale_idx,1)==53) -- F-4
        assert(xScale.restrict_to_scale(54,scale_idx,1)==53) -- F-4
        assert(xScale.restrict_to_scale(55,scale_idx,1)==55) -- G-4
        assert(xScale.restrict_to_scale(56,scale_idx,1)==55) -- G-4
        assert(xScale.restrict_to_scale(57,scale_idx,1)==57) -- A-4
        assert(xScale.restrict_to_scale(58,scale_idx,1)==57) -- A-4
        assert(xScale.restrict_to_scale(59,scale_idx,1)==59) -- B-4

        -- restrict to Natural Major (D)
        scale_idx = xScale.get_scale_index_by_name("Natural Major")       
        assert(xScale.restrict_to_scale(48,scale_idx,3)==47) -- B-3
        assert(xScale.restrict_to_scale(49,scale_idx,3)==49) -- C#4
        assert(xScale.restrict_to_scale(50,scale_idx,3)==50) -- D-4
        assert(xScale.restrict_to_scale(51,scale_idx,3)==50) -- D-4
        assert(xScale.restrict_to_scale(52,scale_idx,3)==52) -- E-4
        assert(xScale.restrict_to_scale(53,scale_idx,3)==52) -- E-4
        assert(xScale.restrict_to_scale(54,scale_idx,3)==54) -- F#4
        assert(xScale.restrict_to_scale(55,scale_idx,3)==55) -- G-4
        assert(xScale.restrict_to_scale(56,scale_idx,3)==55) -- G-4
        assert(xScale.restrict_to_scale(57,scale_idx,3)==57) -- A-4
        assert(xScale.restrict_to_scale(58,scale_idx,3)==57) -- A-4
        assert(xScale.restrict_to_scale(59,scale_idx,3)==59) -- B-4

        -- restrict to Augmented (C)
        scale_idx = xScale.get_scale_index_by_name("Augmented")       
        assert(xScale.restrict_to_scale(48,scale_idx,1)==48) -- C-4
        assert(xScale.restrict_to_scale(49,scale_idx,1)==48) -- C-4
        assert(xScale.restrict_to_scale(50,scale_idx,1)==48) -- C-4
        assert(xScale.restrict_to_scale(51,scale_idx,1)==51) -- D#4
        assert(xScale.restrict_to_scale(52,scale_idx,1)==52) -- E-4
        assert(xScale.restrict_to_scale(53,scale_idx,1)==52) -- E-4
        assert(xScale.restrict_to_scale(54,scale_idx,1)==52) -- E-4
        assert(xScale.restrict_to_scale(55,scale_idx,1)==55) -- G-4
        assert(xScale.restrict_to_scale(56,scale_idx,1)==56) -- G#4
        assert(xScale.restrict_to_scale(57,scale_idx,1)==56) -- G#4
        assert(xScale.restrict_to_scale(58,scale_idx,1)==56) -- G#4
        assert(xScale.restrict_to_scale(59,scale_idx,1)==59) -- B-4

        -- restrict to Pentatonic Major (C)
        scale_idx = xScale.get_scale_index_by_name("Pentatonic Major")       
        assert(xScale.restrict_to_scale(48,scale_idx,1)==48) -- C-4
        assert(xScale.restrict_to_scale(49,scale_idx,1)==48) -- C-4
        assert(xScale.restrict_to_scale(50,scale_idx,1)==50) -- D-4
        assert(xScale.restrict_to_scale(51,scale_idx,1)==50) -- D-4
        assert(xScale.restrict_to_scale(52,scale_idx,1)==52) -- E-4
        assert(xScale.restrict_to_scale(53,scale_idx,1)==52) -- E-4
        assert(xScale.restrict_to_scale(54,scale_idx,1)==52) -- E-4
        assert(xScale.restrict_to_scale(55,scale_idx,1)==55) -- G-4
        assert(xScale.restrict_to_scale(56,scale_idx,1)==55) -- G-4
        assert(xScale.restrict_to_scale(57,scale_idx,1)==57) -- A-4
        assert(xScale.restrict_to_scale(58,scale_idx,1)==57) -- A-4
        assert(xScale.restrict_to_scale(59,scale_idx,1)==57) -- A-4

        -- restrict to Pentatonic Major (#C)
        scale_idx = xScale.get_scale_index_by_name("Pentatonic Major")       
        assert(xScale.restrict_to_scale(48,scale_idx,2)==46) -- A#3
        assert(xScale.restrict_to_scale(49,scale_idx,2)==49) -- C#4
        assert(xScale.restrict_to_scale(50,scale_idx,2)==49) -- C#4
        assert(xScale.restrict_to_scale(51,scale_idx,2)==51) -- D#4
        assert(xScale.restrict_to_scale(52,scale_idx,2)==51) -- D#4
        assert(xScale.restrict_to_scale(53,scale_idx,2)==53) -- F-4
        assert(xScale.restrict_to_scale(54,scale_idx,2)==53) -- F-4
        assert(xScale.restrict_to_scale(55,scale_idx,2)==53) -- F-4
        assert(xScale.restrict_to_scale(56,scale_idx,2)==56) -- G#4
        assert(xScale.restrict_to_scale(57,scale_idx,2)==56) -- G#4
        assert(xScale.restrict_to_scale(58,scale_idx,2)==58) -- A#4
        assert(xScale.restrict_to_scale(59,scale_idx,2)==58) -- A#4

        -- restrict to Pentatonic Major (G)
        scale_idx = xScale.get_scale_index_by_name("Pentatonic Major")       
        assert(xScale.restrict_to_scale(48,scale_idx,8)==47) -- B-3
        assert(xScale.restrict_to_scale(49,scale_idx,8)==47) -- B-3
        assert(xScale.restrict_to_scale(50,scale_idx,8)==50) -- D-4
        assert(xScale.restrict_to_scale(51,scale_idx,8)==50) -- D-4
        assert(xScale.restrict_to_scale(52,scale_idx,8)==52) -- E-4
        assert(xScale.restrict_to_scale(53,scale_idx,8)==52) -- E-4
        assert(xScale.restrict_to_scale(54,scale_idx,8)==52) -- E-4
        assert(xScale.restrict_to_scale(55,scale_idx,8)==55) -- G-4
        assert(xScale.restrict_to_scale(56,scale_idx,8)==55) -- G-4
        assert(xScale.restrict_to_scale(57,scale_idx,8)==57) -- A-4
        assert(xScale.restrict_to_scale(58,scale_idx,8)==57) -- A-4
        assert(xScale.restrict_to_scale(59,scale_idx,8)==59) -- B-4

        LOG(">>> xScale: OK - passed all tests")


    end
})
    

