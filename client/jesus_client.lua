local QBCore = exports['qb-core']:GetCoreObject()
local InvType = Config.CoreSettings.Inventory.Type
local TargetType = Config.CoreSettings.Target.Type
local NotifyType = Config.CoreSettings.Notify.Type
local busy, inChurch = false, false
local spawnedChurchProps = {}


--notification function
local function SendNotify(msg,type,time,title)
    if NotifyType == nil then print("Lusty94_Jesus: NotifyType Not Set in Config.CoreSettings.Notify.Type!") return end
    if not title then title = "Jesus" end
    if not time then time = 5000 end
    if not type then type = 'success' end
    if not msg then print("Notification Sent With No Message.") return end
    if NotifyType == 'qb' then
        QBCore.Functions.Notify(msg,type,time)
    elseif NotifyType == 'okok' then
        exports['okokNotify']:Alert(title, msg, time, type, true)
    elseif NotifyType == 'mythic' then
        exports['mythic_notify']:DoHudText(type, msg)
    elseif NotifyType == 'boii' then
        exports['boii_ui']:notify(title, msg, type, time)
    elseif NotifyType == 'ox' then
        lib.notify({ title = title, description = msg, type = type, duration = time})
    end
end

--church blip
CreateThread(function()
    for k, v in pairs(Config.Blips) do
        if v.useblip then
            v.blip = AddBlipForCoord(v.coords.x, v.coords.y, v.coords.z)
            SetBlipSprite(v.blip, v.id)
            SetBlipDisplay(v.blip, 4)
            SetBlipScale(v.blip, v.scale)
            SetBlipColour(v.blip, v.colour)
            SetBlipAsShortRange(v.blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(v.title)
            EndTextCommandSetBlipName(v.blip)
        end
    end
end)


--church door boxzone
CreateThread(function()
    for k,v in pairs(Config.InteractionLocations) do
        if TargetType == 'qb' then
            exports['qb-target']:AddBoxZone(v.Name, v.Coords, v.Width, v.Height, { name = v.Name, heading = v.Heading, debugPoly = Config.DebugPoly, minZ = v.MinZ, maxZ = v.MaxZ, }, { options = { { type = "client", event = v.Event, icon = v.Icon, label = v.Label, job = v.Job, item = v.Item, } }, distance = v.Distance, })
        elseif TargetType =='ox' then
            exports.ox_target:addBoxZone({
                coords = v.Coords, size = v.Size, rotation = v.Heading, debug = Config.DebugPoly, options = { { id = v.Name, item = v.Item, groups = v.Job, event = v.Event, label = v.Label, icon = v.Icon, distance = v.Distance, } }, })
        elseif TargetType == 'custom' then
            --insert your own custom target code here
        end
    end
end)

--chuch props
CreateThread(function()
    for k,v in pairs(Config.Props) do
        lib.requestModel(v.Model, 5000)
        churchProps = CreateObject(v.Model, v.Coords.x, v.Coords.y, v.Coords.z - 1, true, false, false)
        spawnedChurchProps[#spawnedChurchProps+1] = churchProps
        SetEntityHeading(churchProps, v.Coords.w)
        PlaceObjectOnGroundProperly(churchProps, true)
        FreezeEntityPosition(churchProps, true)
    end
end)


--jesus ped
CreateThread(function()
    for k,v in pairs(Config.InteractionLocations) do
        lib.requestModel(v.JesusPedModel, 5000)
        jesusPed = CreatePed(0, v.JesusPedModel, v.JesusSpawn.x, v.JesusSpawn.y, v.JesusSpawn.z - 1, true, false)
        SetEntityHeading(jesusPed, v.JesusSpawn.w)
        FreezeEntityPosition(jesusPed, true)
        SetEntityInvincible(jesusPed, true)
        SetBlockingOfNonTemporaryEvents(jesusPed, true)
        local jesusDict = 'timetable@amanda@ig_4'
        local jesusAnim = 'ig_4_base'
        lib.requestAnimDict(jesusDict, 5000)
        TaskPlayAnim(jesusPed, jesusDict, jesusAnim, 1.0, -1.0, 1.0, 11, 49, 0, 0, 0)        
        if TargetType == 'qb' then
            exports['qb-target']:AddTargetEntity(jesusPed, { options = { { type = "client", event = "lusty94_jesus:client:prayToJesus", icon = v.PrayingIcon, label = v.PrayingLabel,}, { type = "client", event = "lusty94_jesus:client:exitChurch", icon = v.ExitIcon, label = v.ExitLabel, }, }, distance = v.JesusDistance })
        elseif TargetType == 'ox' then
            exports.ox_target:addLocalEntity(jesusPed, { { name = 'jesusPed', icon = v.PrayingIcon, label = v.PrayingLabel, event = 'lusty94_jesus:client:prayToJesus', distance = v.JesusDistance, }, { name = 'jesusPed', icon = v.ExitIcon, label = v.ExitLabel, event = 'lusty94_jesus:client:exitChurch', distance = v.JesusDistance }, })
        end
    end
end)

--enter church
RegisterNetEvent('lusty94_jesus:client:enterChurch', function()
    local playerPed = PlayerPedId()
    if busy then
        SendNotify(Config.Language.Notifications.BusyName, 'error', 2000)
    else
        for k,v in pairs(Config.InteractionLocations) do
            inChurch = true
            SetEntityCoords(playerPed, v.PlayerSpawn)
            SetEntityHeading(playerPed, v.PlayerSpawn.w)
            SendNotify(Config.Language.Notifications.ChurchEnterName, 'success', 2000)
            if Config.CoreSettings.Sound.UseInteractSound then
                TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, Config.CoreSettings.Sound.EnterChurch, 0.5)
            end
        end
    end
end)

--play lords prayer when entering church
function churchMusic()
    if Config.CoreSettings.Sound.UseInteractSound then
        TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, Config.CoreSettings.Sound.LordsPrayer, 0.5)
    end
