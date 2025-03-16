local QBCore = exports['qb-core']:GetCoreObject()

local function CheckCooldowns(citizenid, callback)
    MySQL.Async.fetchAll("SELECT item, last_purchased FROM gunshop_cooldowns WHERE citizenid = ?", { citizenid }, function(results)
        local cooldowns = {}
        for _, row in ipairs(results) do
            cooldowns[row.item] = tonumber(row.last_purchased) or 0
        end
        callback(cooldowns)
    end)
end

local function SetCooldown(citizenid, itemName)
    if itemName == 'weapon_pistol' then
        MySQL.Async.execute([[
            INSERT INTO gunshop_cooldowns (citizenid, item, last_purchased) 
            VALUES (?, ?, ?) 
            ON DUPLICATE KEY UPDATE last_purchased = VALUES(last_purchased)
        ]], { citizenid, itemName, os.time() })
    end
end

RegisterNetEvent("vivify_gunshop:server:openShop", function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local hasLicense = true
    
    CheckCooldowns(citizenid, function(cooldowns)
        local menuItems = {}
        
        for _, item in ipairs(Config.ShopItems) do
            if item.requiredLicense then
                local licenses = Player.PlayerData.metadata["licences"] or {}
                if not licenses[item.requiredLicense] then
                    hasLicense = false
                    TriggerClientEvent('QBCore:Notify', src, "You don't have the required license to buy this.", "error")
                    return
                end
            end
            
            if item.name == 'weapon_pistol' then
                local lastPurchase = cooldowns[item.name] or 0
                if os.time() < lastPurchase + 60 then
                    goto continue
                end
            end

            table.insert(menuItems, {
                header = item.label,
                txt = "Price: $" .. item.price,
                params = {
                    event = "vivify_gunshop:client:selectQuantity",
                    args = { 
                        name = item.name, 
                        label = item.label, 
                        price = item.price, 
                        type = item.type, 
                        max = item.name == "weapon_pistol" and 1 or 999
                    }
                }
            })
            
            ::continue::
        end

        if #menuItems == 0 then
            TriggerClientEvent('QBCore:Notify', src, "There are no available items for purchase at this time.", "error")
            return
        end
        
        TriggerClientEvent("vivify_gunshop:client:openShopMenu", src, menuItems)
    end)
end)

RegisterNetEvent("vivify_gunshop:server:purchaseItem", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local selectedItem = nil

    for _, item in ipairs(Config.ShopItems) do
        if item.name == data.name then
            selectedItem = item
            break
        end
    end
    
    if not selectedItem then
        TriggerClientEvent('QBCore:Notify', src, "Invalid item.", "error")
        return
    end
    
    local totalPrice = selectedItem.price * data.quantity

    if Player.Functions.RemoveMoney('cash', totalPrice) then
        Player.Functions.AddItem(selectedItem.name, data.quantity)
        TriggerClientEvent('QBCore:Notify', src, "You purchased " .. data.quantity .. " " .. selectedItem.label .. "!", "success")
        
        exports['qb-banking']:AddMoney('gundealer', totalPrice, 'Ammunation Purchase')
        
        if selectedItem.name == 'weapon_pistol' then
            SetCooldown(citizenid, selectedItem.name)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "You don't have enough money.", "error")
    end
end)