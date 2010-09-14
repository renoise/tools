~{do
        -- http://www.mozilla.org/projects/netlib/http/http-caching-faq.html
        L:set_header("Cache-control", "no-cache")
        L:set_header("Cache-control", "no-store")
        L:set_header("Pragma", "no-cache")
        L:set_header("Expires", "0")
        
        -------------------

        function s()
          return renoise.song()
        end

        local str = ""
        local function out(s)
          str = str .. "\n"  .. s
        end

        local function get_mute_state(state)
          local states = {'active','off','muted'}
          return states[state]
        end

        -------------------

        out("<table id='table_matrix'>")

        -- get tracks
        local tnum = #s().tracks
        out("<thead><tr><th title='Schedule'>S</th><th title='Loop'>L</th><th>#</th><th>label</th>")
        for tid,t in ipairs(s().tracks) do
          local classes = table.create()
          out(("<th id='t%02d' class='t%02d %s'>%s</th>")
            :format(tid, tid, get_mute_state(t.mute_state), t.name))
        end
        out("</tr></thead><tbody>")

        -- get patterns
        local pattern
        local seq_loop = renoise.song().transport.loop_sequence_range
        for sid,pid in pairs(s().sequencer.pattern_sequence) do

          local current_seq = ''
          local classes = table.create()

          if (sid == s().transport.playback_pos.sequence) then
            classes:insert('current_seq')
          end

          if (seq_loop[1] > 0 and sid >= seq_loop[1] and sid <= seq_loop[2]) then
            classes:insert('seq_loop')
          end

          if (not classes:is_empty()) then
            out(("<tr id='s%d' class='%s'>"):format(sid, classes:concat(' ')))
          else
            out(("<tr id='s%d'>"):format(sid))
          end

          local name = s().patterns[pid].name
          out(("<td class='s'>&gt;</td><td class='l'></td><td class='pid'>%d</td><td class='label'>%s</td>"):format(pid-1,name))
          local seq_mute = false

          for tid=1,tnum do
            for pos,col in s().pattern_iterator:lines_in_pattern_track(pid, tid) do
              seq_mute = s().sequencer:track_sequence_slot_is_muted(tid, sid)
              break
            end

            -- add classes
            local classes = table.create{"p"}
            if (s().patterns[pid].tracks[tid].is_empty) then
              classes:insert("empty")
            end
            if (seq_mute) then
              classes:insert("seq_mute")
            end
            local track_type = s().tracks[tid].type
            if (track_type == renoise.Track.TRACK_TYPE_MASTER) then
              classes:insert("mst")
            elseif (track_type == renoise.Track.TRACK_TYPE_SEND) then
              classes:insert("send")
            end

            if (s().tracks[tid].mute_state == renoise.Track.MUTE_STATE_OFF) then
              classes:insert('off')
            elseif (s().tracks[tid].mute_state == renoise.Track.MUTE_STATE_MUTED) then
              classes:insert('muted')
            end

            classes:insert(('s%02d'):format(sid))
            classes:insert(('t%02d'):format(tid))

            out( ("<td class='%s' id='s%02dt%02d'></td>")
              :format(classes:concat(' '),sid, tid) )

          end
          out("</tr>")
        end

        out("</tbody></table>")
        out("<script type='text/javascript'>")
        out(("var bpm = %f"):format(renoise.song().transport.bpm));
        out(("var line = %f"):format(renoise.song().transport.playback_pos.line));
        local pid = renoise.song().sequencer.pattern_sequence[renoise.song().transport.playback_pos.sequence]
        out(("var lines = %f"):format(renoise.song().patterns[pid].number_of_lines));
        out("</script>");
        OUT = str
end}