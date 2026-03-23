FollowAttack = {
    currentTargetId  = nil,
    obstaclesQueue   = {},
    obstacleWalkTime = 0,
    keyToClearTarget = "Escape",

    walkDirTable = {
        [0] = {"y", -1},
        [1] = {"x",  1},
        [2] = {"y",  1},
        [3] = {"x", -1},
    },

    flags = {
        ignoreNonPathable = true,
        precision         = 0,
        ignoreCreatures   = true
    },

    jumpSpell = {
        up   = "jump up",
        down = "jump down"
    },

    defaultItem  = 1111,
    defaultSpell = "skip",
    kunaiRange   = 5,

    customIds = {
        {id = 1948, castSpell = false},
        {id = 595,  castSpell = false},
        {id = 1067, castSpell = false},
        {id = 1080, castSpell = false},
        {id = 5291, castSpell = false},
        {id = 386,  castSpell = true},
    }
}

storage.followAttack     = storage.followAttack or {}
FollowAttack.kunaiId     = storage.followAttack.kunaiId or 7382

FollowAttack.distanceFromPlayer = function(position)
    local dx = math.abs(posx() - position.x)
    local dy = math.abs(posy() - position.y)
    return math.sqrt(dx * dx + dy * dy)
end

FollowAttack.walkToPathDir = function(path)
    if path then g_game.walk(path[1], false) end
end

FollowAttack.getDirection = function(playerPos, direction)
    local walkDir = FollowAttack.walkDirTable[direction]
    if walkDir then
        playerPos[walkDir[1]] = playerPos[walkDir[1]] + walkDir[2]
    end
    return playerPos
end

FollowAttack.checkItemOnTile = function(tile, tbl)
    if not tile then return nil end
    for _, item in ipairs(tile:getItems()) do
        local itemId = item:getId()
        for _, itemSelected in ipairs(tbl) do
            if itemId == itemSelected.id then
                return itemSelected
            end
        end
    end
    return nil
end

FollowAttack.useTile = function(tile)
    if not tile then return false end
    local customId = FollowAttack.checkItemOnTile(tile, FollowAttack.customIds)
    if customId then
        for _, item in ipairs(tile:getItems()) do
            if item:getId() == customId.id then
                use(item)
                return true
            end
        end
    end
    use(tile:getTopUseThing())
    return true
end

FollowAttack.findKunai = function()
    for _, container in pairs(g_game.getContainers()) do
        for _, item in ipairs(container:getItems()) do
            if item:getId() == FollowAttack.kunaiId then return item end
        end
    end
end

FollowAttack.findDefaultItem = function()
    for _, container in pairs(g_game.getContainers()) do
        for _, item in ipairs(container:getItems()) do
            if item:getId() == FollowAttack.defaultItem then return item end
        end
    end
end

FollowAttack.useKunaiToward = function(targetPos)
    if not storage.followAttack.useKunai then return false end
    if not FollowAttack.findKunai() then return false end
    local playerPos = player:getPosition()
    local dx   = targetPos.x - playerPos.x
    local dy   = targetPos.y - playerPos.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return false end
    local steps = math.min(FollowAttack.kunaiRange, math.floor(dist))
    local targetTilePos = {
        x = playerPos.x + math.floor(dx / dist * steps),
        y = playerPos.y + math.floor(dy / dist * steps),
        z = playerPos.z
    }
    local tile = g_map.getTile(targetTilePos)
    if not tile then return false end
    local topThing = tile:getTopUseThing()
    if not topThing then return false end
    useWith(FollowAttack.kunaiId, topThing)
    return true
end

FollowAttack.findNearestStair = function(playerPos)
    local nearest     = nil
    local nearestDist = math.huge
    for _, tile in ipairs(g_map.getTiles(playerPos.z)) do
        local tilePos = tile:getPosition()
        if tilePos then
            local customId = FollowAttack.checkItemOnTile(tile, FollowAttack.customIds)
            if customId then
                local dist = FollowAttack.distanceFromPlayer(tilePos)
                if dist < nearestDist and dist <= 15 then
                    nearestDist = dist
                    nearest     = tile
                end
            end
        end
    end
    return nearest
end

