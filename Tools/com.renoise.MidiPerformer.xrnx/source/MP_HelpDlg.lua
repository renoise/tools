--[[============================================================================
MP_HelpDlg
============================================================================]]--
--[[

Help dialog for MidiPerformer

]]

class 'MP_HelpDlg'  (vDialog)

--------------------------------------------------------------------------------

function MP_HelpDlg:__init(...)

  vDialog.__init(self,...)

end

-------------------------------------------------------------------------------

function MP_HelpDlg:create_dialog()

  local vb = self.vb 
  local DIALOG_W = 200

  return vb:column{
    spacing = 3,
    margin = 3,
    vb:column{
      margin = 6,
      style = "group",
      vb:text{
        text = [[
MidiPerformer brings simple "record-arming"" of instruments and tracks to Renoise. 

To use it, launch the tool and it will present a list of all instruments that specify 
a MIDI input. Click the record-arm button to enable recording for a given instrument
(or use the provided MIDI mappings if you prefer not to toggle arming using the mouse).  

From the GUI you can add additional instruments and control all input settings. These  
settings are simply a more compact version of the instrument MIDI Panel, all settings
work exactly the same as in the Renoise counterpart. 

Note that when you are rehearsing (playing but not recording), notes are routed to a  
group track. This group track is created automatically if it doesn't already exist.   

Finally, you can control whether recording happens when an instrument track is muted 
(MUTE/OFF) or silent (PreFX with -INF gain).    

--

IMPORTANT: to use the tool, you need to disable the MIDI inputs that you're planning
to manage using this tool. Do this through the Renoise preferences - otherwise, 
incoming MIDI can still be from being recorded.     
]],
        width = DIALOG_W,
      },
    },
  }

end

