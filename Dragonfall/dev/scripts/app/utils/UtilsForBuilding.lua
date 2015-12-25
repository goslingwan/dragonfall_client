UtilsForBuilding = {}

function UtilsForBuilding:GetHousesBy(userData, name, level)
    level = level or 0
    local t = {}
    for _,building in pairs(userData.buildings) do
        for _,house in pairs(building.houses) do
            if house.level > 0 and (not name or house.type == name) then
                table.insert(t, house)
            end
        end
    end
    return t
end

function UtilsForBuilding:GetBuildingsBy(userData, name, level)
    level = level or 0
    local t = {}
    for _,building in pairs(userData.buildings) do
        if building.level >= level and building.type == name then
            table.insert(t, building)
        end
    end
    return t
end


function UtilsForBuilding:GetBuildingBy(userData, nameOrLocation)
    if type(nameOrLocation) == "string" then
        for k,v in pairs(userData.buildings) do
            if v.type == nameOrLocation then
                return v
            end
        end
    else
        for k,v in pairs(userData.buildings) do
            if v.location == nameOrLocation then
                return v
            end
        end
    end
end


function UtilsForBuilding:GetEfficiencyBy(userData, name, offset)
    return self:GetPropertyBy(userData, name, "efficiency", offset)
end
function UtilsForBuilding:GetPropertyBy(userData, name, property, offset)
    offset = offset or 0
    local configs = self:GetBuildingConfig(name)
    for _,building in ipairs(self:GetBuildingsBy(userData, name)) do
        return configs[building.level + offset][property]
    end
end

local BuildingFunction = GameDatas.BuildingFunction
function UtilsForBuilding:GetBuildingConfig(buildingName)
    return BuildingFunction[buildingName]
end

local HouseLevelUp = GameDatas.HouseLevelUp
function UtilsForBuilding:GetCitizenMap(userData)
    local house_citizen = {
        miner = 0,
        farmer = 0,
        quarrier = 0,
        woodcutter = 0,
    }
    for _,building in pairs(userData.buildings) do
        for _,house in pairs(building.houses) do
            local value = house_citizen[house.type]
            if value then
                local citizen = house.level == 0 and 0 or HouseLevelUp[house.type][house.level].citizen
                house_citizen[house.type] = value + citizen
            end
        end
    end
    for _,event in pairs(userData.houseEvents) do
        local location_key = string.format("location_%d", event.buildingLocation)
        for _,house in pairs(userData.buildings[location_key].houses) do
            if house.location == event.houseLocation then
                local value = house_citizen[house.type]
                if value then
                    local config = HouseLevelUp[house.type]
                    local citizen = house.level == 0 and 0 or config[house.level].citizen
                    house_citizen[house.type] = value + config[house.level + 1].citizen - citizen
                end
                break
            end
        end
    end
    house_citizen.food = house_citizen.farmer
    house_citizen.wood = house_citizen.woodcutter
    house_citizen.iron = house_citizen.miner
    house_citizen.stone= house_citizen.quarrier

    house_citizen.total= house_citizen.miner
        + house_citizen.farmer
        + house_citizen.quarrier
        + house_citizen.woodcutter
    return house_citizen
end




local warehouse = GameDatas.BuildingFunction.warehouse
function UtilsForBuilding:GetWarehouseLimit(userData, offset)
    offset = offset or 0
    local limit = {
        maxWood = 0,
        maxFood = 0,
        maxIron = 0,
        maxStone= 0,
    }
    for _,building in ipairs(self:GetBuildingsBy(userData, "warehouse", 1)) do
        local config = warehouse[building.level + offset]
        for k,v in pairs(limit) do
            limit[k] = v + config[k]
        end
    end
    return limit
end

local materialDepot = GameDatas.BuildingFunction.materialDepot
function UtilsForBuilding:GetMaterialDepotLimit(userData, offset)
    offset = offset or 0
    local limit = {
        dragonMaterials     = 0,
        soldierMaterials    = 0,
        buildingMaterials   = 0,
        technologyMaterials = 0,
    }
    for _,building in ipairs(self:GetBuildingsBy(userData, "materialDepot", 1)) do
        local config = materialDepot[building.level + offset]
        for k,v in pairs(limit) do
            limit[k] = v + config[k]
        end
    end
    return limit
end


local production_map = {
    dwelling   = "coin",
    farmer     = "food",
    woodcutter = "wood",
    miner      = "iron",
    quarrier   = "stone",
}
local resource_buff_building = {
    mill       = "farmer",
    foundry    = "miner",
    lumbermill = "woodcutter",
    stoneMason = "quarrier",
    townHall   = "dwelling",
}
function UtilsForBuilding:GetBuildingsBuff(userData)
    local buff = {
        food = 0,
        wood = 0,
        iron = 0,
        stone= 0,
        coin = 0,
        wallHp = 0,
        citizen= 0,
    }
    local buildings = userData.buildings
    for location,building in pairs(buildings) do
        local house_type = resource_buff_building[building.type]
        if house_type and building.level > 0 then
            local _,index = unpack(string.split(location, "_"))
            index = tonumber(index)
            local neighbour_location = index == 15
                and string.format("location_%d", index - 1)
                or string.format("location_%d", index + 1)
            local count = 0
            for _,v in pairs(building.houses) do
                if v.type == house_type then
                    count = count + 1
                end
            end
            local houses = buildings[neighbour_location].houses
            for _,v in pairs(houses) do
                if v.type == house_type then
                    count = count + 1
                end
            end
            local res_type = production_map[house_type]
            buff[res_type] = buff[res_type] + (count >= 3 and 0.05 or 0)
            buff[res_type] = buff[res_type] + (count >= 6 and 0.05 or 0)
        end
    end
    return setmetatable(buff, BUFF_META)
