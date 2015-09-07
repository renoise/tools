function xnotecolumn_test()

	assert(xNoteColumn.note_string_to_value("C-0") == 0)
	assert(xNoteColumn.note_string_to_value("C-4") == 48)
	assert(xNoteColumn.note_string_to_value("C-9") == 108)
	assert(xNoteColumn.note_string_to_value("C#9") == 109)
	assert(xNoteColumn.note_string_to_value("D-9") == 110)
	assert(xNoteColumn.note_string_to_value("D#9") == 111)
	assert(xNoteColumn.note_string_to_value("E-9") == 112)
	assert(xNoteColumn.note_string_to_value("F-9") == 113)
	assert(xNoteColumn.note_string_to_value("F#9") == 114)
	assert(xNoteColumn.note_string_to_value("G-9") == 115)
	assert(xNoteColumn.note_string_to_value("G#9") == 116)
	assert(xNoteColumn.note_string_to_value("A-9") == 117)
	assert(xNoteColumn.note_string_to_value("A#9") == 118)
	assert(xNoteColumn.note_string_to_value("B-9") == 119)
	assert(xNoteColumn.note_string_to_value("OFF") == 120)
	assert(xNoteColumn.note_string_to_value("---") == 121)

	assert(xNoteColumn.column_string_to_value("40") == 0x40)
	assert(xNoteColumn.column_string_to_value("G5") == 0x00001005)
	assert(xNoteColumn.column_string_to_value("..",xLinePattern.EMPTY_VALUE) == 255)

	assert(xNoteColumn.column_string_to_value("..",0) == 0)
	assert(xNoteColumn.column_string_to_value("80") == 128)


end