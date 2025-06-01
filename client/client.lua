local Core = exports.vorp_core:GetCore()
local Script = {}
local ClientRPC = exports.vorp_core:ClientRpcCall()
local timeCheck = 60000
local playtime

Citizen.CreateThread(function ()
    while not NetworkIsSessionActive() do 
        Wait(100)
    end

    TriggerServerEvent("tura:server:loadPlaytime")

    while true do 
        Wait(10000) 
        syncTime()
        getPlaytime()
    end
end)

function syncTime()
    TriggerServerEvent("tura:server:syncTime")
end

function getPlaytime()
    Core.Callback.TriggerAsync("tura:callback:getPlaytime", function(data)
        playtime = data
    end)
   return playtime
end

exports("getPlaytime", getPlaytime())

RegisterCommand("cbtime", function()
    TriggerServerEvent("tura:server:savePlaytime")
end)