FollowAttack.approachAndUse = function(playerPos, tile)
    if not tile then return end
    local tilePos = tile:getPosition()
    local dist    = FollowAttack.distanceFromPlayer(tilePos)

    if dist <= 1 then
        FollowAttack.useTile(tile)
        return
    end

    local path = findPath(playerPos, tilePos, 50, {ignoreNonPathable = true, precision = 1, ignoreCreatures = false})
    if path and #path > 0 then
        local tileToUse = playerPos
        for i, value in ipairs(path) do
            if i > 5 then break end
            tileToUse = FollowAttack.getDirection(tileToUse, value)
        end
        FollowAttack.useTile(g_map.getTile(tileToUse))
        return
    end

    -- path falhou: anda diretamente em direção ao tile
    local dx = tilePos.x - playerPos.x
    local dy = tilePos.y - playerPos.y
    local dir
    if math.abs(dx) >= math.abs(dy) then
        dir = dx > 0 and 1 or 3
    else
        dir = dy > 0 and 2 or 0
    end
    g_game.walk(dir, false)
end

FollowAttack.hasObstacleAt = function(tilePos, obstacleType)
    for _, obs in ipairs(FollowAttack.obstaclesQueue) do
        local obsPos = obs.tilePos or obs.oldPos
        if obsPos and obsPos.x == tilePos.x and obsPos.y == tilePos.y and obsPos.z == tilePos.z then
            if not obstacleType or obs[obstacleType] then return true end
        end
    end
    return false
end

FollowAttack.checkIfWentToCustomId = function(creature, newPos, oldPos, scheduleTime)
    local tile     = g_map.getTile(oldPos)
    local customId = FollowAttack.checkItemOnTile(tile, FollowAttack.customIds)
    if not customId then return end
    if FollowAttack.hasObstacleAt(oldPos, "isCustom") then return end
    scheduleTime = scheduleTime or 0
    schedule(scheduleTime, function()
        if oldPos.z == posz() or #FollowAttack.obstaclesQueue > 0 then
            if not FollowAttack.hasObstacleAt(oldPos, "isCustom") then
                table.insert(FollowAttack.obstaclesQueue, {
                    oldPos = oldPos, newPos = newPos, tilePos = oldPos,
                    customId = customId, tile = g_map.getTile(oldPos), isCustom = true
                })
            end
        end
    end)
end

FollowAttack.checkIfWentToDoor = function(creature, newPos, oldPos)
    if FollowAttack.obstaclesQueue[1] and FollowAttack.distanceFromPlayer(newPos) < FollowAttack.distanceFromPlayer(oldPos) then return end
    if not (math.abs(newPos.x - oldPos.x) == 2 or math.abs(newPos.y - oldPos.y) == 2) then return end

    local doorPos    = {z = oldPos.z}
    local directionX = oldPos.x - newPos.x
    local directionY = oldPos.y - newPos.y

    if math.abs(directionX) > math.abs(directionY) then
        doorPos.x = directionX > 0 and newPos.x + 1 or newPos.x - 1
        doorPos.y = newPos.y
    else
        doorPos.x = newPos.x
        doorPos.y = directionY > 0 and newPos.y + 1 or newPos.y - 1
    end

    local doorTile = g_map.getTile(doorPos)
    if not doorTile or doorTile:isPathable() or doorTile:isWalkable() then return end
    if FollowAttack.hasObstacleAt(doorPos, "isDoor") then return end

    table.insert(FollowAttack.obstaclesQueue, {
        newPos = newPos, tilePos = doorPos, tile = doorTile, isDoor = true
    })
end

FollowAttack.checkifWentToJumpPos = function(creature, newPos, oldPos)
    local hasStair = false
    for x = oldPos.x - 1, oldPos.x + 1 do
        for y = oldPos.y - 1, oldPos.y + 1 do
            if g_map.getMinimapColor({x = x, y = y, z = oldPos.z}) == 210 then
                hasStair = true
                break
            end
        end
        if hasStair then break end
    end
    if hasStair then return end
    if FollowAttack.hasObstacleAt(oldPos, "isJump") then return end

    table.insert(FollowAttack.obstaclesQueue, {
        oldPos  = oldPos,
        oldTile = g_map.getTile(oldPos),
        spell   = newPos.z > oldPos.z and FollowAttack.jumpSpell.down or FollowAttack.jumpSpell.up,
        dir     = creature:getDirection(),
        isJump  = true,
    })
end

onCreaturePositionChange(function(creature, newPos, oldPos)
    if FollowAttack.mainMacro.isOff() then return end
    if creature:getId() ~= FollowAttack.currentTargetId then return end
    if not newPos or not oldPos then return end

    if oldPos.z == newPos.z then
        FollowAttack.checkIfWentToDoor(creature, newPos, oldPos)
    end

    if oldPos.z == posz() and oldPos.z ~= newPos.z then
        FollowAttack.checkifWentToJumpPos(creature, newPos, oldPos)
    end

    if oldPos.z == posz() and (not newPos or oldPos.z ~= newPos.z) then
        FollowAttack.checkIfWentToCustomId(creature, newPos, oldPos)
    end
end)

