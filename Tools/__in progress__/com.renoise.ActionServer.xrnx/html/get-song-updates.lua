~{do
  -- http://www.mozilla.org/projects/netlib/http/http-caching-faq.html
  L:set_header("Cache-control", "no-cache")
  L:set_header("Cache-control", "no-store")
  L:set_header("Pragma", "no-cache")
  L:set_header("Expires", "0")

  local function s()
    return renoise.song()
  end

  local changes = table.create()

  L:subscribe("renoise.tool().app_new_document", function()
    L:publish('song_change', true)
  end)

  L:subscribe("renoise.song().sequencer.pattern_slot_mutes", function()
    L:publish('mutes_changed', true)
  end)

  L:publish('sid', s().transport.playback_pos.sequence)
  OUT = L:serialize(L.changes)
end}