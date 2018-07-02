--[[ 

  Testcase for cConvert

--]]

require (_clibroot.."cConvert")

--=================================================================================================
-- tests

_tests:insert({
name = "cConvert",
fn = function()

  local precision = 1000000000

  LOG(">>> cConvert: starting unit-test...")

  _trace_filters = {"^cConvert*"}

  local assert_hz_to_frames = function(test,sample_rate,expected)
    local result = cConvert.hz_to_frames(test,sample_rate)
    assert(expected==result,("*** hz_to_frames: expected %f got %f"):format(expected,result))
  end

  local assert_frames_to_hz = function(test,sample_rate,expected)
    local result = cConvert.frames_to_hz(test,sample_rate)
    assert(expected==result,("*** frames_to_hz: expected %f, got %f"):format(expected,result))
  end

  local assert_hz_to_frames = function(test,sample_rate,expected)
    local result = cConvert.hz_to_frames(test,sample_rate)
    assert(expected==result,("*** hz_to_frames: expected %f got %f"):format(expected,result))
  end


  assert_frames_to_hz(100,48000,480)
  assert_hz_to_frames(480,48000,100)

  assert_frames_to_hz(100,44100,441)
  assert_hz_to_frames(441,44100,100)

  local assert_hz_to_note = function(test,expected,expected_cents)
    local result,result_cents = cConvert.hz_to_note(test)
    print("*** result",result)
    print("*** result_cents",result_cents)
    assert(cLib.float_compare(expected,result,precision),
      ("*** hz_to_note: expected (note) %f, got %f"):format(expected,result))
    assert(cLib.float_compare(expected_cents,result_cents,precision),
      ("*** hz_to_note: expected (cents) %f, got %f"):format(expected_cents,result_cents))
  end  

  local assert_note_to_hz = function(test,expected)
    local result = cConvert.note_to_hz(test)
    print("*** result",result)    
    assert(cLib.float_compare(expected,result,1000000000),
      ("*** note_to_hz: expected %f, got %f"):format(expected,result))
  end  

  -- A-3
  assert_note_to_hz(45,220)
  assert_hz_to_note(220,45,0) 

  -- C-4 
  assert_note_to_hz(48,261.6255653006) 
  assert_hz_to_note(261.6255653006,48,0) 
  
  -- C-4 (168 frames)
  assert_note_to_hz(48.057766788345907,262.5) 
  assert_hz_to_note(262.5,48,5.7766788345907) 
  
  -- A-4
  assert_note_to_hz(57,440)
  assert_hz_to_note(440,57,0) 

  assert_hz_to_note(444,57,15.667383390537)
  assert_hz_to_note(460,58,-23.04359509634)

  -- A#4
  assert_note_to_hz(58,466.1637615181)
  assert_hz_to_note(466.1637615181,58,0) 
  
  assert_hz_to_note(480,59,-49.362941499368)
  assert_hz_to_note(490,59,-13.666129426507)

  -- B-4
  assert_note_to_hz(59,493.8833012561)
  assert_hz_to_note(493.8833012561,59,0) 

  -- C-5
  assert_note_to_hz(60,523.2511306012)
  assert_hz_to_note(523.2511306012,60,0) 

  -- C-6
  assert_note_to_hz(72,1046.5022612024)
  assert_hz_to_note(1046.5022612024,72,0) 

  local assert_frames_to_note = function(test,sample_rate,expected_note,expected_cents)
    local result,result_cents = cConvert.frames_to_note(test,sample_rate)
    print("*** frames_to_note: result",result)
    print("*** frames_to_note: result_cents",result_cents)    
    assert(expected_note==result,
      ("*** frames_to_note: expected (note) %f, got %f"):format(expected_note,result))
    assert(cLib.float_compare(expected_cents,result_cents,1000000000),
      ("*** frames_to_note: expected (cents) %f, got %f"):format(expected_cents,result_cents))
  end
  local assert_note_to_frames = function(test,sample_rate,expected)
    local result = cConvert.note_to_frames(test,sample_rate)
    assert(expected==result,("*** note_to_frames: expected %f, got %f"):format(expected,result))
  end

  -- C-3
  assert_note_to_frames(48,44100,168) 
  assert_frames_to_note(168,44100,48,5.7766788345907) 

  assert_note_to_frames(48,48000,183)
  assert_frames_to_note(183,48000,48,4.4246802894501)

  

  LOG(">>> cConvert: OK - passed all tests")

end
})

