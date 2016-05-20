--[[ 

  Testcase for xNoteColumn

--]]

_xlib_tests:insert({
name = "xNoteColumn",
fn = function()

  require (_xlibroot.."xNoteColumn")
  require (_xlibroot.."xLinePattern")

  print(">>> xNoteColumn: starting unit-test...")

	assert(xNoteColumn.note_string_to_value("C-0") == 0)
	assert(xNoteColumn.note_value_to_string(0) == "C-0")

	assert(xNoteColumn.note_string_to_value("C-4") == 48)
	assert(xNoteColumn.note_value_to_string(48) == "C-4")

	assert(xNoteColumn.note_string_to_value("C-9") == 108)
	assert(xNoteColumn.note_value_to_string(108) == "C-9")

	assert(xNoteColumn.note_string_to_value("C#9") == 109)
	assert(xNoteColumn.note_value_to_string(109) == "C#9")

	assert(xNoteColumn.note_string_to_value("D-9") == 110)
	assert(xNoteColumn.note_value_to_string(110) == "D-9")

	assert(xNoteColumn.note_string_to_value("D#9") == 111)
	assert(xNoteColumn.note_value_to_string(111) == "D#9")

	assert(xNoteColumn.note_string_to_value("E-9") == 112)
	assert(xNoteColumn.note_value_to_string(112) == "E-9")

	assert(xNoteColumn.note_string_to_value("F-9") == 113)
	assert(xNoteColumn.note_value_to_string(113) == "F-9")

	assert(xNoteColumn.note_string_to_value("F#9") == 114)
	assert(xNoteColumn.note_value_to_string(114) == "F#9")

	assert(xNoteColumn.note_string_to_value("G-9") == 115)
	assert(xNoteColumn.note_value_to_string(115) == "G-9")

	assert(xNoteColumn.note_string_to_value("G#9") == 116)
	assert(xNoteColumn.note_value_to_string(116) == "G#9")

	assert(xNoteColumn.note_string_to_value("A-9") == 117)
	assert(xNoteColumn.note_value_to_string(117) == "A-9")

	assert(xNoteColumn.note_string_to_value("A#9") == 118)
	assert(xNoteColumn.note_value_to_string(118) == "A#9")

	assert(xNoteColumn.note_string_to_value("B-9") == 119)
	assert(xNoteColumn.note_value_to_string(119) == "B-9")

	assert(xNoteColumn.note_string_to_value("OFF") == 120)
	assert(xNoteColumn.note_value_to_string(120) == "OFF")

	assert(xNoteColumn.note_string_to_value("---") == 121)
	assert(xNoteColumn.note_value_to_string(121) == "---")

	assert(xNoteColumn.column_string_to_value("40") == 0x40)
	assert(xNoteColumn.column_value_to_string(0x40) == "40")

	assert(xNoteColumn.column_string_to_value("C8") == 0x00000C08)
	assert(xNoteColumn.column_value_to_string(0x00000C08) == "C8")

	assert(xNoteColumn.column_string_to_value("G5") == 0x00001005)
	assert(xNoteColumn.column_value_to_string(0x00001005) == "G5")

	assert(xNoteColumn.column_string_to_value("..",xLinePattern.EMPTY_VALUE) == 255)
	assert(xNoteColumn.column_value_to_string(xLinePattern.EMPTY_VALUE,"..") == "..")

	assert(xNoteColumn.column_string_to_value("..",0) == 0)
	assert(xNoteColumn.column_value_to_string(0) == "00")

	assert(xNoteColumn.column_string_to_value("80") == 128)
	assert(xNoteColumn.column_value_to_string(128) == "80")

	assert(xNoteColumn.column_string_to_value("80") == 128)
	assert(xNoteColumn.column_value_to_string(128) == "80")

  print(">>> xNoteColumn: OK - passed all tests")

end
})
