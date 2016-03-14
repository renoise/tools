return {
  {
    conditions = {
      {
        -- first condition can't be a logic statement 
        -- (eliminate this entry)
        xRule.LOGIC.OR
      },
      {
        -- (eliminate this one too...)
        xRule.LOGIC.OR
      },
      {
        message_type = {
          equal_to = xMidiMessage.TYPE.NOTE_ON,
        },
      },
      {
        message_type = {
          -- "less than" is not supported - only TYPE_OPERATORS
          less_than = xMidiMessage.TYPE.NOTE_OFF,
        },
      },
      {
        xRule.LOGIC.OR
      },
      {
        -- multiple logic statements following each another is invalid
        -- (eliminate this entry)
        xRule.LOGIC.OR
      },
      {
        -- (eliminate this one too...)
        xRule.LOGIC.OR
      },
      {
        value1 = {
          -- due to context (note-off), should be shown as C-0 / C-4
          between = {0,48}, 
        },
      },
      {
        message_type = {
          not_equal_to = xMidiMessage.TYPE.KEY_AFTERTOUCH,
        },
      },
      {
        channel = {
          less_than = 10,
        },
      },
      {
        track_index = {
          greater_than = 1,
        },
      },
      {
        instrument_index = {
          between = {1,5},
        },
      },
    },
    actions = {
      {
        output_message = 1,
      },
      {
        set_track = 1,
      },
      {
        call_function = "-- yeah lua baby",
      },
      {
        call_function = "Now with syntax error",
      },
      {
        increase_track = 5,
      },
      {
        decrease_channel = 1,
      },

    }
  }
}