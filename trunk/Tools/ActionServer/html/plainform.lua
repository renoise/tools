<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" dir="ltr">
  <head>
      <title>Plain Form Handler</title>
      <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
      <meta http-equiv="refresh" content="1;url=http://~{L:get_address()}" />
      <link type="text/css" href="default.css" rel="stylesheet" />
    </head>
    <body>
      <p style="font-weight: bold">
~{do
   local myvar = P.submit_button or ""
   local action = myvar:upper()
   if action == "PLAY" then
      OUT = "Starting playback."
      renoise.song().transport:start(1)
   elseif action == "STOP" then
      OUT = "Stopping playback."
      renoise.song().transport:stop()
   else 
      OUT = "No action received."
   end
end}  </p>
      <p>Thanks for submitting the form! Redirecting in 1 second. Or <a href="/">return to index now<a/>.</p>
   </body>
</html>