end
local HouseFunction = GameDatas.HouseFunction
function UtilsForBuilding:GetHouseProductions(userData)
    local production = {
        wood  = 0,
        food  = 0,
        iron  = 0,
        stone = 0,
        coin  = 0,
    }
    for _,building in pairs(userData.buildings) do
        for _,house in pairs(building.houses) do
            if house.level > 0 then
                local res_type = production_map[house.type]
                production[res_type] = production[res_type] + HouseFunction[house.type][house.level].production
            end
        end
    end
    return setmetatable(production, BUFF_META)
end

local dwelling = GameDatas.HouseFunction.dwelling
local initCitizen_value = GameDatas.PlayerInitData.intInit.initCitizen.value
function UtilsForBuilding:GetCitizenLimit(userData)
    local limit = 0
    for _,house in ipairs(self:GetHousesBy(userData, "dwelling", 1)) do
        limit = limit + dwelling[house.level].citizen
    end
    return limit + initCitizen_value
end



local tradeGuild = GameDatas.BuildingFunction.tradeGuild
function UtilsForBuilding:GetTradeGuildInfo(userData)
    local info = {
        maxCart      = 0,
        maxSellQueue = 0,
        cartRecovery = 0,
    }
    local building = self:GetBuildingBy(userData, "tradeGuild")
    if building.level > 0 then
        local tech = userData.productionTechs["logistics"]
        local effect = UtilsForTech:GetEffect("logistics", tech)
        info.maxCart = math.ceil(tradeGuild[building.level].maxCart * (1 + effect))
        info.maxSellQueue = tradeGuild[building.level].maxSellQueue
        info.cartRecovery = tradeGuild[building.level].cartRecovery
    end
    return info
end
local wall = GameDatas.BuildingFunction.wall
function UtilsForBuilding:GetWallInfo(userData)
    local info = {
        wallHp = 0,
        wallRecovery = 0,
    }
    local building = self:GetBuildingBy(userData, "wall")
    if building.level > 0 then
        local config = wall[building.level]
        info.wallHp = config.wallHp
        info.wallRecovery = config.wallRecovery
    end
    return info
end


--获取伤病最大上限
local hospital = GameDatas.BuildingFunction.hospital
function UtilsForBuilding:GetMaxCasualty(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    local value = 0
    local tech = userData.productionTechs["rescueTent"]
    local tech_effect = UtilsForTech:GetEffect("rescueTent", tech)
    for _,building in ipairs(self:GetBuildingsBy(userData, "hospital", 1)) do
        return math.floor(hospital[building.level + offset].maxCitizen * (1 + tech_effect))
    end
    return value
end


-- 
local keep = GameDatas.BuildingFunction.keep
function UtilsForBuilding:GetFreeUnlockPoint(userData)
    local unlocked_count = 0
    for _,building in pairs(userData.buildings) do
        if building.level > 0 
        and building.type ~= "wall"
        and building.type ~= "tower" then
            unlocked_count = unlocked_count + 1
        end
    end
    for _,event in pairs(userData.buildingEvents) do
        local building = self:GetBuildingBy(userData, event.location)
        if building.level == 0 
        and building.type ~= "wall"
        and building.type ~= "tower" then
            unlocked_count = unlocked_count + 1
        end
    end
    return self:GetUnlockPoint(userData) - unlocked_count
end
function UtilsForBuilding:GetUnlockPoint(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    for _,building in ipairs(self:GetBuildingsBy(userData, "keep", 1)) do
        return keep[building.level + offset].unlock
    end
    assert(false)
end
function UtilsForBuilding:GetBeHelpedCount(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    for _,building in ipairs(self:GetBuildingsBy(userData, "keep", 1)) do
        return keep[building.level + offset].beHelpedCount
    end
    assert(false)
end



local barracks = GameDatas.BuildingFunction.barracks
function UtilsForBuilding:GetMaxRecruitSoldier(userData, offset)
    offset = offset or 0
    assert(offset >= 0)
    local max = 0
    for _,building in ipairs(self:GetBuildingsBy(userData, "barracks", 1)) do
        max = max + barracks[building.level + offset].maxRecruit
    end
    return max
end



local needs = {"Wood", "Stone", "Iron", "time"}
local toolShop = GameDatas.BuildingFunction.toolShop
function UtilsForBuilding:GetToolShopNeedByCategory(userData, category)
    for _,building in ipairs(self:GetBuildingsBy(userData, "toolShop", 1)) do
        local need = {}
        local config = toolShop[building.level]
        local key = category == "buildingMaterials" and "Bm" or "Am"
        for _, v in ipairs(needs) do
            table.insert(need, config[string.format("product%s%s", key, v)])
        end
        return config["production"], unpack(need)
    end
    assert(false)
end


