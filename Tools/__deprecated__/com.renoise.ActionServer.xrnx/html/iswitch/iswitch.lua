~{do
    -- http://www.mozilla.org/projects/netlib/http/http-caching-faq.html
    L:set_header("Cache-control", "no-cache")
    L:set_header("Cache-control", "no-store")
    L:set_header("Pragma", "no-cache")
    L:set_header("Expires", "0")
    
    local client_id = tonumber(P.client_id) or 1

    -- Setters

    if (P.inst) then
      renoise.song().selected_instrument_index = tonumber(P.inst)
    end

    -- Getters

    L:subscribe(client_id, "renoise.song().selected_instrument_index", function(name)
      L:publish(name, 'inst', renoise.song().selected_instrument_index)
    end)
    
    L:subscribe(client_id, "renoise.tool().app_new_document", function(name)
      L:reset_notifiers()    
      L:publish(name, 'song_change', true)
      L:publish("renoise.song().selected_instrument_index", 'inst', renoise.song().selected_instrument_index)
    end)

    -- Output

    OUT = L:get_messages_for(client_id)
end}