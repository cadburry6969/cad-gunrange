Config = {}

Config.Framework = 'qb'

Config.Inventory = 'qb'
Config.ItemName = 'gunreceipt'

if Config.Framework == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()

    function GetPlayer(src)
        local player = QBCore.Functions.GetPlayer(src)
        if not player then return nil end
        local data = {}
        data.citizenId = player.PlayerData.citizenid
        data.fullName = player.PlayerData.charinfo.firstname .. ' '.. player.PlayerData.charinfo.lastname
        return data
    end
end

if Config.Framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()
    -- TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

    function GetPlayer(src)
        local player = ESX.GetPlayerFromId(src)
        if not player then return nil end
        local data = {}
        data.citizenId = player.getIdentifier()
        data.fullName = player.getName()
        return data
    end
end

if Config.Framework == 'custom' then

    function GetPlayer(src)
        local data = {}
        data.citizenId = 'NOT DEFINED'
        data.fullName = 'NOT DEFINED'
        return data
    end
end

if Config.Inventory == 'ox' then
    function AddItem(src, data)
        local metadata = data
        metadata.description = ('CitizenId: %s \n\nName: %s \n\nScore: %d \n\nDifficulty: %s \n\nIssued On: %s'):format(data.citizenId, data.fullName, data.score, data.difficulty, data.date)
       return exports.ox_inventory:AddItem(src, Config.ItemName, 1, metadata)
    end
end

if Config.Inventory == 'qb' then
    function AddItem(src, data)
        local info = data
        local description = ('<p><strong>CitizenId: </strong><span>%s</span></p><p><strong>Name: </strong><span>%s</span></p><p><strong>Score: </strong><span>%d</span></p><p><strong>Difficulty: </strong><span>%s</span></p><p><strong>Issued On: </strong><span>%s</span></p>'):format(data.citizenId, data.fullName, data.score, data.difficulty, data.date)
        info.description = description
       return exports['qb-inventory']:AddItem(src, Config.ItemName, 1, nil, info)
    end
end