end

--lib.zones
local churchZone = lib.zones.box({
    coords = Config.ChurchZone.Coords,
    size = Config.ChurchZone.Size,
    rotation = Config.ChurchZone.Heading,
    debug = Config.DebugPoly,
    onEnter = churchMusic,
})

--exit church
RegisterNetEvent('lusty94_jesus:client:exitChurch', function()
    local playerPed = PlayerPedId()
    if busy then
        SendNotify(Config.Language.Notifications.BusyName, 'error', 2000)
    else
        for k,v in pairs(Config.InteractionLocations) do
            inChurch = false
            SetEntityCoords(playerPed, v.Coords)
            SetEntityHeading(playerPed, v.Heading - 180)
            SendNotify(Config.Language.Notifications.ChurchLeaveName, 'success', 2000)
            if Config.CoreSettings.Sound.UseInteractSound then
                TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, Config.CoreSettings.Sound.ExitChurch, 0.5)
            end
        end
    end
end)

--pray to jesus
RegisterNetEvent('lusty94_jesus:client:prayToJesus', function(args)
    local args = tonumber(args)
    local playerPed = PlayerPedId()
    local StressEvent = Config.CoreSettings.EventNames.Stress
    local stressReduced = Config.CoreSettings.Effects.RemoveStressAmount
    if busy then
        SendNotify(Config.Language.Notifications.BusyName, 'error', 2000)
    else
        QBCore.Functions.TriggerCallback('lusty94_jesus:get:StressLevels', function(isStressed)
            if isStressed then
                if lib.alertDialog({header = 'Church Donations Fund', content = '✨ You must make a donation to the church for Jesus to speak to you! \n \n \n \n 💰 Minimum amount you can donate is $1 💰', centered = true, cancel = false, size = 'lg', overflow = true, } ) then
                    local input = lib.inputDialog('Church Donations', {
                        {
                            type = 'input',
                            placeholder = 'How much do you want to donate?',
                            disabled = true,
                        },
                        {
                            type = 'slider',
                            required = true,
                            default = 1,
                            min = 1, max = 1000,
                        },
                        {
                            type = 'input',
                            placeholder = 'Do you want some bread and wine?',
                            disabled = true,
                        },
                        {
                            type = 'checkbox',
                            label = 'Yes / No',
                            checked = true,
                            required = false,
                        },
                    })
                    if input then
                        if tonumber(input[2]) >= 0 then
                            local amount = tonumber(input[2])
                            local checkbox = input[4]
                            QBCore.Functions.TriggerCallback('lusty94_jesus:get:DonationAmount', function(hasMoney)
                                if hasMoney then
                                    busy = true
                                    LockInventory(true)
                                    TriggerServerEvent('lusty94_jesus:server:DonateMoney', amount)
                                    if lib.progressCircle({ duration = Config.CoreSettings.Timers.PrayToJesus, label = Config.Language.ProgressBar.PrayToJesus, position = 'bottom', useWhileDead = false, canCancel = true, disable = { car = true, move = true, }, anim = { dict = Config.Animations.Prayer.AnimDict, clip = Config.Animations.Prayer.Anim, flag = Config.Animations.Prayer.Flags}, }) then
                                        if checkbox then TriggerServerEvent('lusty94_jesus:server:GiveBreadWine') end
                                        busy = false
                                        LockInventory(false)
                                        TriggerServerEvent(StressEvent, stressReduced)
                                        local goodTripChance = Config.CoreSettings.Chances.GoodTrip
                                        if goodTripChance >= math.random(1,100) then
                                            SendNotify(Config.Language.Notifications.GoodTripName, 'success', 2000)
                                            doTrips(1)                                        
                                        else
                                            SendNotify(Config.Language.Notifications.BadTripName, 'error', 2000)
                                            doTrips(2)
                                        end
                                    else 
                                        busy = false
                                        LockInventory(false)
                                        SendNotify(Config.Language.Notifications.CancelledName, 'error', 2000)
                                    end
                                else
                                    SendNotify(Config.Language.Notifications.NotEnoughName, 'error', 2000)
                                end
                            end, amount)
                        else
                            SendNotify(Config.Language.Notifications.TooMuchName, 'error', 2000)
                        end
                    else
                        SendNotify(Config.Language.Notifications.DonationRequirementName, 'error', 2000)
                    end
                end
            else
                SendNotify(Config.Language.Notifications.NotStressedName, 'error', 2000)
            end
        end)
    end
end)

