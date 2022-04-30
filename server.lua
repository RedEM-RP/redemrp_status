Inventory = {}
TriggerEvent("redemrp_inventory:getData", function(call)
    Inventory = call
end)

data2 = {}
TriggerEvent("redemrp_inventory:getData",function(call)
    data2 = call
end)

local PlayersStatus = {}

AddEventHandler("redemrp:playerLoaded", function(source, user)
    local _source = source
    local identifier = user.getIdentifier()
    local charid = user.getSessionVar("charid")
    MySQL.Async.fetchAll('SELECT * FROM status WHERE `identifier`=@identifier AND `charid`=@charid;', {
        identifier = identifier,
        charid = charid
    }, function(status)
        if status[1] then
            PlayersStatus[identifier .. "_" .. charid] = json.decode(status[1].status)
            PlayersStatus[identifier .. "_" .. charid].source = _source
            print("redemrp_status: Status Loaded!")
        else
            print("redemrp_status: Status Created!")

            local Created = {
                hunger = 100,
                thirst = 100,
                drunk = 0,
                drugs = 0,
                source = _source
            }
            local temp = {
                hunger = 100,
                thirst = 100,
                drunk = 0,
                drugs = 0
            }
            PlayersStatus[identifier .. "_" .. charid] = Created
            MySQL.Async.execute(
                'INSERT INTO status (`identifier`, `charid`, `status`) VALUES (@identifier, @charid, @status);', {
                    identifier = identifier,
                    charid = charid,
                    status = json.encode(temp)
                }, function(rowsChanged)
                end)
        end
        TriggerClientEvent('redemrp_status:UpdateStatus', tonumber(PlayersStatus[identifier .. "_" .. charid].source),
            PlayersStatus[identifier .. "_" .. charid].thirst, PlayersStatus[identifier .. "_" .. charid].hunger)
    end)

end)

AddEventHandler("redemrp:playerDropped", function(user)
    local charid = user.getSessionVar("charid")
    local identifier = user.get('identifier')
    local temp = {}
    temp.hunger = PlayersStatus[identifier .. "_" .. charid].hunger
    temp.thirst = PlayersStatus[identifier .. "_" .. charid].thirst
    temp.drunk = PlayersStatus[identifier .. "_" .. charid].drunk
    temp.drugs = PlayersStatus[identifier .. "_" .. charid].drugs
    MySQL.Async.execute("UPDATE status SET `status`='" .. json.encode(temp) ..
        "' WHERE `identifier`=@identifier AND `charid`=@cid", {
            identifier = identifier,
            cid = charid
        }, function(done)
            PlayersStatus[identifier .. "_" .. charid] = nil
        end)

end)

function UpdatePlayersStatus()
    SetTimeout(12000, function()
        Citizen.CreateThread(function()
            for id, status in pairs(PlayersStatus) do
                if PlayersStatus[id].hunger - 0.2 >= 0.0 then
                    PlayersStatus[id].hunger = PlayersStatus[id].hunger - 0.17
                end
                if PlayersStatus[id].thirst - 0.2 >= 0.0 then
                    PlayersStatus[id].thirst = PlayersStatus[id].thirst - 0.2
                end
                TriggerClientEvent('redemrp_status:UpdateStatus', tonumber(PlayersStatus[id].source), PlayersStatus[id].thirst, PlayersStatus[id].hunger)
                Wait(10)
            end
            UpdatePlayersStatus()
        end)
    end)
end
UpdatePlayersStatus()

