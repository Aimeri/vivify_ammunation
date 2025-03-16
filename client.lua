local QBCore = exports['qb-core']:GetCoreObject()
local spawnedPeds = {}


local function SpawnPeds()
    for i, location in ipairs(Config.PedLocation) do
        local pedModel = GetHashKey(Config.PedModel)

        RequestModel(pedModel)
        while not HasModelLoaded(pedModel) do
            Wait(100)
        end

        local ped = CreatePed(4, pedModel, location.x, location.y, location.z -1, location.w, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)

        spawnedPeds[i] = ped
    end
end

local function CreateTargetZones()
    for i, location in ipairs(Config.PedLocation) do
        exports['qb-target']:AddTargetModel(Config.PedModel, {
            options = {
                {
                    type = "server",
                    event = "vivify_gunshop:server:openShop",
                    icon = 'fas fa-coins',
                    label = 'Shop'
                },
            },
            distance = 2.5
        })
    end
end

RegisterNetEvent("vivify_gunshop:client:openShopMenu", function(menuItems)
    local shopMenu = {
        {
            header = "Gun Shop",
            isMenuHeader = true
        }
    }
    
    for _, item in ipairs(menuItems) do
        table.insert(shopMenu, item)
    end
    
    table.insert(shopMenu, {
        header = "Close",
        params = {
            event = "qb-menu:closeMenu"
        }
    })
    
    exports['qb-menu']:openMenu(shopMenu)
end)

RegisterNetEvent("vivify_gunshop:client:selectQuantity", function(data)
    local maxAmount = data.max
    if maxAmount <= 0 then
        QBCore.Functions.Notify("You have reached the purchase limit for this item.", "error")
        return
    end

    local dialog = exports['qb-input']:ShowInput({
        header = "Select Quantity",
        submitText = "Purchase",
        inputs = {
            {
                text = "Enter amount (Max: " .. maxAmount .. ")",
                name = "quantity",
                type = "number",
                isRequired = true
            }
        }
    })

    if dialog then
        local quantity = tonumber(dialog.quantity)
        if quantity and quantity > 0 and quantity <= maxAmount then
            TriggerServerEvent("vivify_gunshop:server:purchaseItem", { name = data.name, label = data.label, quantity = quantity })
        else
            QBCore.Functions.Notify("Invalid quantity.", "error")
        end
    end
end)

RegisterNetEvent("vivify_gunshop:client:purchaseItem", function(itemName)
    TriggerServerEvent("vivify_gunshop:server:purchaseItem", itemName)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, ped in ipairs(spawnedPeds) do
            if DoesEntityExist(ped) then
                DeleteEntity(ped)
            end
        end
        exports['qb-target']:RemoveTargetModel(Config.PedModel)
    end
end)

CreateThread(function()
    SpawnPeds()
    CreateTargetZones()
end)