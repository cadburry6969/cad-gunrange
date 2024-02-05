local totalScore = 0
local obj = nil

local function UpdateScore(diff)
    local text = {
        ('Status: %s  \n'):format('Active'),
		('Difficulty: %s  \n'):format(diff),
		('Current Score: %d  \n'):format(totalScore),
    }

    lib.showTextUI(table.concat(text))
end

local function FinalScore(id, difficulty)
    lib.hideTextUI()

    local text = {
        ('Status: %s  \n'):format('Completed'),
		('Difficulty: %s  \n'):format(difficulty),
		('Final Score: %d  \n'):format(totalScore),
    }

    lib.showTextUI(table.concat(text))

    TriggerServerEvent('gunrange:server:setInUse', id, false)
    TriggerServerEvent('gunrange:giveResultReceipt', totalScore, difficulty)
    SetTimeout(5000, function()
        lib.hideTextUI()
    end)
end

local function getRandomTarget(targets)
    local randomIndex = math.random(1, #targets)
    return targets[randomIndex]
end

local function SpawnTarget(model, coords, rotation, hpt, maxR)
    local x, y, z, w = table.unpack(coords)
    model = model or `prop_range_target_01`
    local shot = 0

    lib.requestModel(model)

    obj = CreateObject(model, x, y, z, true, true, true)
    SetEntityHeading(obj, w)
    SetEntityProofs(obj, false, true, false, false, false, false, false, false)
    SetEntityRotation(obj, rotation)
    PlaySoundFrontend(-1, "SHOOTING_RANGE_ROUND_OVER", "HUD_AWARDS", true)

    Wait(1)

    local iterations = 0

    while shot < hpt do
        Wait(0)
        iterations = iterations + 1
        if IsPedShooting(cache.ped) then
            Wait(100)
            if iterations > maxR or HasEntityBeenDamagedByWeapon(obj, 0, 2) then
                PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
                shot = (iterations > maxR) and (shot + 100) or (shot + 1)
                totalScore = (iterations > maxR and totalScore) or (totalScore + 1)
                ClearEntityLastDamageEntity(obj)
            else
                PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
                shot = shot + 1
            end
        elseif iterations > maxR then
            PlaySoundFrontend(-1, "CONFIRM_BEEP", "HUD_MINI_GAME_SOUNDSET", true)
            shot = shot + 100
        end
    end

    DeleteEntity(obj)
    SetModelAsNoLongerNeeded(model)
end

local function UseRange(difficulty, data, weaponData)
    if GlobalState.GunRangeInUse[data.id] then
        return lib.notify({ description = 'The Firing Range is already in use!' })
    end

    TriggerServerEvent('gunrange:server:setInUse', data.id, true)
    GiveWeaponToPed(cache.ped, weaponData.hash, weaponData.ammo, false, true)
    SetCurrentPedWeapon(cache.ped, weaponData.hash, true)
    if weaponData.infiniteAmmo then SetPedInfiniteAmmo(cache.ped, true, weaponData.hash) end
    totalScore = 0
    local currentTarget = { model = `prop_range_target_01`, coords = vec4(0, 0, 0, 0), rotation = vec3(0, 0, 0) }
    local diff = Config.Difficulty[difficulty]
    local maxtargets = data.maxtargets or 19
    UpdateScore(diff.label)

    PlaySoundFrontend(-1, "Checkpoint_Hit", "GTAO_FM_Events_Soundset", false)
    Wait(1000)
    PlaySoundFrontend(-1, "Checkpoint_Hit", "GTAO_FM_Events_Soundset", false)
    Wait(1000)
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", false)
    Wait(1000)

    for i = 1, maxtargets, 1 do
        Wait(diff.time)
        currentTarget = getRandomTarget(data.targets)
        SpawnTarget(currentTarget.model, currentTarget.coords, currentTarget.rotation, diff.hpt, diff.maxr)
        UpdateScore(diff.label)
    end
    Wait(1000)
    SetPedInfiniteAmmo(cache.ped, false, weaponData.hash)
    RemoveWeaponFromPed(cache.ped, weaponData.hash)
    SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
    FinalScore(data.id, diff.label)
end

local function OpenDifficultyMenu(data, weaponData)
    local options = {}
    for diff, _data in pairs(Config.Difficulty) do
        options[#options + 1] = {
            title = _data.label,
            icon = 'fas fa-gun',
            onSelect = function()
                UseRange(diff, data, weaponData)
            end,
        }
    end
    lib.registerContext({
        id = 'weapon_range_difficulty',
        title = 'Firing Range (Choose Difficulty)',
        options = options
    })
    lib.showContext('weapon_range_difficulty')
end

local function OpenTestMenu(data)
    local result = CanOpenMenu()
    if not result.status then return lib.notify({ description = result.msg, type = "error" }) end
    lib.hideTextUI()
    local options = {}
    for _, _data in ipairs(Config.Weapons) do
        options[#options+1] = {
            title = _data.label,
            icon = 'fas fa-gun',
            onSelect = function()
                OpenDifficultyMenu(data, _data)
            end,
        }
    end
    lib.registerContext({
        id = 'weapon_range_choose',
        title = 'Firing Range (Choose Weapon)',
        options = options
    })
    lib.showContext('weapon_range_choose')
end

local function onEnter(self)
    lib.showTextUI('[E] ' .. self.data.name)
end

local function onExit(self)
    lib.hideTextUI()
end

local function insideZone(self)
    if IsControlJustPressed(0, 38) then
        OpenTestMenu(self.data)
    end
end

CreateThread(function()
    for _, data in pairs(Config.Locations) do
        if Config.UseTarget then
            exports[Config.UseTarget]:addBoxZone({
                coords = data.zone.coords,
                size = data.zone.size,
                rotation = data.zone.rotation,
                debug = data.zone.debug or false,
                drawSprite = true,
                options = {
                    {
                        label = data.name,
                        icon = 'fa-solid fa-gun',
                        onSelect = function()
                            OpenTestMenu(data)
                        end
                    }
                }
            })
        else
            lib.zones.box({
                coords = data.zone.coords,
                size = data.zone.size,
                rotation = data.zone.rotation,
                debug = data.zone.debug or false,
                data = data,
                inside = insideZone,
                onEnter = onEnter,
                onExit = onExit
            })
        end
        if data.hidemodels then
            for _, target in pairs(data.targets) do
                for _, model in pairs(data.hidemodels) do
                    CreateModelHide(target.coords.x, target.coords.y, target.coords.z, 2.0, model, true)
                end
            end
        end
    end
end)

CreateThread(function()
    lib.hideTextUI()
    local oldcoords = nil
    while Config.Debug do
        Wait(0)
        local pos = GetEntityCoords(cache.ped)
        local hit, entity = GetEntityPlayerIsFreeAimingAt(cache.playerId)
        if hit then
            local coords = GetEntityCoords(entity)
            local heading = GetEntityHeading(entity)
            coords = vec4(coords.x, coords.y, coords.z, heading)
            local rotation = GetEntityRotation(entity)
            local model = GetEntityModel(entity)
            DrawLine(pos.x, pos.y, pos.z, coords.x, coords.y, coords.z, 100, 100, 255, 255)
            if oldcoords ~= coords then
                oldcoords = coords
                local textShow = {
                    'Model: ' .. model .. ' \n',
                    'Coords: ' .. coords .. ' \n',
                    'Heading: ' .. heading .. ' \n',
                    'Rotation: ' .. rotation .. ' \n',
                    '[E] Save'
                }

                lib.showTextUI(table.concat(textShow))
            end
            if IsControlJustPressed(0, 38) then
                local data = '{ model = ' .. model .. ', coords = ' .. coords .. ', rotation = ' .. rotation .. ' },'
                TriggerServerEvent('gunrange:saveData', data)
            end
        end
    end
end)
