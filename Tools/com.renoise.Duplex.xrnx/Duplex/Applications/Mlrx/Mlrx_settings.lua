--[[============================================================================
-- Duplex.Application.Mlrx.Mlrx_settings
============================================================================]]--

--[[--

Mlrx: static methods for storing settings in song comments

]]

--==============================================================================

class 'Mlrx_settings' (Application)

Mlrx_settings.__VERSION = "0.99.0"
Mlrx_settings.TOKEN_START = "-- begin mlrx settings"
Mlrx_settings.TOKEN_END = "-- end mlrx_settings"

--------------------------------------------------------------------------------

function Mlrx_settings.store_local_settings(mlrx)
  TRACE("Mlrx_settings.store_local_settings(mlrx)",mlrx)

  local build_tracks = function()
    local t = table.create()
    for _,trk in ipairs(mlrx.tracks) do
      local grp_idx = mlrx:get_group_index(trk.group)
      t:insert({
        group_index = grp_idx,
        velocity = trk.velocity,
        panning = trk.panning,
        shuffle_amount = trk.shuffle_amount,
        instr_index = trk.rns_instr_idx,
        track_index = trk.rns_track_idx,
        note_pitch = trk.note_pitch,
        trig_mode = trk.trig_mode,
        arp_enabled = trk.arp_enabled,
        arp_mode = trk.arp_mode,
        drift_mode = trk.drift_mode,
        drift_amount = trk.drift_amount,
        do_sxx_output = trk.do_sxx_output,
        do_exx_output = trk.do_exx_output,
        cycle_lines = trk.cycle_lines,
        cycle_length = trk.cycle_length,
      })
    end
    return t
  end

  local build_groups = function()
    local t = table.create()
    for _,grp in ipairs(mlrx.groups) do
      t:insert({
        velocity = grp.velocity,
        panning = grp.panning,
      })
    end
    return t
  end

  local config = {
    __version = Mlrx_settings.__VERSION,
    number_of_tracks = #mlrx.tracks,
    selected_track = mlrx.selected_track,
    tracks = build_tracks(),
    groups = build_groups(),
  }

  xPersistentSettings.store(config,
    Mlrx_settings.TOKEN_START,Mlrx_settings.TOKEN_END)

end

--------------------------------------------------------------------------------

function Mlrx_settings.retrieve_local_settings(mlrx)
  TRACE("Mlrx_settings.retrieve_local_settings(mlrx)",mlrx)

  local skip_output = true

  local apply_settings = function(t)
    for k,v in pairs(t) do
      if (k=="selected_track") then
        mlrx:select_track(v)
      elseif (k=="groups") then
        for k2,v2 in ipairs(v) do
          for k3,v3 in pairs(v2) do
            local grp = mlrx.groups[k2]
            if (k3 == "velocity") then
              grp:set_grp_velocity(v3,skip_output)
            elseif (k3 == "panning") then
              grp:set_grp_panning(v3,skip_output)
            end
          end
        end
      elseif (k=="tracks") then
        for k2,v2 in ipairs(v) do
          for k3,v3 in pairs(v2) do
            local trk = mlrx.tracks[k2]
            if trk then 
              if (k3 == "group_index") then
                mlrx:assign_track(v3,k2,true)
              elseif (k3 == "velocity") then
                trk:set_trk_velocity(v3,skip_output)
              elseif (k3 == "panning") then
                trk:set_trk_panning(v3,skip_output)
              elseif (k3 == "shuffle_amount") then
                trk.shuffle_amount = v3
              elseif (k3 == "track_index") then
                trk.rns_track_idx = v3
                trk:attach_to_track()
              elseif (k3 == "instr_index") then
                trk.rns_instr_idx = v3
                trk:attach_to_instr()
              elseif (k3 == "note_pitch") then
                trk.note_pitch = v3
                trk:set_transpose(0)
              elseif (k3 == "trig_mode") then
                trk:set_trig_mode(v3)
              elseif (k3 == "arp_enabled") then
                trk.arp_enabled = v3
              elseif (k3 == "arp_mode") then
                trk:set_arp_mode(v3)
              elseif (k3 == "drift_mode") then
                trk:set_drift_mode(v3)
              elseif (k3 == "drift_amount") then
                trk:set_drift_amount(v3)
              elseif (k3 == "do_sxx_output") then
                trk:set_sxx_output(v3)
              elseif (k3 == "do_exx_output") then
                trk:set_exx_output(v3)
              elseif (k3 == "cycle_lines") then
                trk.cycle_lines = v3 
              elseif (k3 == "cycle_length") then
                trk:set_cycle_length(v3,true)
              end
            else
              -- TODO some tracks could not be imported,
              -- show this information in the status bar

            end
          end
        end
      end
      
    end

    mlrx:update_matrix()

  end

  local config,err = xPersistentSettings.retrieve(Mlrx_settings.TOKEN_START,Mlrx_settings.TOKEN_END)
  if not config then 
    if err then
      renoise.app():show_status(err)  
    end
    return
  end 

  apply_settings(config)


end 

