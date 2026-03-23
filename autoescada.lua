panel = mainTab;

Stairs.nextPosition = {
    {x = 0,  y = -1},
    {x = 1,  y = 0},
    {x = 0,  y = 1},
    {x = -1, y = 0},
    {x = 1,  y = -1},
    {x = 1,  y = 1},
    {x = -1, y = 1},
    {x = -1, y = -1}
}

Stairs.reverseDirection = {2, 3, 0, 1, 6, 7, 4, 5}

Stairs.getDistance = function(p1, p2)
    local dx = math.abs(p1.x - p2.x)
    local dy = math.abs(p1.y - p2.y)
    return math.sqrt(dx * dx + dy * dy)
end

Stairs.getPosition = function(pos, dir)
    local next = Stairs.nextPosition[dir + 1]
    pos.x = pos.x + next.x
    pos.y = pos.y + next.y
    return pos
end

Stairs.doReverse = function(dir)
    return Stairs.reverseDirection[dir + 1]
end

Stairs.checkTile = function(tile)
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

Stairs.markOnThing = function(thing, color)
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

Stairs.verifyTiles = function(pos)
    pos = pos or player:getPosition()
    local nearest

    for _, tile in ipairs(g_map.getTiles(pos.z)) do
        local tilePos = tile:getPosition()
        if tilePos then
            local distance = Stairs.getDistance(pos, tilePos)
            if not nearest or nearest.distance > distance then
                if Stairs.checkTile(tile) then
                    if getDistanceBetween(tilePos, pos) == 1 or findPath(tilePos, pos) then
                        nearest = {tile = tile, tilePos = tilePos, distance = distance}
                        Stairs.markOnThing(Stairs.actualTile)
                        Stairs.actualTile = tile
                        Stairs.actualPos  = tilePos
                    end
                end
            end
        end
    end
    Stairs.hasVerified = true
end

Stairs.goUse = function(pos)
    local playerPos = player:getPosition()
    local path = findPath(pos, playerPos, 100)
    if not path then return end

    local kunaiThing
    for i = 1, math.min(5, #path) do
        local direction = path[#path - (i - 1)]
        local nextDir   = Stairs.doReverse(direction)
        playerPos       = Stairs.getPosition(playerPos, nextDir)
        local tmpTile   = g_map.getTile(playerPos)
        if tmpTile and tmpTile:isWalkable(true) and tmpTile:isPathable() and tmpTile:canShoot() then
            kunaiThing = tmpTile:getTopThing()
        end
    end

    local tile     = g_map.getTile(playerPos)
    local topThing = tile and tile:getTopUseThing()
    if topThing then
        local distance = getDistanceBetween(playerPos, player:getPosition())
        if distance > 1 and storage.useKunai and storage.kunaiId and kunaiThing then
            useWith(storage.kunaiId, kunaiThing)
        end
        use(topThing)
    end
end

Stairs.doWalk = function()
    if not Stairs.tryToStep and autoWalk(Stairs.actualPos, 1) then
        Stairs.tryToStep = true
    end
    Stairs.goUse(Stairs.actualPos)
    Stairs.isTrying = true
end

Stairs.clear = function()
    if Stairs.isTrying then
        Stairs.isTrying = nil
        player:lockWalk(100)
        for i = 1, 10 do
            g_game.stop()
        end
    end
    Stairs.markOnThing(Stairs.actualTile)
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
            Stairs.markOnThing(Stairs.actualTile, "#00FF00")
            Stairs.doWalk()
        elseif not Stairs.hasVerified then
            Stairs.verifyTiles(pos())
        else
            modules.game_textmessage.displayFailureMessage("Sem escadas por perto.")
        end
    else
        Stairs.clear()
    end
end)
