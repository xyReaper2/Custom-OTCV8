jumpBySave = {}

jumpBySave.message      = modules.game_bot.message
jumpBySave.isKeyPressed = modules.corelib.g_keyboard.isKeyPressed
jumpBySave.isMobile     = modules._G.g_app.isMobile()

jumpBySave.extraJumpDirections = {
    ['W'] = {x = 0,  y = -1, dir = 0},
    ['D'] = {x = 1,  y = 0,  dir = 1},
    ['S'] = {x = 0,  y = 1,  dir = 2},
    ['A'] = {x = -1, y = 0,  dir = 3}
}

local arrowXkey = {["W"] = "Up", ["S"] = "Down", ["D"] = "Right", ["A"] = "Left"}
for KEY, ARROW in pairs(arrowXkey) do
    jumpBySave.extraJumpDirections[ARROW] = table.copy(jumpBySave.extraJumpDirections[KEY])
end

jumpBySave.nextPosition = {
    {x = 0,  y = -1},
    {x = 1,  y = 0},
    {x = 0,  y = 1},
    {x = -1, y = 0},
    {x = 1,  y = -1},
    {x = 1,  y = 1},
    {x = -1, y = 1},
    {x = -1, y = -1}
}

jumpBySave.standingTime = now

onPlayerPositionChange(function(newPos, oldPos)
    jumpBySave.standingTime  = now
    jumpBySave.lastWalkPos   = oldPos
    jumpBySave.actualWalkPos = newPos
    jumpBySave.isWalking     = nil
end)

jumpBySave.standTime = function()
    return now - jumpBySave.standingTime
end

jumpBySave.posToString = function(pos)
    return pos.x .. ',' .. pos.y .. ',' .. pos.z
end

jumpBySave.getDistance = function(p1, p2)
    local dx = math.abs(p1.x - p2.x)
    local dy = math.abs(p1.y - p2.y)
    return math.sqrt(dx * dx + dy * dy)
end

jumpBySave.correctDirection = function()
    local dir = player:getDirection()
    if dir <= 3 then return dir end
    return dir < 6 and 1 or 3
end

jumpBySave.getNextDirection = function(pos, dir)
    local offset = jumpBySave.nextPosition[dir + 1]
    pos.x = pos.x + offset.x
    pos.y = pos.y + offset.y
    return pos
end

jumpBySave.getPressedKeys = function()
    local wasdWalking = modules.game_walking.wsadWalking

    if jumpBySave.isMobile then
        local marginTop  = jumpBySave.pointer:getMarginTop()
        local marginLeft = jumpBySave.pointer:getMarginLeft()
        for _, value in ipairs(jumpBySave.DIRS) do
            if marginTop  >= value.lowest.x and marginTop  <= value.highest.x and
               marginLeft >= value.lowest.y and marginLeft <= value.highest.y then
                return value.info
            end
        end
    else
        for walkKey, value in pairs(jumpBySave.extraJumpDirections) do
            if jumpBySave.isKeyPressed(walkKey) then
                if #walkKey > 1 or wasdWalking then
                    return value
                end
            end
        end
    end
end

if jumpBySave.isMobile then
    local keypad = g_ui.getRootWidget():recursiveGetChildById("keypad")
    jumpBySave.pointer = keypad.pointer

    jumpBySave.DIRS = {
        {highest = {x = -16, y = 29},  lowest = {x = -75, y = -30}, info = {dir = 0, x = 0,  y = -1}},
        {highest = {x = 29,  y = 75},  lowest = {x = -30, y = 15},  info = {dir = 1, x = 1,  y = 0}},
        {highest = {x = 75,  y = 29},  lowest = {x = 16,  y = -30}, info = {dir = 2, x = 0,  y = 1}},
        {highest = {x = 29,  y = -15}, lowest = {x = -30, y = -75}, info = {dir = 3, x = -1, y = 0}},
    }
end

storage.jumps = storage.jumps or {}
local config  = storage.jumps

if #config > 0 then
    for index, value in ipairs(config) do
        config[jumpBySave.posToString(value)] = {
            direction = value.direction,
            jumpTo    = value.jumpTo
        }
        config[index] = nil
    end
