local rangesInUse = {}
GlobalState.GunRangeInUse = {}

RegisterNetEvent('gunrange:server:setInUse', function(id, value)
    rangesInUse[id] = value
    GlobalState.GunRangeInUse = rangesInUse
end)

RegisterNetEvent('gunrange:giveResultReceipt', function(score, difficulty)
    local src = source
    local player = GetPlayer(src)
    if not player then return end
    local date = os.date('%Y-%m-%d %H:%M')
    local citizenId = player.citizenId
    local fullName = player.fullName
    local metadata = {
        citizenId = citizenId,
        fullName = fullName,
        score = score,
        difficulty = difficulty,
        date = date
    }
    if AddItem(src, metadata) then
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'You have received a receipt with your firing results!',
        })
    else
        TriggerClientEvent('ox_lib:notify', src, {
            description = 'Your pockets was full, You couldnt receive firing results receipt!',
        })
    end
end)

RegisterNetEvent('gunrange:saveData', function(message)
    local data = LoadResourceFile(GetCurrentResourceName(), 'saved_locations.lua')
    local output = (data and data..'\n'..message) or message
	SaveResourceFile(GetCurrentResourceName(), 'saved_locations.lua', output, -1)
end)