function UpdateDb()
    SetTimeout(300000, function()
        Citizen.CreateThread(function()
            for id, status in pairs(PlayersStatus) do
                local temp = {}
                temp.hunger = PlayersStatus[id].hunger
                temp.thirst = PlayersStatus[id].thirst
                temp.drunk = PlayersStatus[id].drunk
                temp.drugs = PlayersStatus[id].drugs
                local identifier = id:sub(1, -3)
                local charid = id:sub(#id, #id)
                MySQL.Async.execute("UPDATE status SET `status`='" .. json.encode(temp) ..
                    "' WHERE `identifier`=@identifier AND `charid`=@cid", {
                        identifier = identifier,
                        cid = charid
                    }, function(done)
                    end)
                Wait(100)
            end
            UpdateDb()
        end)
    end)
end
UpdateDb()

Citizen.CreateThread(function()
    for name, info in pairs(Config.Items) do
        RegisterServerEvent("RegisterUsableItem:" .. name)
        AddEventHandler("RegisterUsableItem:" .. name, function(source)
            TriggerEvent('redemrp:getPlayerFromId', source, function(user)
                local identifier = user.getIdentifier()
                local charid = user.getSessionVar("charid")
                PlayersStatus[identifier .. "_" .. charid].hunger = PlayersStatus[identifier .. "_" .. charid].hunger + info.hunger
                PlayersStatus[identifier .. "_" .. charid].thirst = PlayersStatus[identifier .. "_" .. charid].thirst + info.thirst
                if PlayersStatus[identifier .. "_" .. charid].hunger > 100.0 then PlayersStatus[identifier .. "_" .. charid].hunger = 100 end
                if PlayersStatus[identifier .. "_" .. charid].thirst > 100.0 then PlayersStatus[identifier .. "_" .. charid].thirst = 100 end
                local ItemData = Inventory.getItem(tonumber(PlayersStatus[identifier .. "_" .. charid].source), name)
                ItemData.RemoveItem(1)
                TriggerClientEvent('redemrp_status:UpdateStatus', tonumber(PlayersStatus[identifier .. "_" .. charid].source), PlayersStatus[identifier .. "_" .. charid].thirst, PlayersStatus[identifier .. "_" .. charid].hunger)
                info.action(tonumber(PlayersStatus[identifier .. "_" .. charid].source) , name)

            end)
        end)
    end
end)

RegisterServerEvent("redemrp_status:Restart")
AddEventHandler("redemrp_status:Restart", function()
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        PlayersStatus[identifier .. "_" .. charid].hunger = 25
        PlayersStatus[identifier .. "_" .. charid].thirst = 25
        TriggerClientEvent('redemrp_status:UpdateStatus', tonumber(PlayersStatus[identifier .. "_" .. charid].source), PlayersStatus[identifier .. "_" .. charid].thirst, PlayersStatus[identifier .. "_" .. charid].hunger)
        local temp = {}
        temp.hunger = PlayersStatus[identifier .. "_" .. charid].hunger
        temp.thirst = PlayersStatus[identifier .. "_" .. charid].thirst
        temp.drunk = PlayersStatus[identifier .. "_" .. charid].drunk
        temp.drugs = PlayersStatus[identifier .. "_" .. charid].drugs
        MySQL.Async.execute("UPDATE status SET `status`='" .. json.encode(temp) ..
            "' WHERE `identifier`=@identifier AND `charid`=@cid", {
                identifier = identifier,
                cid = charid
            }, function(done)
            end)

    end)
end)

RegisterServerEvent("redemrp_status:AddAmount")
AddEventHandler("redemrp_status:AddAmount", function(hunger , thirst)
    local _source = source
    TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
        local identifier = user.getIdentifier()
        local charid = user.getSessionVar("charid")
        PlayersStatus[identifier .. "_" .. charid].hunger = PlayersStatus[identifier .. "_" .. charid].hunger + hunger
        PlayersStatus[identifier .. "_" .. charid].thirst = PlayersStatus[identifier .. "_" .. charid].thirst + thirst
        if PlayersStatus[identifier .. "_" .. charid].hunger > 100.0 then PlayersStatus[identifier .. "_" .. charid].hunger = 100 end
        if PlayersStatus[identifier .. "_" .. charid].thirst > 100.0 then PlayersStatus[identifier .. "_" .. charid].thirst = 100 end
        TriggerClientEvent('redemrp_status:UpdateStatus', tonumber(PlayersStatus[identifier .. "_" .. charid].source), PlayersStatus[identifier .. "_" .. charid].thirst, PlayersStatus[identifier .. "_" .. charid].hunger)
    end)
end)