macro(1, function()
    if FollowAttack.mainMacro.isOff() then return end
    local obs = FollowAttack.obstaclesQueue[1]
    if not obs then return end
    if (not obs.isJump and obs.tilePos and obs.tilePos.z ~= posz()) or
       (obs.isJump and obs.oldPos.z ~= posz()) then
        table.remove(FollowAttack.obstaclesQueue, 1)
    end
end)

macro(1, function()
    if FollowAttack.mainMacro.isOff() then return end
    local obs = FollowAttack.obstaclesQueue[1]
    if not obs or not obs.isDoor then return end

    local playerPos      = pos()
    local walkingTile    = obs.tile
    local walkingTilePos = obs.tilePos

    if table.compare(playerPos, obs.newPos) then
        FollowAttack.obstacleWalkTime = 0
        table.remove(FollowAttack.obstaclesQueue, 1)
        local target = g_game.getAttackingCreature()
        if target then
            local otherPath = findPath(playerPos, target:getPosition(), 50, {ignoreNonPathable = true, precision = 0, ignoreCreatures = false})
            if otherPath and #otherPath > 0 then g_game.walk(otherPath[1], false) end
        end
        return
    end

    local path = findPath(playerPos, walkingTilePos, 50, {ignoreNonPathable = true, precision = 0, ignoreCreatures = false})
    if not path or #path <= 1 then
        if not path and FollowAttack.obstacleWalkTime < now then
            g_game.use(walkingTile:getTopThing())
            FollowAttack.obstacleWalkTime = now + 500
        end
    end
end)

macro(100, function()
    if FollowAttack.mainMacro.isOff() then return end
    local obs = FollowAttack.obstaclesQueue[1]
    if not obs or not obs.isJump then return end

    local playerPos      = pos()
    local walkingTilePos = obs.oldPos
    local distance       = FollowAttack.distanceFromPlayer(walkingTilePos)

    if playerPos.z ~= walkingTilePos.z then
        table.remove(FollowAttack.obstaclesQueue, 1)
        return
    end

    if distance == 0 then
        g_game.turn(obs.dir)
        schedule(50, function()
            if FollowAttack.obstaclesQueue[1] then say(FollowAttack.obstaclesQueue[1].spell) end
        end)
        return
    elseif distance < 2 then
        if FollowAttack.obstacleWalkTime < now then
            FollowAttack.walkToPathDir(findPath(playerPos, walkingTilePos, 1, {ignoreCreatures = false, precision = 0, ignoreNonPathable = true}))
            FollowAttack.obstacleWalkTime = now + 500
        end
        return
    end

    local path = findPath(playerPos, walkingTilePos, 50, {ignoreNonPathable = true, precision = 0, ignoreCreatures = false})
    if distance >= 2 and distance < 5 and path then
        FollowAttack.useTile(obs.oldTile)
    elseif path then
        local tileToUse = playerPos
        for i, value in ipairs(path) do
            if i > 5 then break end
            tileToUse = FollowAttack.getDirection(tileToUse, value)
        end
        FollowAttack.useTile(g_map.getTile(tileToUse))
    end
end)

macro(100, function()
    if FollowAttack.mainMacro.isOff() then return end
    local obs = FollowAttack.obstaclesQueue[1]
    if not obs or not obs.isCustom then return end

    local playerPos      = pos()
    local walkingTile    = obs.tile
    local walkingTilePos = obs.tilePos
    local distance       = FollowAttack.distanceFromPlayer(walkingTilePos)

    if playerPos.z ~= walkingTilePos.z then
        table.remove(FollowAttack.obstaclesQueue, 1)
        return
    end

    if distance == 0 then
        if obs.customId.castSpell then say(FollowAttack.defaultSpell) end
        return
    elseif distance < 2 then
        local item = FollowAttack.findDefaultItem()
        if obs.customId.castSpell or not item then
            if FollowAttack.obstacleWalkTime < now then
                FollowAttack.walkToPathDir(findPath(playerPos, walkingTilePos, 1, {ignoreCreatures = false, precision = 0, ignoreNonPathable = true}))
                FollowAttack.obstacleWalkTime = now + 500
            end
        elseif item then
            g_game.useWith(item, walkingTile)
            table.remove(FollowAttack.obstaclesQueue, 1)
        end
        return
    end

    local path = findPath(playerPos, walkingTilePos, 50, {ignoreNonPathable = true, precision = 0, ignoreCreatures = false})
    if not path or #path <= 1 then
        if not path then FollowAttack.useTile(walkingTile) end
        return
    end

    local tileToUse = playerPos
    for i, value in ipairs(path) do
        if i > 5 then break end
        tileToUse = FollowAttack.getDirection(tileToUse, value)
    end
    FollowAttack.useTile(g_map.getTile(tileToUse))
end)

