-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
{
  actions = {
      {
          set_instrument = 1,
      },
      {
          output_message = 1,
      },
      instrument_index = 1,
      output_message = 1,
  },
  conditions = {
      {
          message_type = {
              equal_to = "note_on",
          },
      },
      {
          value1 = {
              greater_than = 60,
          },
      },
      note_off = {
          value1 = {
              less_than = 47,
          },
      },
      note_on = {
          value1 = {
              less_than = 47,
          },
      },
  },
},
{
  actions = {
      {
          set_instrument = 2,
      },
      {
          output_message = 1,
      },
      instrument_index = 2,
      output_message = 1,
  },
  conditions = {
      {
          message_type = {
              equal_to = "note_on",
          },
      },
      {
          value1 = {
              less_than = 59,
          },
      },
      note_off = {
          value1 = {
              greater_than = 48,
          },
      },
      note_on = {
          value1 = {
              greater_than = 48,
          },
      },
  },
}
}