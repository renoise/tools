~{do L:set_header("Cache-Control", "private, max-age: 3600") end}

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" dir="ltr">
    <head>
      <title>Renoise Live! Action List</title>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <link type="text/css" href="/default.css" rel="stylesheet" />
    </head>
    <body>
      <h1>Renoise Action List</h1>
      ~{do
         local tree = {}
         local levels = {}
         for _,v in ipairs(L:get_action_names()) do
             if not string.find(v, "Window") and
             not string.find(v, "Dialog") and
             not string.find(v, "Sequence XX") and
             not string.find(v, "Seq. XX") then
               OUT = OUT .. "<p>"..v.."</p>\r\n"
            end
         end
       end}

      <p><a href="/">Back to index</a></p>
    </body>
</html>

