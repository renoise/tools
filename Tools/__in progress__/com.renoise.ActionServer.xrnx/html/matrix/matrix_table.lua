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
          out(("<th id='t%02d' class='%s'>%s</th>")
            :format(tid, get_mute_state(t.mute_state), t.name))
        end
        out("</tr></thead><tbody>")
    
        -- get patterns
        local pattern
        for sid,pid in pairs(s().sequencer.pattern_sequence) do
          local current_seq = ''
          if (sid == s().transport.playback_pos.sequence) then
              current_seq = "class='current_seq'"
          end
          out(("<tr id='s%d' %s>"):format(sid, current_seq))
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

            out( ("<td class='%s' id='s%02dt%02d'></td>")
              :format(classes:concat(' '),sid, tid, sid, tid) )

          end
          out("</tr>")
        end

        out("</tbody></table>")
        OUT = str
end}