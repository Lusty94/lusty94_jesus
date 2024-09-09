local QBCore = exports['qb-core']:GetCoreObject()
local InvType = Config.CoreSettings.Inventory.Type
local NotifyType = Config.CoreSettings.Notify.Type

--notification function
local function SendNotify(src, msg, type, time, title)
    if not title then title = "Jesus" end
    if not time then time = 5000 end
    if not type then type = 'success' end
    if not msg then print("Notification Sent With No Message") return end
    if NotifyType == 'qb' then
        TriggerClientEvent('QBCore:Notify', src, msg, type, time)
    elseif NotifyType == 'okok' then
        TriggerClientEvent('okokNotify:Alert', src, title, msg, time, type, Config.CoreSettings.Notify.Sound)
    elseif NotifyType == 'mythic' then
        TriggerClientEvent('mythic_notify:client:SendAlert', src, { type = type, text = msg, style = { ['background-color'] = '#00FF00', ['color'] = '#FFFFFF' } })
    elseif NotifyType == 'boii'  then
        TriggerClientEvent('boii_ui:notify', src, title, msg, type, time)
    elseif NotifyType == 'ox' then 
        TriggerClientEvent('ox_lib:notify', src, ({ title = title, description = msg, length = time, type = type, style = 'default'}))
    end
end

--stress level callback
QBCore.Functions.CreateCallback('lusty94_jesus:get:StressLevels', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local minStress = Config.CoreSettings.Effects.MinStress
    local stressData = Player.PlayerData.metadata['stress']
    if not Player then return end
    if stressData >= minStress then
        cb(true)
    else
        cb(false)
    end
end)



--donation amount callback
QBCore.Functions.CreateCallback('lusty94_jesus:get:DonationAmount', function(source, cb, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local cash = Player.PlayerData.money.cash
    if not Player then return end
    if cash >= amount then
        cb(true)
    else
        cb(false)
    end
end)

--donate money to the church
RegisterServerEvent('lusty94_jesus:server:DonateMoney', function(amount)
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    if InvType == 'qb' then
        if Player.Functions.RemoveMoney('cash', amount) then
            SendNotify(src, Config.Language.Notifications.DonationName, 'success', 2000)
        end
    elseif InvType == 'ox' then
        if exports.ox_inventory:RemoveItem(src,"money", amount) then
            SendNotify(src, Config.Language.Notifications.DonationName, 'success', 2000)
        end
    end
end)

--give bread and wine if checkbox enabled
RegisterServerEvent('lusty94_jesus:server:GiveBreadWine', function()
	local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local items = { 'bread', 'wine', } -- change item names here
    local itemsAmount
    for _, item in pairs(items) do
        itemsAmount = 1 -- edit amount of EACH item you get from the table above
        if InvType == 'qb' then
            if exports['qb-inventory']:AddItem(src, item, itemsAmount, nil, nil, nil) then
                TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[items], "add", itemsAmount)
            end
        elseif InvType == 'ox' then
            if exports.ox_inventory:CanCarryItem(src, item, itemsAmount) then 
                exports.ox_inventory:AddItem(src, item, itemsAmount)
            else
                SendNotify(src, Config.Language.Notifications.CantCarryName, 'error', 2000)
            end
        end        
    end
end)

---------------------< DONT TOUCH >-----------

local function CheckVersion()
	PerformHttpRequest('https://raw.githubusercontent.com/Lusty94/UpdatedVersions/main/Jesus/version.txt', function(err, newestVersion, headers)
		local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
		if not newestVersion then print("Currently unable to run a version check.") return end
		local advice = "^1You are currently running an outdated version^7, ^1please update^7"
		if newestVersion:gsub("%s+", "") == currentVersion:gsub("%s+", "") then advice = '^6You are running the latest version.^7'
		else print("^3Version Check^7: ^2Current^7: "..currentVersion.." ^2Latest^7: "..newestVersion..advice) end
	end)
end
CheckVersion()