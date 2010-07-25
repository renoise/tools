~{do
  -- http://www.mozilla.org/projects/netlib/http/http-caching-faq.html
  L:set_header("Cache-control", "no-cache")
  L:set_header("Cache-control", "no-store")
  L:set_header("Pragma", "no-cache")
  L:set_header("Expires", "0")

  local function s()
    return renoise.song()
  end

  local function serialize(s)
    local str = ''
    for k,v in pairs(s) do
      str = str .. k .. '='.. v .. '\n'
    end
    return str
  end

  local changes = table.create()
  changes['sid'] = s().transport.playback_pos.sequence
  OUT = serialize(changes)
end}