end

jumpBySave.kunaiId    = storage.kunaiConfig and storage.kunaiConfig.kunaiId       or 7382
jumpBySave.kunaiRange = storage.kunaiConfig and storage.kunaiConfig.kunaiDistance or 5

jumpBySave.findKunai = function()
    for _, container in pairs(g_game.getContainers()) do
        for _, item in ipairs(container:getItems()) do
            if item:getId() == jumpBySave.kunaiId then
                return item
            end
        end
    end
end

jumpBySave.useKunaiToJump = function(tilePos)
    if not storage.kunaiConfig or not storage.kunaiConfig.enabled then return false end
    if not jumpBySave.findKunai() then return false end

    local playerPos = player:getPosition()
    local dx   = tilePos.x - playerPos.x
    local dy   = tilePos.y - playerPos.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist == 0 then return false end

    local steps = math.min(jumpBySave.kunaiRange, math.floor(dist))
    local targetPos = {
        x = playerPos.x + math.floor(dx / dist * steps),
        y = playerPos.y + math.floor(dy / dist * steps),
        z = playerPos.z
    }

    local tile = g_map.getTile(targetPos)
    if not tile then return false end
    local topThing = tile:getTopUseThing()
    if not topThing then return false end

    useWith(jumpBySave.kunaiId, topThing)
    return true
end

function Creature:setAndClear(text, delayMs)
    self:setText(text)
    delayMs = delayMs or 500
    local time = now + delayMs
    self.time = time
    schedule(delayMs, function()
        if self.time ~= time then return end
        self:clearText()
    end)
end

onTalk(function(name, level, mode, text)
    if not storage.jumps.savePositions then return end
    if name ~= player:getName() then return end
    if mode ~= 44 then return end
    if not jumpBySave.actualWalkPos or not jumpBySave.lastWalkPos then return end
    if jumpBySave.actualWalkPos.z == jumpBySave.lastWalkPos.z then return end
    if text:lower():find('jump') then
        local lastWalkPos = jumpBySave.posToString(jumpBySave.lastWalkPos)
        if not config[lastWalkPos] then
            text = text:gsub('"', ""):gsub(":", "")
            local saveJump = text:trim()
            config[lastWalkPos] = {
                direction = jumpBySave.correctDirection(),
                jumpTo    = saveJump
            }
            player:setAndClear(lastWalkPos .. '\n Saved as: ' .. saveJump)
        end
    end
end)

local MAX_FINDPATH_DIST = 15

jumpBySave.findNearestJump = function()
    local playerPos = pos()
    local nearest   = {}

    if jumpBySave.tile then
        jumpBySave.tile:setText("")
        jumpBySave.tile = nil
    end

    for stringPos, value in pairs(config) do
        local splitPos = stringPos:split(',')
        if #splitPos == 3 then
            local tilePos = {
                x = tonumber(splitPos[1]),
                y = tonumber(splitPos[2]),
                z = tonumber(splitPos[3])
            }

            if tilePos.z == playerPos.z then
                local distance = jumpBySave.getDistance(tilePos, playerPos)

                if not nearest.distance or distance < nearest.distance then
                    if distance <= MAX_FINDPATH_DIST then
                        local tile = g_map.getTile(tilePos)
                        if tile and tile:isWalkable() and tile:isPathable() then
                            if findPath(playerPos, tilePos) then
                                nearest = {
                                    tile      = tile,
                                    distance  = distance,
                                    direction = value.direction,
                                    jumpTo    = value.jumpTo
                                }
                            end
                        end
                    end
                end
            end
        end
    end

    return nearest
end

jumpBySave.doWalk = function(pos)
    local playerPos = player:getPosition()
    local path      = findPath(playerPos, pos)
    if not path then return end

    local kunaiThing
    for index, dir in ipairs(path) do
        if index > 5 then break end
        playerPos = jumpBySave.getNextDirection(playerPos, dir)
        local tmpTile = g_map.getTile(playerPos)
        if tmpTile and tmpTile:isWalkable(true) and tmpTile:isPathable() and tmpTile:canShoot() then
            kunaiThing = tmpTile:getTopThing()
        end
    end

    local tile = g_map.getTile(playerPos)
    if not tile then return end

    local topThing = tile:getTopThing()
    local distance = getDistanceBetween(playerPos, player:getPosition())
    if distance > 1 and storage.kunaiConfig and storage.kunaiConfig.enabled and kunaiThing then
        g_game.stop()
        useWith(jumpBySave.kunaiId, kunaiThing)
    end
    if topThing then use(topThing) end
