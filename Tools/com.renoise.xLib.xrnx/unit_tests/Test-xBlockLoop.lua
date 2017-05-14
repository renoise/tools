--[[ 

  Testcase for xNoteColumn

--]]

_xlib_tests:insert({
  name = "xBlockLoop",
  fn = function()

    require (_xlibroot.."xBlockLoop")
    _trace_filters = {"^xBlockLoop*"}

    print(">>> xBlockLoop: starting unit-test...")

    --== normalize ==--

    local num_lines = 64
    local coeffs = xBlockLoop.COEFFS_ALL 

    -- 1 & 4 will enlarge to 1 & 5 (4 lines - 1/16th)
    local start_line = 1
    local end_line = 4
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==5,"Expected 5, got ".._end)

    -- 1 & 6 is not altered (5 lines - 1/12th, with 4 remaining lines)
    local start_line = 1
    local end_line = 6
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==6,"Expected 6, got ".._end)
    
    -- 2 & 7 is not altered (-//-, but shifted*) 
    local start_line = 2
    local end_line = 7
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 2, got ".._start)
    assert(_end==6,"Expected 7, got ".._end)

    -- 1 & 7 is not altered (6 lines - 1/10th, with 4 remaining lines)
    local start_line = 1
    local end_line = 7
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==7,"Expected 7, got ".._end)

    
    -- 1 & 8 is not altered (7 lines - 1/9th, with 1 remaining line)
    -- 1 & 8 is not altered (7 lines - 1/9th, with 1 remaining line)
    -- 1 & 9 is not altered (8 lines - 1/8th)
    -- 1 & 10 is not altered (9 lines - 1/7th, with 1 remaining line)
    -- 1 & 11 is not altered (10 lines - 1/6th, with 4 remaining lines)
    -- 1 & 12 is not altered (11 lines - 1/5th, with 9 remaining lines)

    local start_line = 1
    local end_line = 16
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==16,"Expected 16, got ".._end)

    local start_line = 1
    local end_line = 16
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==16,"Expected 16, got ".._end)

    local start_line = 1
    local end_line = 4
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==4,"Expected 4, got ".._end)

    local start_line = 1
    local end_line = 3
    local _start,_end = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==4,"Expected 4, got ".._end)

    print(">>> xBlockLoop: OK - passed all tests")

  end
})
  