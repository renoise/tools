--[[ 

  Testcase for xNoteColumn

--]]

_xlib_tests:insert({
  name = "xBlockLoop",
  fn = function()

    cLib.require (_xlibroot.."xBlockLoop")
    _trace_filters = {"^xBlockLoop*"}

    LOG(">>> xBlockLoop: starting unit-test...")

    local num_lines,coeffs,start_line,end_line,_start,_end,_coeff

    --== normalize ==--

    num_lines = 64
    coeffs = xBlockLoop.COEFFS_ALL 

    start_line = 1
    end_line = 3
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==5,"Expected 5, got ".._end)
    assert(_coeff==16,"Expected 16, got ".._coeff)

    start_line = 1
    end_line = 4
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==5,"Expected 5, got ".._end)
    assert(_coeff==16,"Expected 16, got ".._coeff)

    start_line = 1
    end_line = 6
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==6,"Expected 6, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 2
    end_line = 7
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==2,"Expected 2, got ".._start)
    assert(_end==7,"Expected 7, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 3
    end_line = 8
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==3,"Expected 3, got ".._start)
    assert(_end==8,"Expected 8, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 1
    end_line = 7
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==7,"Expected 7, got ".._end)
    assert(_coeff==10,"Expected 10, got ".._coeff)

    start_line = 1
    end_line = 8
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==8,"Expected 8, got ".._end)
    assert(_coeff==9,"Expected 9, got ".._coeff)

    start_line = 11
    end_line = 18
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==11,"Expected 11, got ".._start)
    assert(_end==18,"Expected 18, got ".._end)
    assert(_coeff==9,"Expected 9, got ".._coeff)

    start_line = 1
    end_line = 9
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==9,"Expected 9, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 21
    end_line = 29
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==21,"Expected 21, got ".._start)
    assert(_end==29,"Expected 29, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 1
    end_line = 10
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==10,"Expected 10, got ".._end)
    assert(_coeff==7,"Expected 7, got ".._coeff)

    start_line = 31
    end_line = 40
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==31,"Expected 31, got ".._start)
    assert(_end==40,"Expected 40, got ".._end)
    assert(_coeff==7,"Expected 7, got ".._coeff)

    start_line = 1
    end_line = 11
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==11,"Expected 11, got ".._end)
    assert(_coeff==6,"Expected 6, got ".._coeff)
  

    start_line = 1
    end_line = 12
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==13,"Expected 13, got ".._end)
    assert(_coeff==5,"Expected 5, got ".._coeff)

    start_line = 1
    end_line = 13
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==13,"Expected 13, got ".._end)
    assert(_coeff==5,"Expected 5, got ".._coeff)

    start_line = 1
    end_line = 14
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 15
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 16
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 3
    end_line = 18
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==3,"Expected 3, got ".._start)
    assert(_end==19,"Expected 19, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 13
    end_line = 28
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==13,"Expected 13, got ".._start)
    assert(_end==29,"Expected 29, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 18
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==22,"Expected 22, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 1
    end_line = 23
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==33,"Expected 33, got ".._end)
    assert(_coeff==2,"Expected 2, got ".._coeff)

    start_line = 1
    end_line = 43
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==65,"Expected 65, got ".._end)
    assert(_coeff==1,"Expected 1, got ".._coeff)

    --== now with fours ==--

    --num_lines = 64
    coeffs = xBlockLoop.COEFFS_FOUR 

    start_line = 1
    end_line = 3
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==5,"Expected 5, got ".._end)
    assert(_coeff==16,"Expected 16, got ".._coeff)

    start_line = 1
    end_line = 4
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==5,"Expected 5, got ".._end)
    assert(_coeff==16,"Expected 16, got ".._coeff)

    start_line = 1
    end_line = 6
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==9,"Expected 9, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 2
    end_line = 7
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==2,"Expected 2, got ".._start)
    assert(_end==10,"Expected 10, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 1
    end_line = 7
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==9,"Expected 9, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 1
    end_line = 8
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==9,"Expected 9, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 1
    end_line = 9
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==9,"Expected 9, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 21
    end_line = 29
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==21,"Expected 21, got ".._start)
    assert(_end==29,"Expected 29, got ".._end)
    assert(_coeff==8,"Expected 8, got ".._coeff)

    start_line = 1
    end_line = 10
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 11
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)
  

    start_line = 1
    end_line = 12
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 13
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 14
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 15
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 16
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==17,"Expected 17, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 3
    end_line = 18
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==3,"Expected 3, got ".._start)
    assert(_end==19,"Expected 19, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 13
    end_line = 28
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==13,"Expected 13, got ".._start)
    assert(_end==29,"Expected 29, got ".._end)
    assert(_coeff==4,"Expected 4, got ".._coeff)

    start_line = 1
    end_line = 18
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==33,"Expected 33, got ".._end)
    assert(_coeff==2,"Expected 2, got ".._coeff)

    start_line = 1
    end_line = 23
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==33,"Expected 33, got ".._end)
    assert(_coeff==2,"Expected 2, got ".._coeff)

    start_line = 1
    end_line = 43 
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==65,"Expected 65, got ".._end)
    assert(_coeff==1,"Expected 1, got ".._coeff)

    --== now with threes ==--

    --num_lines = 64
    coeffs = xBlockLoop.COEFFS_THREE

    start_line = 1
    end_line = 3
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==6,"Expected 6, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 1
    end_line = 4
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==6,"Expected 6, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 1
    end_line = 6
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==6,"Expected 6, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 2
    end_line = 7
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==2,"Expected 2, got ".._start)
    assert(_end==7,"Expected 7, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 3
    end_line = 8
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==3,"Expected 3, got ".._start)
    assert(_end==8,"Expected 8, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)

    start_line = 1
    end_line = 7
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==11,"Expected 11, got ".._end)
    assert(_coeff==6,"Expected 6, got ".._coeff)

    start_line = 1
    end_line = 8
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==11,"Expected 11, got ".._end)
    assert(_coeff==6,"Expected 6, got ".._coeff)

    start_line = 1
    end_line = 9
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==11,"Expected 11, got ".._end)
    assert(_coeff==6,"Expected 6, got ".._coeff)

    start_line = 1
    end_line = 10
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==11,"Expected 11, got ".._end)
    assert(_coeff==6,"Expected 6, got ".._coeff)

    start_line = 1
    end_line = 11
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==11,"Expected 11, got ".._end)
    assert(_coeff==6,"Expected 6, got ".._coeff)

    start_line = 1
    end_line = 12
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==22,"Expected 22, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 1
    end_line = 13
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==22,"Expected 22, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 1
    end_line = 14
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==22,"Expected 22, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 1
    end_line = 15
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==22,"Expected 22, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 1
    end_line = 16
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==22,"Expected 22, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 3
    end_line = 18
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==3,"Expected 3, got ".._start)
    assert(_end==24,"Expected 24, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 1
    end_line = 18
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==22,"Expected 22, got ".._end)
    assert(_coeff==3,"Expected 3, got ".._coeff)

    start_line = 1
    end_line = 23
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==33,"Expected 33, got ".._end)
    assert(_coeff==2,"Expected 2, got ".._coeff)

    start_line = 1
    end_line = 43 
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==65,"Expected 65, got ".._end)
    assert(_coeff==1,"Expected 1, got ".._coeff)

    --== now with threes and various pattern lengths ==--

    num_lines = 15
    coeffs = xBlockLoop.COEFFS_THREE

    start_line = 1
    end_line = 2
    _start,_end,_coeff = xBlockLoop.normalize_line_range(start_line,end_line,num_lines,coeffs)
    assert(_start==1,"Expected 1, got ".._start)
    assert(_end==2,"Expected 2, got ".._end)
    assert(_coeff==12,"Expected 12, got ".._coeff)


    LOG(">>> xBlockLoop: OK - passed all tests")

  end
})
  