~{do
  -- http://www.mozilla.org/projects/netlib/http/http-caching-faq.html
  L:set_header("Cache-control", "no-cache")
  L:set_header("Cache-control", "no-store")
  L:set_header("Pragma", "no-cache")
  L:set_header("Expires", "0")

  -- JSON
  --L:set_header("Content-Type", "application/json")
  
  local client_id = tonumber(P.client_id) or 1

  function subscribe_track_mutes()
   for tid,_ in ipairs(renoise.song().tracks) do
      L:subscribe(client_id, "renoise.song().tracks["..tid.."].mute_state", function(name)
        L:publish(name, 'track_state_changed',
          {tid=("%02d"):format(tid), state=renoise.song().tracks[tid].mute_state}
        )
      end)
   end
  end

  function get_changed_mute_states()
    print("get_changed_mute_states")
    local mutes = {}
    local changes = {}
    for track_index,_ in ipairs(renoise.song().tracks) do
      for sequence_index,_ in ipairs(renoise.song().sequencer.pattern_sequence) do
        if (not mutes[track_index]) then
          mutes[track_index] = {}
        end
        mutes[track_index][sequence_index] = renoise.song().sequencer:track_sequence_slot_is_muted(track_index, sequence_index)
        if (L.old_mutes and L.old_mutes[track_index][sequence_index] ~= mutes[track_index][sequence_index]) then
          local pos = ("s%02dt%02d"):format(sequence_index, track_index)
          changes[pos] = mutes[track_index][sequence_index]
        end
      end
    end
    L.old_mutes = mutes
    rprint(changes)
    return changes
  end

  -- initial
  if (not L.old_mutes) then
    get_changed_mute_states()
  end
  
  subscribe_track_mutes()

  L:subscribe(client_id, "renoise.tool().app_new_document", function(name)
    print("New song")
    L:publish(name, 'song_change', true)
    L:reset_notifiers()
    L.old_mutes = nil
  end)

  L:subscribe(client_id, "renoise.song().sequencer.pattern_slot_mutes", function(name)
    L:publish(name, 'mutes_changed', get_changed_mute_states())
  end)

  L:subscribe(client_id, "renoise.song().transport.bpm", function(name)
    L:publish(name, 'tempo', renoise.song().transport.bpm)
  end)

  local pid = renoise.song().sequencer.pattern_sequence[renoise.song().transport.playback_pos.sequence]
  L:publish(nil, 'lines', renoise.song().patterns[pid].number_of_lines)

  L:publish(nil, 'sid', renoise.song().transport.playback_pos.sequence)

  -- L:publish(nil, 'line', renoise.song().transport.playback_pos.line)

  L:publish(nil, 'seq_loop', renoise.song().transport.loop_sequence_range)

  OUT = L:get_messages_for(client_id)
end}
