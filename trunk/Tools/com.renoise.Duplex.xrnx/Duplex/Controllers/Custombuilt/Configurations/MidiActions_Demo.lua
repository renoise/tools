--[[----------------------------------------------------------------------------
-- Duplex.Custombuilt
----------------------------------------------------------------------------]]--

-- This configuration demonstrates the MidiActions application

duplex_configurations:insert {

  -- configuration properties
  name = "MidiActions",
  pinned = true,

  -- device properties
  device = {
    class_name = nil,          
    display_name = "Custombuilt",
    device_port_in = "",
    device_port_out = "",
    control_map = "Controllers/Custombuilt/Controlmaps/MidiActions.xml",
    protocol = DEVICE_PROTOCOL.MIDI
  },
  
  applications = {

    -- master-vol, undo + redo --
  
    MasterVolume = {
      application = "MidiActions",
      mappings = {control = {group_name = "MstVolume",index = 1}},
      options = {action = "Track Levels:Volume:Master Track (Pre) [Set]"},
    },
    Undo = {
      application = "MidiActions",
      mappings = {control = {group_name = "UndoRedo",index = 1}},
      options = {action = "Transport:Record:Undo Last Action [Trigger]"},
    },
    Redo = {
      application = "MidiActions",
      mappings = {control = {group_name = "UndoRedo",index = 2}},
      options = {action = "Transport:Record:Redo Last Action [Trigger]"},
    },

    -- transport --

    TransportPlay = {
      application = "MidiActions",
      mappings = {control = {group_name = "Transport",index = 1}},
      options = {action = "Transport:Playback:Start/Stop Playing [Set]"},
    },
    TransportPattLoop = {
      application = "MidiActions",
      mappings = {control = {group_name = "Transport",index = 2}},
       options = {action = "Transport:Playback:Loop Pattern [Set]"},
   },
    TransportStop = {
      application = "MidiActions",
      mappings = {control = {group_name = "Transport",index = 3}},
      options = {action = "Transport:Playback:Stop Playing [Trigger]"},
    },
    TransportEditMode = {
      application = "MidiActions",
      mappings = {control = {group_name = "Transport",index = 4}},
      options = {action = "Transport:Edit:Edit Mode [Set]"},
   },
    TransportFollow = {
      application = "MidiActions",
      mappings = {control = {group_name = "Transport",index = 5}},
      options = {action = "Transport:Playback:Follow Player [Set]"},
    },
    TransportMetronome = {
      application = "MidiActions",
      mappings = {control = {group_name = "Transport",index = 6}},
      options = {action = "Transport:Record:Metronome Enabled [Set]"},
    },

    -- block loop --

    BlockLoop = {
      application = "MidiActions",
      mappings = {control = {group_name = "LoopBlock",index = 1}},
      options = {action = "Transport:Playback:Loop Block [Set]"},
    },
    BlockLoopRange = {
      application = "MidiActions",
      mappings = {control = {group_name = "LoopBlock",index = 2}},
      options = {action = "Transport:Playback:Loop Block Range [Set]"},
    },
    BlockLoopUp = {
      application = "MidiActions",
      mappings = {control = {group_name = "LoopBlock",index = 3}},
      options = {action = "Transport:Playback:Move Loop Block Backwards [Trigger]"},
    },
    BlockLoopDown = {
      application = "MidiActions",
      mappings = {control = {group_name = "LoopBlock",index = 4}},
      options = {action = "Transport:Playback:Move Loop Block Forwards [Trigger]"},
    },

    -- BPM --

    BPM_Decrease = {
      application = "MidiActions",
      mappings = {control = {group_name = "BPM",index = 1}},
      options = {action = "Transport:Song:Decrease BPM [Trigger]"},
    },
    BPM_Set = {
      application = "MidiActions",
      mappings = {control = {group_name = "BPM",index = 2}},
      options = {
        action = "Transport:Song:BPM [Set]",
        min_scaling = "64",
        max_scaling = "200",
        scaling = "Exp+"
      },
    },
    BPM_Increase = {
      application = "MidiActions",
      mappings = {control = {group_name = "BPM",index = 3}},
      options = {action = "Transport:Song:Increase BPM [Trigger]"},
    },

    -- LPB --

    LPB_Decrease = {
      application = "MidiActions",
      mappings = {control = {group_name = "LPB",index = 1}},
      options = {action = "Transport:Song:Decrease LPB [Trigger]"},
    },
    LPB_Set = {
      application = "MidiActions",
      mappings = {control = {group_name = "LPB",index = 2}},
      options = {action = "Transport:Song:LPB [Set]"},
    },
    LPB_Increase = {
      application = "MidiActions",
      mappings = {control = {group_name = "LPB",index = 3}},
      options = {action = "Transport:Song:Increase LPB [Trigger]"},
    },

    -- Octave --

    OctDecrease = {
      application = "MidiActions",
      mappings = {control = {group_name = "Oct",index = 1}},
      options = {action = "Transport:Edit:Decrease Octave [Trigger]"},
    },
    Oct_Set = {
      application = "MidiActions",
      mappings = {control = {group_name = "Oct",index = 2}},
      options = {action = "Transport:Edit:Octave [Set]"},
    },
    OctIncrease = {
      application = "MidiActions",
      mappings = {control = {group_name = "Oct",index = 3}},
      options = {action = "Transport:Edit:Increase Octave [Trigger]"},
    },

    -- upper tabs --

    UpperTabsBrowser = {
      application = "MidiActions",
      mappings = {control = {group_name = "UpperTabs",index = 1}},
      options = {action = "GUI:Show Disk Browser [Trigger]"},
    },
    UpperTabsScopes = {
      application = "MidiActions",
      mappings = {control = {group_name = "UpperTabs",index = 2}},
      options = {action = "GUI:Upper Frame:Show Track Scopes [Trigger]"},
    },
    UpperTabsSpectrum = {
      application = "MidiActions",
      mappings = {control = {group_name = "UpperTabs",index = 3}},
      options = {action = "GUI:Upper Frame:Show Master Spectrum [Trigger]"},
    },
    --[[
    UpperTabsMstScopes = {
      application = "MidiActions",
      mappings = {control = {group_name = "UpperTabs",index = 2}},
      options = {action = "GUI:Upper Frame:Show Master Scopes [Trigger]"},
    },
    ]]

    -- track mute --

    MuteTrk1 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 1}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #01 [Set]"},
    },
    MuteTrk2 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 2}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #02 [Set]"},
    },
    MuteTrk3 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 3}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #03 [Set]"},
    },
    MuteTrk4 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 4}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #04 [Set]"},
    },
    MuteTrk5 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 5}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #05 [Set]"},
    },
    MuteTrk6 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 6}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #06 [Set]"},
    },
    MuteTrk7 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 7}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #07 [Set]"},
    },
    MuteTrk8 = {
      application = "MidiActions",
      mappings = {control = {group_name = "MuteTracks",index = 8}},
      options = {action = "Track Muting:Mute/Unmute:Track XX [Set]:Track #08 [Set]"},
    },

    -- track solo --

    SoloTrk1 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 1}},
      options = {action = "Track Muting:Solo:Track XX:Track #01 [Trigger]"},
    },
    SoloTrk2 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 2}},
      options = {action = "Track Muting:Solo:Track XX:Track #02 [Trigger]"},
    },
    SoloTrk3 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 3}},
      options = {action = "Track Muting:Solo:Track XX:Track #03 [Trigger]"},
    },
    SoloTrk4 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 4}},
      options = {action = "Track Muting:Solo:Track XX:Track #04 [Trigger]"},
    },
    SoloTrk5 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 5}},
      options = {action = "Track Muting:Solo:Track XX:Track #05 [Trigger]"},
    },
    SoloTrk6 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 6}},
      options = {action = "Track Muting:Solo:Track XX:Track #06 [Trigger]"},
    },
    SoloTrk7 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 7}},
      options = {action = "Track Muting:Solo:Track XX:Track #07 [Trigger]"},
    },
    SoloTrk8 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SoloTracks",index = 8}},
      options = {action = "Track Muting:Solo:Track XX:Track #08 [Trigger]"},
    },

    -- seq. mute --

    SeqMuteTrk1 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 1}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #01 [Set]"},
    },
    SeqMuteTrk2 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 2}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #02 [Set]"},
    },
    SeqMuteTrk3 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 3}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #03 [Set]"},
    },
    SeqMuteTrk4 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 4}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #04 [Set]"},
    },
    SeqMuteTrk5 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 5}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #05 [Set]"},
    },
    SeqMuteTrk6 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 6}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #06 [Set]"},
    },
    SeqMuteTrk7 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 7}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #07 [Set]"},
    },
    SeqMuteTrk8 = {
      application = "MidiActions",
      mappings = {control = {group_name = "SeqMuteTracks",index = 8}},
      options = {action = "Seq. Muting:Selected Seq. [Set]:Mute Track #08 [Set]"},
    },

    -- track volume --
    TrkVol1 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol1",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #01 [Set]"},
    },
    TrkVol2 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol2",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #02 [Set]"},
    },
    TrkVol3 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol3",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #03 [Set]"},
    },
    TrkVol4 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol4",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #04 [Set]"},
    },
    TrkVol5 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol5",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #05 [Set]"},
    },
    TrkVol6 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol6",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #06 [Set]"},
    },
    TrkVol7 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol7",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #07 [Set]"},
    },
    TrkVol8 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackVol8",index = 1}},
      options = {action = "Track Levels:Volume:Track XX (Pre):Track #08 [Set]"},
    },

    -- track panning --

    TrkPan1 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth1",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #01 [Set]"},
    },
    TrkPan2 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth2",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #02 [Set]"},
    },
    TrkPan3 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth3",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #03 [Set]"},
    },
    TrkPan4 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth4",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #04 [Set]"},
    },
    TrkPan5 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth5",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #05 [Set]"},
    },
    TrkPan6 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth6",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #06 [Set]"},
    },
    TrkPan7 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth7",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #07 [Set]"},
    },
    TrkPan8 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth8",index = 1}},
      options = {action = "Track Levels:Panning:Track XX (Pre):Track #08 [Set]"},
    },

    -- track width --

    TrkWidth1 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth1",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #01 [Set]"},
    },
    TrkWidth2 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth2",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #02 [Set]"},
    },
    TrkWidth3 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth3",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #03 [Set]"},
    },
    TrkWidth4 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth4",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #04 [Set]"},
    },
    TrkWidth5 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth5",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #05 [Set]"},
    },
    TrkWidth6 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth6",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #06 [Set]"},
    },
    TrkWidth7 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth7",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #07 [Set]"},
    },
    TrkWidth8 = {
      application = "MidiActions",
      mappings = {control = {group_name = "TrackPanWidth8",index = 2}},
      options = {action = "Track Levels:Width:Track XX:Track #08 [Set]"},
    },

  }
}


