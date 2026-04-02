panel = mainTab;

local bugMap = {};

bugMap.kunaiId      = storage.kunaiConfig and storage.kunaiConfig.kunaiId or 7382
bugMap.isKeyPressed = modules.corelib.g_keyboard.isKeyPressed

storage.bugMap = storage.bugMap or {}

bugMap.directions = {
    ["W"] = {x = 0,  y = -5, direction = 0},
    ["E"] = {x = 3,  y = -3},
    ["D"] = {x = 5,  y = 0,  direction = 1},
    ["C"] = {x = 3,  y = 3},
    ["S"] = {x = 0,  y = 5,  direction = 2},
    ["Z"] = {x = -3, y = 3},
    ["A"] = {x = -5, y = 0,  direction = 3},
    ["Q"] = {x = -3, y = 3}
}

bugMap.stairsIds = {
    [1666]=true, [6207]=true, [1948]=true, [435]=true, [7771]=true,
    [5542]=true, [8657]=true, [6264]=true, [1646]=true, [1648]=true,
    [1678]=true, [5291]=true, [1680]=true, [6905]=true, [6262]=true,
    [1664]=true, [13296]=true, [1067]=true, [13861]=true, [11931]=true,
    [1949]=true, [6896]=true, [6205]=true, [13926]=true, [1947]=true,
    [12097]=true, [615]=true, [8367]=true
}

bugMap.hasStairs = function(tile)
    if not tile then return false end
    for _, item in ipairs(tile:getItems()) do
        if bugMap.stairsIds[item:getId()] then return true end
    end
    local cor = g_map.getMinimapColor(tile:getPosition())
    if cor >= 210 and cor <= 213 and not tile:isPathable() and tile:isWalkable() then
        return true
    end
    return false
end

bugMap.findKunai = function()
    local kunaiId = storage.kunaiConfig and storage.kunaiConfig.kunaiId or bugMap.kunaiId
    for _, container in pairs(g_game.getContainers()) do
        for _, item in ipairs(container:getItems()) do
            if item:getId() == kunaiId then return item end
        end
    end
end

bugMap.useKunaiToPos = function(tilePos)
    if not storage.kunaiConfig or not storage.kunaiConfig.enabled then return false end
    if not bugMap.findKunai() then return false end
    local kunaiId    = storage.kunaiConfig.kunaiId or 7382
    local kunaiRange = storage.kunaiConfig.kunaiDistance or 5
    local playerPos  = player:getPosition()
    local dx   = tilePos.x - playerPos.x
    local dy   = tilePos.y - playerPos.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return false end
    local steps = math.min(kunaiRange, math.floor(dist))
    local targetPos = {
        x = playerPos.x + math.floor(dx / dist * steps),
        y = playerPos.y + math.floor(dy / dist * steps),
        z = playerPos.z
    }
    local tile = g_map.getTile(targetPos)
    if not tile then
        -- fallback: tenta usar direto no tile destino
        local destTile = g_map.getTile(tilePos)
        if not destTile then return false end
        local thing = destTile:getTopUseThing()
        if not thing then return false end
        useWith(kunaiId, thing)
        return true
    end
    local topThing = tile:getTopUseThing()
    if not topThing then return false end
    useWith(kunaiId, topThing)
    return true
end

bugMap.macro = macro(1, "Bug Map", function()
    if modules.game_console:isChatEnabled() or modules.corelib.g_keyboard.isCtrlPressed() then return end
    local pos = pos()
    for key, config in pairs(bugMap.directions) do
        if bugMap.isKeyPressed(key) then
            if config.direction then
                turn(config.direction)
            end
            local tilePos = {x = pos.x + config.x, y = pos.y + config.y, z = pos.z}
            local tile = g_map.getTile(tilePos)
            if tile then
                local topThing = tile:getTopUseThing()
                if not bugMap.hasStairs(tile) then
                    bugMap.useKunaiToPos(tilePos)
                end
                return g_game.use(topThing)
            end
        end
    end
end)