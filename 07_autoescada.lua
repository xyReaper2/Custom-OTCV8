panel = mainTab

Stairs = Stairs or {}
Stairs.isKeyPressed = Stairs.isKeyPressed or modules.corelib.g_keyboard.isKeyPressed
Stairs.isMobile     = Stairs.isMobile or modules._G.g_app.isMobile()
Stairs.excludeMap   = Stairs.excludeMap or {}
Stairs.stairsMap    = Stairs.stairsMap  or {}

local nextPosition = {
    {x = 0,  y = -1},
    {x = 1,  y = 0},
    {x = 0,  y = 1},
    {x = -1, y = 0},
    {x = 1,  y = -1},
    {x = 1,  y = 1},
    {x = -1, y = 1},
    {x = -1, y = -1}
}

local reverseDirection = {2, 3, 0, 1, 6, 7, 4, 5}

local function getDistance(p1, p2)
    local dx = math.abs(p1.x - p2.x)
    local dy = math.abs(p1.y - p2.y)
    return math.sqrt(dx * dx + dy * dy)
end

local function getPosition(pos, dir)
    local next = nextPosition[dir + 1]
    pos.x = pos.x + next.x
    pos.y = pos.y + next.y
    return pos
end

local function doReverse(dir)
    return reverseDirection[dir + 1]
end

local function checkTile(tile)
    if not tile then return end
    local tilePos = tile:getPosition()
    if not tilePos then return end

    local items = tile:getItems()

    for _, item in ipairs(items) do
        if Stairs.excludeMap[item:getId()] then return end
    end

    for _, item in ipairs(items) do
        if Stairs.stairsMap[item:getId()] then return true end
    end

    local cor = g_map.getMinimapColor(tilePos)
    if cor >= 210 and cor <= 213 and not tile:isPathable() and tile:isWalkable() then
        return true
    end
end

local function markOnThing(thing, color)
    if not thing then return end
    local items = thing:getItems()
    local useThing = items[#items]
    if not useThing then
        if color == "#00FF00" then
            thing:setText("AQUI", "green")
        elseif color == "#FF0000" then
            thing:setText("AQUI", "red")
        else
            thing:setText("")
        end
    else
        useThing:setMarked(color)
    end
end

local function verifyTiles(pos)
    pos = pos or player:getPosition()
    local nearest

    for _, tile in ipairs(g_map.getTiles(pos.z)) do
        local tilePos = tile:getPosition()
        if tilePos then
            local distance = getDistance(pos, tilePos)
            if not nearest or nearest.distance > distance then
                if checkTile(tile) then
                    if getDistanceBetween(tilePos, pos) == 1 or findPath(tilePos, pos) then
                        nearest = {tile = tile, tilePos = tilePos, distance = distance}
                        markOnThing(Stairs.actualTile)
                        Stairs.actualTile = tile
                        Stairs.actualPos  = tilePos
                    end
                end
            end
        end
    end
    Stairs.hasVerified = true
end

local function findKunai()
    local kunaiId = storage.kunaiConfig and storage.kunaiConfig.kunaiId or 7382
    for _, container in pairs(g_game.getContainers()) do
        for _, item in ipairs(container:getItems()) do
            if item:getId() == kunaiId then return item end
        end
    end
end

local function useKunaiToPos(tilePos)
    if not storage.kunaiConfig or not storage.kunaiConfig.enabled then return false end
    if not findKunai() then return false end
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
    if not tile then return false end
    local topThing = tile:getTopUseThing()
    if not topThing then return false end
    useWith(kunaiId, topThing)
    return true
end

local function goUse(pos)
    local playerPos = player:getPosition()
    local path = findPath(pos, playerPos, 100)
    if not path then return end

    local nextPos = playerPos
    for i = 1, math.min(5, #path) do
        local direction = path[#path - (i - 1)]
        local nextDir   = doReverse(direction)
        nextPos         = getPosition(nextPos, nextDir)
    end

    local distance = getDistanceBetween(nextPos, player:getPosition())
    if distance > 1 then
        useKunaiToPos(nextPos)
    end

    local tile     = g_map.getTile(nextPos)
    local topThing = tile and tile:getTopUseThing()
    if topThing then use(topThing) end
end

local function doWalk()
    if not Stairs.tryToStep and autoWalk(Stairs.actualPos, 1) then
        Stairs.tryToStep = true
    end
    goUse(Stairs.actualPos)
    Stairs.isTrying = true
end

local function clear()
    if Stairs.isTrying then
        Stairs.isTrying = nil
        player:lockWalk(100)
        for i = 1, 10 do
            g_game.stop()
        end
    end
    markOnThing(Stairs.actualTile)
    Stairs.hasVerified = nil
    Stairs.actualTile  = nil
    Stairs.actualPos   = nil
    Stairs.tryToStep   = nil
    Stairs.tryWalk     = nil
end

g_game.disableFeature(37)

onPlayerPositionChange(function(newPos, oldPos)
    Stairs.tryWalk   = nil
    Stairs.tryToStep = nil
    schedule(50, function()
        Stairs.hasVerified = nil
    end)
end)

Stairs.macro = macro(1, "Auto Escadas", function()
    if Stairs.actualPos then
        Stairs.actualTile = g_map.getTile(Stairs.actualPos)
    end

    local key = not Stairs.isMobile and "Space" or "F1"

    if Stairs.isKeyPressed(key) then
        if Stairs.actualTile and Stairs.actualPos.z == pos().z then
            markOnThing(Stairs.actualTile, "#00FF00")
            doWalk()
        elseif not Stairs.hasVerified then
            verifyTiles(pos())
            if Stairs.actualTile then
                markOnThing(Stairs.actualTile, "#FF0000")
            end
        else
            if Stairs.actualTile then
                markOnThing(Stairs.actualTile, "#FF0000")
            end
        end
    else
        clear()
    end
end)