RegisterServerEvent("RegisterUsableItem:lemonade")
AddEventHandler("RegisterUsableItem:lemonade", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
					if data.thirst + 25 <= 100 then
                            statusUsers[number]["thirst"] = data.thirst + 25
							else
							statusUsers[number]["thirst"] = 100
					end

					local itemData = data2.getItem(tonumber(data.zrodlo), "lemonade")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:drinking', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus',data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:herbal_tea")
AddEventHandler("RegisterUsableItem:herbal_tea", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
					if data.thirst + 25 <= 100 then
                            statusUsers[number]["thirst"] = data.thirst + 25
							else
							statusUsers[number]["thirst"] = 100
					end

					local itemData = data2.getItem(tonumber(data.zrodlo), "herbal_tea")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:drinking', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus',data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:minttea")
AddEventHandler("RegisterUsableItem:minttea", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
					if data.thirst + 25 <= 100 then
                            statusUsers[number]["thirst"] = data.thirst + 25
							else
							statusUsers[number]["thirst"] = 100
					end

					local itemData = data2.getItem(tonumber(data.zrodlo), "minttea")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:drinking', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus',data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:coffee")
AddEventHandler("RegisterUsableItem:coffee", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
					if data.thirst + 30 <= 100 then
                            statusUsers[number]["thirst"] = data.thirst + 30
							else
							statusUsers[number]["thirst"] = 100
					end

					local itemData = data2.getItem(tonumber(data.zrodlo), "coffee")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:drinking', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus',data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("redemrp_status:drinkingwater")
AddEventHandler("redemrp_status:drinkingwater", function()
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
					if data.thirst + 20 <= 100 then
                            statusUsers[number]["thirst"] = data.thirst + 20
							else
							statusUsers[number]["thirst"] = 100
					end
					TriggerClientEvent('redemrp_status:drinkingfromsea', _source)
					TriggerClientEvent('redemrp_status:sendStatus',data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("redemrp_status:drinkingwater2")
AddEventHandler("redemrp_status:drinkingwater2", function()
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
					if data.thirst + 35 <= 100 then
                            statusUsers[number]["thirst"] = data.thirst + 35
							else
							statusUsers[number]["thirst"] = 100
					end
					TriggerClientEvent('redemrp_status:drinkingfromsea', _source)
					TriggerClientEvent('redemrp_status:sendStatus',data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("redemrp_status:eatberry")
AddEventHandler("redemrp_status:eatberry", function()
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 10 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 10
						else
							statusUsers[number]["hunger"] = 100
						end

					TriggerClientEvent('redemrp_status:drinkingfromsea', _source)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:bread")
AddEventHandler("RegisterUsableItem:bread", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 10 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 10
						else
							statusUsers[number]["hunger"] = 100
						end
					local itemData = data2.getItem(tonumber(data.zrodlo), "bread")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:carrot")
AddEventHandler("RegisterUsableItem:carrot", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 15 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 15
						else
							statusUsers[number]["hunger"] = 100
						end
					local itemData = data2.getItem(tonumber(data.zrodlo), "carrot")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:broccoli")
AddEventHandler("RegisterUsableItem:broccoli", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 15 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 15
						else
							statusUsers[number]["hunger"] = 100
						end
					local itemData = data2.getItem(tonumber(data.zrodlo), "broccoli")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:lettuce")
AddEventHandler("RegisterUsableItem:lettuce", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 10 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 10
						else
							statusUsers[number]["hunger"] = 100
						end
					local itemData = data2.getItem(tonumber(data.zrodlo), "lettuce")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:cooked_bread")
AddEventHandler("RegisterUsableItem:cooked_bread", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 12 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 12
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "cooked_bread")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:cooked_fish")
AddEventHandler("RegisterUsableItem:cooked_fish", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 15 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 15
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "cooked_fish")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:cooked_fish2")
AddEventHandler("RegisterUsableItem:cooked_fish2", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 25 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 25
						else
							statusUsers[number]["hunger"] = 100
						end


					local itemData = data2.getItem(tonumber(data.zrodlo), "cooked_fish2")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:cooked_fish3")
AddEventHandler("RegisterUsableItem:cooked_fish3", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
					statusUsers[number]["hunger"] = 100
					local itemData = data2.getItem(tonumber(data.zrodlo), "cooked_fish3")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)



RegisterServerEvent("RegisterUsableItem:cooked_corn")
AddEventHandler("RegisterUsableItem:cooked_corn", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 25 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 25
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "cooked_corn")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:stew")
AddEventHandler("RegisterUsableItem:stew", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 50 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 50
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "stew")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_inventory:closeinv', data.zrodlo)
					TriggerClientEvent('redemrp_status:stew', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:stew2")
AddEventHandler("RegisterUsableItem:stew2", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 60 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 60
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "stew2")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_inventory:closeinv', data.zrodlo)
					TriggerClientEvent('redemrp_status:stew', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:stew3")
AddEventHandler("RegisterUsableItem:stew3", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 40 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 40
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "stew3")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_inventory:closeinv', data.zrodlo)
					TriggerClientEvent('redemrp_status:stew', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:cooked_meat")
AddEventHandler("RegisterUsableItem:cooked_meat", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 20 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 20
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "cooked_meat")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

RegisterServerEvent("RegisterUsableItem:capocollo")
AddEventHandler("RegisterUsableItem:capocollo", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 25 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 25
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "capocollo")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)


RegisterServerEvent("RegisterUsableItem:apple")
AddEventHandler("RegisterUsableItem:apple", function(source)
 local _source = source
	TriggerEvent('redemrp:getPlayerFromId', _source, function(user)
	local _id = user.getIdentifier()
	local _cid = user.getSessionVar("charid")
	        for number, data in pairs(statusUsers) do
					if data.id == _id and data.cid == _cid and data.zrodlo == _source then
						if data.hunger + 10 <= 100 then
                            statusUsers[number]["hunger"] = data.hunger + 10
						else
							statusUsers[number]["hunger"] = 100
						end

					local itemData = data2.getItem(tonumber(data.zrodlo), "apple")
					itemData.RemoveItem(1)
					TriggerClientEvent('redemrp_status:eating', data.zrodlo)
					Wait(500)
					TriggerClientEvent('redemrp_status:sendStatus', data.zrodlo, data.thirst, data.hunger)
					end
                end
	end)
end)

-- RegisterServerEvent("RegisterUsableItem:cigarettes")
-- AddEventHandler("RegisterUsableItem:cigarettes", function(source)
 -- local _source = source
	-- local itemData = data2.getItem(_source, "cigarettes")
	-- itemData.RemoveItem(1)
	-- TriggerClientEvent('redemrp_status:StartCigarette', _source)
-- end)


RegisterServerEvent("RegisterUsableItem:bagienneziele_pro")
AddEventHandler("RegisterUsableItem:bagienneziele_pro", function(source)
 local _source = source
	local itemData = data2.getItem(_source, "bagienneziele_pro")
	itemData.RemoveItem(1)
	TriggerClientEvent('redemrp_status:Bagienne', _source)
end)

RegisterServerEvent("RegisterUsableItem:bandage")
AddEventHandler("RegisterUsableItem:bandage", function(source)
	local _source = source
	TriggerClientEvent('redemrp_status:StartBandage', _source , "bandage")
end)

RegisterServerEvent("RegisterUsableItem:herbal_cream")
AddEventHandler("RegisterUsableItem:herbal_cream", function(source)
	local _source = source
	TriggerClientEvent('redemrp_status:StartBandage', _source , "herbal_cream")
end)


-- RegisterServerEvent("RegisterUsableItem:selfcigarettes")
-- AddEventHandler("RegisterUsableItem:selfcigarettes", function(source)
 -- local _source = source
	   	-- local itemData = data2.getItem(_source, "selfcigarettes")
	-- itemData.RemoveItem(1)
	-- TriggerClientEvent('redemrp_status:StartCigarette', _source)
-- end)

-- RegisterServerEvent("RegisterUsableItem:cigar")
-- AddEventHandler("RegisterUsableItem:cigar", function(source)
 -- local _source = source
		   	-- local itemData = data2.getItem(_source, "cigar")
	-- itemData.RemoveItem(1)
	-- TriggerClientEvent('redemrp_status:StartCigar', _source)
-- end)

RegisterServerEvent("RegisterUsableItem:cigarettes")
AddEventHandler("RegisterUsableItem:cigarettes", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "cigarettes")
	itemData.RemoveItem(1)
	TriggerClientEvent('prop:cigarettes', _source)
end)

RegisterServerEvent("RegisterUsableItem:hairpomade")
AddEventHandler("RegisterUsableItem:hairpomade", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "hairpomade")
	itemData.RemoveItem(1)
	TriggerClientEvent('prop:hairpomade', _source)
end)

RegisterServerEvent("RegisterUsableItem:cigar")
AddEventHandler("RegisterUsableItem:cigar", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "cigar")
	itemData.RemoveItem(1)
	TriggerClientEvent('prop:cigar', _source)
end)

RegisterServerEvent("RegisterUsableItem:notebook")
AddEventHandler("RegisterUsableItem:notebook", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "notebook")
	--itemData.RemoveItem(1)
	TriggerClientEvent('prop:ledger', _source)
end)

RegisterServerEvent("RegisterUsableItem:pocket_watch")
AddEventHandler("RegisterUsableItem:pocket_watch", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "pocket_watch")
	--itemData.RemoveItem(1)
	TriggerClientEvent('prop:watch', _source)
end)

RegisterServerEvent("RegisterUsableItem:book")
AddEventHandler("RegisterUsableItem:book", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "book")
	--itemData.RemoveItem(1)
	TriggerClientEvent('prop:book', _source)
end)

RegisterServerEvent("RegisterUsableItem:pipe")
AddEventHandler("RegisterUsableItem:pipe", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "pipe")
	--itemData.RemoveItem(1)
	TriggerClientEvent('prop:pipe', _source)
end)

RegisterServerEvent("RegisterUsableItem:fan")
AddEventHandler("RegisterUsableItem:fan", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "fan")
	--itemData.RemoveItem(1)
	TriggerClientEvent('prop:fan', _source)
end)

RegisterServerEvent("RegisterUsableItem:chewingtobacco")
AddEventHandler("RegisterUsableItem:chewingtobacco", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "chewingtobacco")
	itemData.RemoveItem(1)
	TriggerClientEvent('prop:chewingtobacco', _source)
end)

RegisterServerEvent("RegisterUsableItem:selfcigarettes")
AddEventHandler("RegisterUsableItem:selfcigarettes", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "selfcigarettes")
			local itemData2 = data2.getItem(_source, "cigarettes")
	itemData.RemoveItem(1)
	itemData2.AddItem(15)
	--TriggerClientEvent('prop:cigarettes', _source)
end)

RegisterServerEvent("RegisterUsableItem:selfcigars")
AddEventHandler("RegisterUsableItem:selfcigars", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "selfcigars")
			local itemData2 = data2.getItem(_source, "cigar")
	itemData.RemoveItem(1)
	itemData2.AddItem(10)
	--TriggerClientEvent('prop:cigarettes', _source)
end)

RegisterServerEvent("RegisterUsableItem:wine")
AddEventHandler("RegisterUsableItem:wine", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "wine")
	itemData.RemoveItem(1)
	TriggerClientEvent('redemrp_status:StartWine', _source)
end)

RegisterServerEvent("RegisterUsableItem:beer")
AddEventHandler("RegisterUsableItem:beer", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "beer")
	itemData.RemoveItem(1)
	TriggerClientEvent('redemrp_status:StartBeer', _source)
end)

RegisterServerEvent("RegisterUsableItem:szampan")
AddEventHandler("RegisterUsableItem:szampan", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "szampan")
	itemData.RemoveItem(1)
	TriggerClientEvent('redemrp_status:StartSzampan', _source)
end)

RegisterServerEvent("RegisterUsableItem:moonshine")
AddEventHandler("RegisterUsableItem:moonshine", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "moonshine")
	itemData.RemoveItem(1)
	TriggerClientEvent('redemrp_status:StartMoonshine', _source)
end)
RegisterServerEvent("RegisterUsableItem:poor_whisky")
AddEventHandler("RegisterUsableItem:poor_whisky", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "poor_whisky")
	itemData.RemoveItem(1)
	TriggerClientEvent('redemrp_status:StartWhisky', _source)
end)
RegisterServerEvent("RegisterUsableItem:good_whisky")
AddEventHandler("RegisterUsableItem:good_whisky", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "good_whisky")
	itemData.RemoveItem(1)
	TriggerClientEvent('redemrp_status:StartWhisky', _source)
end)
----HORSE ITEMS
RegisterServerEvent("RegisterUsableItem:consumable_haycube")
AddEventHandler("RegisterUsableItem:consumable_haycube", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "consumable_haycube")
	itemData.RemoveItem(1)
	TriggerClientEvent('horse:haycube', _source)
end)
RegisterServerEvent("RegisterUsableItem:consumable_horse_stimulant")
AddEventHandler("RegisterUsableItem:consumable_horse_stimulant", function(source)
 local _source = source
		   	local itemData = data2.getItem(_source, "consumable_horse_stimulant")
	itemData.RemoveItem(1)
	TriggerClientEvent('horse:horsestimulant', _source)
end)
---------
