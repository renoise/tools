~{"Server responds: "}
~{do L:header("MyCustomHeader", "Woot!") end}
~{do
   local myvar = P.myvar or ""
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
end}