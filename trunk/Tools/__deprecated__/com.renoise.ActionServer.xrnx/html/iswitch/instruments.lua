~{do
    -- http://www.mozilla.org/projects/netlib/http/http-caching-faq.html
    L:set_header("Cache-control", "no-cache")
    L:set_header("Cache-control", "no-store")
    L:set_header("Pragma", "no-cache")
    L:set_header("Expires", "0")

    local str = ""
    local function out(s)
      str = str .. "\n"  .. s
    end

    out("<table>")
    for k,inst in ipairs(renoise.song().instruments) do
      out(("<tr id='i%d'><td class='id'>%02X</td><td>%s</td></tr>"):format(k, k-1, inst.name))
    end
    out("</table>")

    OUT = str
  end}