end

macro(1, function()
    if stopCombo and stopCombo - 200 >= now then return end
    if jumpBySave.executeMacro and jumpBySave.executeMacro.isOff() then return end
    if player:isWalking() or jumpBySave.standTime() <= 200 then return end
    local values = jumpBySave.getPressedKeys()
    if not values then return end
    local currentPos = pos()
    turn(values.dir)
    currentPos.x = currentPos.x + values.x
    currentPos.y = currentPos.y + values.y
    local tile = g_map.getTile(currentPos)
    say(tile and tile:isFullGround() and "Jump up" or "Jump Down")
end)

jumpBySave.executeMacro = macro(1, "Jump", function()
    if jumpBySave.isWalking then return end
    local jumpInfo = jumpBySave.findNearestJump()

    if not jumpBySave.isKeyPressed(not jumpBySave.isMobile and "f" or "F1") then
        if jumpInfo.tile then
            jumpBySave.tile = jumpInfo.tile
            jumpInfo.tile:setText(jumpInfo.jumpTo, "red")
        end
        local currentPos = jumpBySave.posToString(pos())
        if jumpBySave.isKeyPressed("Delete") then
            if storage.jumps[currentPos] then
                player:setAndClear(currentPos .. '\n Removed.')
                storage.jumps[currentPos] = nil
            end
        end
    elseif jumpInfo.tile then
        local tilePos = jumpInfo.tile:getPosition()
        if tilePos then
            jumpBySave.tile = jumpInfo.tile
            jumpBySave.tile:setText(jumpInfo.jumpTo, "green")
            local distanceFromTile = getDistanceBetween(tilePos, pos())
            if distanceFromTile == 0 then
                g_game.turn(jumpInfo.direction)
                say(jumpInfo.jumpTo)
            elseif distanceFromTile == 1 then
                autoWalk(tilePos, 1)
                jumpBySave.isWalking = true
            else
                if not jumpBySave.useKunaiToJump(tilePos) then
                    jumpBySave.doWalk(tilePos)
                end
            end
        end
    else
        player:setAndClear("No jump nearby.")
    end
end)

local checkBox = setupUI([[
CheckBox
  id: checkBox
  font: cipsoftFont
  text: Save Positions
]])

checkBox.onCheckChange = function(widget, checked)
    storage.jumps.savePositions = checked
end

if storage.jumps.savePositions == nil then
    storage.jumps.savePositions = true
end

checkBox:setChecked(storage.jumps.savePositions)

UI.Separator()

UI.Button("Exportar Jumps", function()
    local export = {}
    for stringPos, value in pairs(config) do
        if type(stringPos) == "string" and stringPos:find(',') then
            export[stringPos] = value
        end
    end
    UI.MultilineEditorWindow(json.encode(export), {title = "Exportar Jumps", description = "Copie o JSON abaixo:", width = 350}, function() end)
end)

UI.Button("Importar Jumps", function()
    UI.MultilineEditorWindow("", {title = "Importar Jumps", description = "Cole o JSON dos jumps aqui:", width = 350}, function(text)
        local ok, data = pcall(json.decode, text:trim())
        if not ok or type(data) ~= "table" then
            jumpBySave.message("error", "JSON inválido.")
            return
        end
        local count = 0
        for stringPos, value in pairs(data) do
            if type(stringPos) == "string" and type(value) == "table" and value.direction and value.jumpTo then
                if not config[stringPos] then
                    config[stringPos] = {direction = value.direction, jumpTo = value.jumpTo}
                    count = count + 1
                end
            end
        end
        jumpBySave.message("info", count .. " jump(s) importado(s).")
    end)
end)

addIcon("jumpIcon", {item = 3001, text = "Jump"}, jumpBySave.executeMacro)
