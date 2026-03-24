panel = mainTab

local pushPlayer = {}

pushPlayer.isKeyPressed  = modules.corelib.g_keyboard.isKeyPressed
pushPlayer.isShiftPressed = modules.corelib.g_keyboard.isShiftPressed

local ATTACKING_COLORS = {"#FF8888", "#FF0000"}

local function resolveBattlePanel()
    local root = g_ui.getRootWidget()
    if not root then return nil end
    local gameRoot = root:getChildById("gameRootPanel")
    if not gameRoot then return nil end
    local battleWindow = gameRoot:getChildById("battleWindow")
    if not battleWindow then return nil end
    local contentsPanel = battleWindow:getChildById("contentsPanel")
    if not contentsPanel then return nil end
    return contentsPanel:getChildById("battlePanel")
end

local battlePanel = resolveBattlePanel()

pushPlayer.searchWithinVariables = function()
    for key, func in pairs(g_game) do
        if type(func) == "function" and key:lower():match("getatt") then
            local ok, result = pcall(func)
            if ok and result and (result:isPlayer() or result:isMonster()) then
                return result
            end
        end
    end
end

pushPlayer.getAttackingCreature = function()
    if not battlePanel then return pushPlayer.searchWithinVariables() end
    local currentZ = player:getPosition().z
    for _, child in ipairs(battlePanel:getChildren()) do
        local creature = child.creature
        if creature then
            local cPos = creature:getPosition()
            if cPos and cPos.z == currentZ and table.find(ATTACKING_COLORS, child.color) then
                return creature
            end
        end
    end
    return pushPlayer.searchWithinVariables()
end

pushPlayer.getAway = function(targetPos)
    local playerPos = player:getPosition()
    local dx = playerPos.x - targetPos.x
    local dy = playerPos.y - targetPos.y

    -- normaliza para direção oposta ao target
    local stepX = dx == 0 and 0 or (dx > 0 and 2 or -2)
    local stepY = dy == 0 and 0 or (dy > 0 and 2 or -2)

    -- tenta diagonal primeiro, depois os eixos separados
    local candidates = {
        {x = playerPos.x + stepX, y = playerPos.y + stepY, z = playerPos.z},
        {x = playerPos.x + stepX, y = playerPos.y,         z = playerPos.z},
        {x = playerPos.x,         y = playerPos.y + stepY, z = playerPos.z},
    }

    for _, newPos in ipairs(candidates) do
        local tile = g_map.getTile(newPos)
        if tile and tile:isWalkable() and tile:isPathable() then
            g_game.use(tile:getTopThing())
            delay(400)
            return
        end
    end
end

pushPlayer.positions = {
    ["W"] = {x = 0,  y = -1},
    ["A"] = {x = -1, y = 0},
    ["S"] = {x = 0,  y = 1},
    ["D"] = {x = 1,  y = 0},
    ["Q"] = {x = -1, y = -1},
    ["E"] = {x = 1,  y = -1},
    ["C"] = {x = 1,  y = 1},
    ["Z"] = {x = -1, y = 1}
}

macro(1, "Push", function()
    if not pushPlayer.isShiftPressed() then return end
    if modules.game_console:isChatEnabled() then
        modules.game_textmessage.displayFailureMessage("Desative o chat para usar o Push.")
        return
    end

    local target = pushPlayer.getAttackingCreature()
    if not target then return end

    local targetPos = target:getPosition()
    if not targetPos then return end

    local sumPos
    for key, sum in pairs(pushPlayer.positions) do
        if pushPlayer.isKeyPressed(key) then
            sumPos = sum
            break
        end
    end

    if not sumPos then return end

    local playerPos = player:getPosition()
    local distance  = getDistanceBetween(playerPos, targetPos)

    if distance > 1 then
        local newPos = {
            x = targetPos.x + sumPos.x,
            y = targetPos.y + sumPos.y,
            z = targetPos.z
        }
        local tile = g_map.getTile(newPos)
        if tile and tile:isWalkable() and tile:isPathable() then
            g_game.move(target, newPos)
            delay(300)
        end
    else
        pushPlayer.getAway(targetPos)
    end
end)
