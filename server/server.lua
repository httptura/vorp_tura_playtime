local Core = exports.vorp_core:GetCore()
local ServerRPC = exports.vorp_core:ServerRpcCall()
local players = {}
local playerCharacters = {}
local playersLoaded = {}

Citizen.CreateThread(function()
    MySQL.Async.fetchAll('SHOW COLUMNS FROM characters LIKE "playtime"', {}, function(result)
        if #result == 0 then
            MySQL.Async.execute('ALTER TABLE characters ADD COLUMN playtime INT DEFAULT 0', {}, function(success)
            end)
        end
    end)
end)

function CacheCharacterData(source)
    local User = Core.getUser(source)
    if User then
        local Character = User.getUsedCharacter
        if Character then
            playerCharacters[source] = {
                charIdentifier = Character.charIdentifier,
                firstname = Character.firstname or "Unbekannt",
                lastname = Character.lastname or "Unbekannt"
            }
            return true
        end
    end
    return false
end

Core.Callback.Register("tura:callback:getPlaytime", function(source, cb, ...)
    local playerTime = players[source] or 0
    cb(playerTime) 
end)

RegisterNetEvent("tura:server:syncTime")
AddEventHandler("tura:server:syncTime", function ()
    local source = source
    

    if not playerCharacters[source] then
        CacheCharacterData(source)
    end
    
    if players[source] then
        players[source] = players[source] + 1
    end
end)

RegisterNetEvent("tura:server:savePlaytime")
AddEventHandler("tura:server:savePlaytime", function()
    local source = source
    
    if not playerCharacters[source] then
        if not CacheCharacterData(source) then
            return
        end
    end
    
    local currentPlaytime = players[source] or 0
    local charData = playerCharacters[source]
    
    if not charData then
        return
    end
    
    MySQL.Async.execute('UPDATE characters SET playtime = @playtime WHERE charidentifier = @identifier', {
        ['@playtime'] = currentPlaytime,
        ['@identifier'] = charData.charIdentifier
    }, function(result)
    end)
end)

RegisterNetEvent("tura:server:loadPlaytime")
AddEventHandler("tura:server:loadPlaytime", function()
    local source = source
    if playersLoaded[source] then
        return
    end
    
    if not CacheCharacterData(source) then
        return
    end
    
    local charData = playerCharacters[source]
    
    MySQL.Async.fetchScalar('SELECT playtime FROM characters WHERE charidentifier = @charidentifier', {
        ['@charidentifier'] = charData.charIdentifier
    }, function(playtime)
        if playtime then
            players[source] = playtime
            playersLoaded[source] = true
            TriggerClientEvent("tura:client:receivePlaytime", source, playtime)
        else
            players[source] = 0
            playersLoaded[source] = true
            MySQL.Async.execute('UPDATE characters SET playtime = @playtime WHERE charidentifier = @charidentifier', {
                ['@playtime'] = 0,
                ['@charidentifier'] = charData.charIdentifier
            }, function(result)
            end)
            TriggerClientEvent("tura:client:receivePlaytime", source, 0)
        end
    end)
end)

function SaveAllPlaytimes()
    local savedCount = 0
    local totalPlayers = 0
    
    for playerId, playtime in pairs(players) do
        totalPlayers = totalPlayers + 1
        local charData = playerCharacters[playerId]
        
        if charData then
            MySQL.Async.execute('UPDATE characters SET playtime = @playtime WHERE charidentifier = @identifier', {
                ['@playtime'] = playtime,
                ['@identifier'] = charData.charIdentifier
            }, function(result)
                savedCount = savedCount + 1
            end)
        else
            savedCount = savedCount + 1
        end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    SaveAllPlaytimes()
    Citizen.Wait(2000)
end)

RegisterNetEvent("vorp:SelectedCharacter")
AddEventHandler("vorp:SelectedCharacter", function(source, character)
    if playersLoaded[source] then
        return
    end

    playerCharacters[source] = {
        charIdentifier = character.charIdentifier,
        firstname = character.firstname or "Unbekannt",
        lastname = character.lastname or "Unbekannt"
    }
    
    Citizen.Wait(1000)
    TriggerEvent("tura:server:loadPlaytime", source)
end)
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    Citizen.Wait(5000)
    
    local onlinePlayers = GetPlayers()
    for _, playerId in ipairs(onlinePlayers) do
        playerId = tonumber(playerId)
        if not playersLoaded[playerId] then
            if CacheCharacterData(playerId) then
                TriggerEvent("tura:server:loadPlaytime", playerId)
            end
        end
    end
end)


AddEventHandler('playerDropped', function(reason)
    local source = source
    
    if players[source] then
        local playtime = players[source]
        local charData = playerCharacters[source]
        
        if charData then
            MySQL.Async.execute('UPDATE characters SET playtime = @playtime WHERE charidentifier = @identifier', {
                ['@playtime'] = playtime,
                ['@identifier'] = charData.charIdentifier
            }, function(result)
            end)
        end
    end

    players[source] = nil
    playerCharacters[source] = nil
    playersLoaded[source] = nil
end)

RegisterCommand("playtime", function(source, args, rawCommand)
    local playerId = source
    
    if players[playerId] then
        local playtime = players[playerId]
        local hours = math.floor(playtime / 60)
        local minutes = playtime % 60
        
        TriggerClientEvent("vorp:TipRight", playerId, message, 5000)
    else
        TriggerClientEvent("vorp:TipRight", playerId, "Deine Spielzeit konnte nicht geladen werden", 5000)
    end
end, false)