FollowAttack.mainMacro = macro(50, "Follow Attack", function()
    if not g_game.isAttacking() and not FollowAttack.targetChangedFloor then return end

    if FollowAttack.targetChangedFloor then
        local playerPos = pos()
        FollowAttack.targetChangedFloor = false
        local stairTile = FollowAttack.findNearestStair(playerPos)
        if stairTile then
            FollowAttack.approachAndUse(playerPos, stairTile)
        else
        end
        return
    end

    local target = g_game.getAttackingCreature()
    if not target then return end

    local targetId = target:getId()
    if targetId ~= FollowAttack.currentTargetId then
        FollowAttack.currentTargetId = targetId
        FollowAttack.obstaclesQueue  = {}
    end

    local playerPos      = pos()
    local targetPosition = target:getPosition()
    local distance       = getDistanceBetween(playerPos, targetPosition)
    if distance <= 1 then return end

    if targetPosition.z ~= playerPos.z then
        local stairTile = FollowAttack.findNearestStair(playerPos)
        if stairTile then
            FollowAttack.approachAndUse(playerPos, stairTile)
        end
        return
    end

    local path = findPath(playerPos, targetPosition, 30, FollowAttack.flags)
    if not path then
        info("path nil, tentando kunai/escada")
        if not FollowAttack.useKunaiToward(targetPosition) then
            local stairTile = FollowAttack.findNearestStair(playerPos)
            info("stairTile: " .. tostring(stairTile))
            if stairTile then
                FollowAttack.approachAndUse(playerPos, stairTile)
            end
        end
        return
    end

    local realPath = findPath(playerPos, targetPosition, 30, {ignoreNonPathable = false, precision = 0, ignoreCreatures = true})
    if not realPath then
        info("realPath nil, tentando escada")
        local stairTile = FollowAttack.findNearestStair(playerPos)
        if stairTile then
            FollowAttack.approachAndUse(playerPos, stairTile)
            return
        end
    end

    if FollowAttack.obstaclesQueue[1] and FollowAttack.obstaclesQueue[1].isDoor then
        return
    end

    g_game.setChaseMode(1)

    if storage.followAttack.useKunai and distance > FollowAttack.kunaiRange and FollowAttack.findKunai() then
        FollowAttack.useKunaiToward(targetPosition)
        return
    end

    local tileToUse = playerPos
    for i, value in ipairs(path) do
        if i > 5 then break end
        tileToUse = FollowAttack.getDirection(tileToUse, value)
    end
    FollowAttack.useTile(g_map.getTile(tileToUse))
end)

FollowAttack.targetVisible    = true
FollowAttack.savedZ           = nil
FollowAttack.targetChangedFloor = false
FollowAttack.disappearPending = false

onCreatureDisappear(function(creature)
    if creature:getId() == FollowAttack.currentTargetId then
        local p = creature:getPosition()
        FollowAttack.savedZ           = p and p.z
        FollowAttack.disappearPending = true
        schedule(100, function()
            if FollowAttack.disappearPending then
                FollowAttack.targetChangedFloor = true
                FollowAttack.disappearPending   = false
            end
        end)
    end
end)

onCreatureAppear(function(creature)
    if creature:getId() == FollowAttack.currentTargetId then
        local newZ = creature:getPosition() and creature:getPosition().z
        local playerZ = player:getPosition().z
        FollowAttack.disappearPending = false
        if newZ and newZ ~= playerZ then
            FollowAttack.targetChangedFloor = true
        else
            FollowAttack.targetChangedFloor = false
        end
    end
end)

onKeyDown(function(key)
    if key == "Escape" then
        FollowAttack.currentTargetId = nil
        FollowAttack.obstaclesQueue  = {}
    end
end)

local kunaiCheckBox = setupUI([[
CheckBox
  font: cipsoftFont
  text: Usar Kunai
]])

kunaiCheckBox.onCheckChange = function(widget, checked)
    storage.followAttack.useKunai = checked
end

if storage.followAttack.useKunai == nil then
    storage.followAttack.useKunai = false
end

kunaiCheckBox:setChecked(storage.followAttack.useKunai)

UI.Label("ID da Kunai:")
local kunaiIdEdit = UI.TextEdit()
kunaiIdEdit:setText(tostring(storage.followAttack.kunaiId or 7382))
kunaiIdEdit.onTextChange = function(widget, text)
    local id = tonumber(text)
    if id then
        storage.followAttack.kunaiId = id
        FollowAttack.kunaiId         = id
    end
end