--trips
function doTrips(args)
    local args = tonumber(args)
    local playerPed = PlayerPedId()
    busy = true
    if args == 1 then -- good trip
        local armourEnabled = Config.CoreSettings.Effects.AddArmour
        local armourGained = Config.CoreSettings.Effects.ArmourAmount
        local healthEnabled = Config.CoreSettings.Effects.AddHealth
        local healthGained = Config.CoreSettings.Effects.HealthAmount
        Wait(2000)
        SetFlash(0, 0, 500, 7000, 500)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.00)
        Wait(3000)
        ShakeGameplayCam('DRUNK_SHAKE', 1.10)
        Wait(3000) 
        SetTimecycleModifier('spectator5')
        SetPedMotionBlur(playerPed, true)
        SetFlash(0, 0, 500, 7000, 500)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.10)
        Wait(3000)
        SetFlash(0, 0, 500, 7000, 500)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.10)
        Wait(3000)
        DoScreenFadeOut(1000)
        if armourEnabled then
            AddArmourToPed(playerPed, armourGained)
        end
        if healthEnabled then
            SetEntityHealth(playerPed, GetEntityHealth(playerPed) + healthGained)
        end
        DoScreenFadeIn(1500)
        Wait(3000)
        SendNotify(Config.Language.Notifications.FeelingBetterName, 'success', 2000)
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        StopGameplayCamShaking(playerPed, true)
        SetPedIsDrunk(playerPed, false)
        SetPedMotionBlur(playerPed, false)
        busy = false
    elseif args == 2 then -- bad trip
        Wait(2000)
        SetFlash(0, 0, 500, 7000, 500)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.00)
        Wait(2000)
        ShakeGameplayCam('DRUNK_SHAKE', 1.10)
        Wait(3000) 
        SetTimecycleModifier('spectator5')
        SetPedMotionBlur(playerPed, true)
        SetFlash(0, 0, 500, 7000, 500)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.10)
        Wait(2000)
        SetFlash(0, 0, 500, 7000, 500)
        ShakeGameplayCam('LARGE_EXPLOSION_SHAKE', 1.10)
        Wait(1000)
        DoScreenFadeOut(1000)
        Wait(2500)
        local teleportChance = Config.CoreSettings.Chances.Teleport
        if teleportChance >= math.random(1,100) then
            SetEntityCoords(playerPed, Config.CoreSettings.Effects.TeleportLocation.x, Config.CoreSettings.Effects.TeleportLocation.y, Config.CoreSettings.Effects.TeleportLocation.z, true, false, false, false)
            SetEntityHeading(playerPed, Config.CoreSettings.Effects.TeleportLocation.w)
        end
        Wait(1000)
        lib.requestAnimDict(Config.Animations.Effects.AnimDict, 5000)
        TaskPlayAnim(playerPed, Config.Animations.Effects.AnimDict, Config.Animations.Effects.Anim, 1.0, -1.0, 1.0, 11, Config.Animations.Effects.Flags, 0, 0, 0)
        Wait(2500)
        DoScreenFadeIn(1500)
        Wait(5000)
        SendNotify(Config.Language.Notifications.SoulCleansedName, 'success', 2000)
        ClearTimecycleModifier()
        ResetScenarioTypesEnabled()
        StopGameplayCamShaking(playerPed, true)
        SetPedIsDrunk(playerPed, false)
        SetPedMotionBlur(playerPed, false)
        ClearPedTasksImmediately(playerPed)
        busy = false
    end
