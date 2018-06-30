--[[ 
  Testcase for xKeyZone
--]]

_xlib_tests:insert({
  name = "xKeyZone",
  fn = function()
  
    require (_xlibroot.."xKeyZone")
    require (_xlibroot.."xSampleMapping")
    _trace_filters = {"^xKeyZone*"}
  
    LOG(">>> xKeyZone: starting unit-test...")
  
    -- multisample velocities 
  
    local velocities = xKeyZone.compute_multisample_velocities(4,0,0x7F)
    assert(type(velocities)=="table")
    assert(#velocities == 4)
    assert(cLib.table_compare(velocities[1],{0,31}),velocities[1])
    assert(cLib.table_compare(velocities[2],{32,63}),velocities[2])
    assert(cLib.table_compare(velocities[3],{64,95}),velocities[3])
    assert(cLib.table_compare(velocities[4],{96,127}),velocities[4])
  
    local velocities = xKeyZone.compute_multisample_velocities(4,0,0x42)
    assert(type(velocities)=="table")
    assert(#velocities == 4)
    assert(cLib.table_compare(velocities[1],{0,16}),velocities[1])
    assert(cLib.table_compare(velocities[2],{17,33}),velocities[2])
    assert(cLib.table_compare(velocities[3],{34,49}),velocities[3])
    assert(cLib.table_compare(velocities[4],{50,66}),velocities[4])
  
    -- multisample notes 
  
    -- every 7 notes, from C-0 to C-4 (extend)
    local notes = xKeyZone.compute_multisample_notes(7,0,48,true)  
    assert(type(notes)=="table")
    assert(#notes == 7)
    assert(cLib.table_compare(notes[1],{0,6}),notes[1])
    assert(cLib.table_compare(notes[2],{7,13}),notes[2])
    assert(cLib.table_compare(notes[3],{14,20}),notes[3])
    assert(cLib.table_compare(notes[4],{21,27}),notes[4])
    assert(cLib.table_compare(notes[5],{28,34}),notes[5])
    assert(cLib.table_compare(notes[6],{35,41}),notes[6])
    assert(cLib.table_compare(notes[7],{42,119}),notes[7]) -- extended, would be 48
  
    -- every 7 notes, from C-3 to A-4 (extend)
    local notes = xKeyZone.compute_multisample_notes(7,36,48,true)  
    assert(type(notes)=="table")
    assert(#notes == 2)
    assert(cLib.table_compare(notes[1],{0,42}),notes[1])
    assert(cLib.table_compare(notes[2],{43,119}),notes[2])
  
    -- create multisample layout
    local note_steps,note_min,note_max = 7,0,48
    local vel_steps,vel_min,vel_max = 1,0,0x7F
    local mappings = xKeyZone.create_multisample_layout({
      note_steps = note_steps,
      note_min = note_min,
      note_max = note_max,
      vel_steps = vel_steps,
      vel_min = vel_min,
      vel_max = vel_max
    })
  
    rprint(mappings)
    assert(type(mappings)=="table")
    assert(#mappings == 7)  
    assert(mappings[1].layer == renoise.Instrument.LAYER_NOTE_ON)
    assert(mappings[1].map_velocity_to_volume == true)
    assert(mappings[1].map_key_to_pitch == true)
    assert(cLib.table_compare(mappings[1].note_range,{0,6}),rprint(mappings[1].note_range))
    assert(cLib.table_compare(mappings[1].velocity_range,{0,0x7F}),rprint(mappings[1].velocity_range))
    assert(cLib.table_compare(mappings[2].note_range,{7,13}),rprint(mappings[2].note_range))
    assert(cLib.table_compare(mappings[2].velocity_range,{0,0x7F}),rprint(mappings[2].velocity_range))
  
    local mapping = xKeyZone.find_mapping(mappings,{0,6},{0,0x7F})
    assert(type(mapping)=="xSampleMapping")
    local mapping = xKeyZone.find_mapping(mappings,{0,0},{0,0x7F})
    assert(type(mapping)=="nil",type(mapping))
  
    LOG(">>> xKeyZone: OK - passed all tests")
  
  end
  })