end

-- function to lock inventory to prevent exploits
function LockInventory(toggle) -- big up to jim for how to do this
	if toggle then
        LocalPlayer.state:set("inv_busy", true, true) -- used by qb, ps and ox

        --this is the old method below uncomment if needed
        --[[         
        if InvType == 'qb' then
            this is for the old method if using old qb and ox
            TriggerEvent('inventory:client:busy:status', true) TriggerEvent('canUseInventoryAndHotbar:toggle', false)
        elseif InvType == 'ox' then
            LocalPlayer.state:set("inv_busy", true, true)
        end         
        ]]
    else 
        LocalPlayer.state:set("inv_busy", false, true) -- used by qb, ps and ox

        --this is the old method below uncomment if needed
        --[[        
        if InvType == 'qb' then
            this is for the old method if using old qb and ox
         TriggerEvent('inventory:client:busy:status', false) TriggerEvent('canUseInventoryAndHotbar:toggle', true)
        elseif InvType == 'ox' then
            LocalPlayer.state:set("inv_busy", false, true)
        end        
        ]]
    end
end

--dont touch
AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
        busy = false
        LockInventory(false)
        for _, v in pairs(spawnedChurchProps) do SetEntityAsMissionEntity(v, false, true) DeleteObject(v) end print('Church Props - Objects Deleted')
        for k, v in pairs(Config.InteractionLocations) do if TargetType == 'qb' then exports['qb-target']:RemoveZone(v.Name) elseif TargetType == 'ox' then exports.ox_target:removeZone(v.Name) end end  
        if TargetType == 'qb' then exports['qb-target']:RemoveTargetEntity(jesusPed, 'jesusPed') elseif TargetType == 'ox' then exports.ox_target:removeLocalEntity(jesusPed, 'jesusPed') end        
        DeletePed(jesusPed)
        print('^5--<^3!^5>-- ^7| Lusty94 |^5 ^5--<^3!^5>--^7 Jesus V1.0.0 Stopped Successfully ^5--<^3!^5>--^7')
	end
end)