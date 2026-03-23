panel = mainTab;

local bugMap = {};

bugMap.kunaiId      = storage.bugMap and storage.bugMap.kunaiId or 7382
bugMap.isKeyPressed = modules.corelib.g_keyboard.isKeyPressed

storage.bugMap = storage.bugMap or {}

bugMap.checkBox = setupUI([[
CheckBox
  id: checkBox
  font: cipsoftFont
  text: Use Diagonal
]])

bugMap.checkBox.onCheckChange = function(widget, checked)
    storage.bugMapCheck = checked
end

if storage.bugMapCheck == nil then
    storage.bugMapCheck = true
end

bugMap.checkBox:setChecked(storage.bugMapCheck)

bugMap.kunaiCheckBox = setupUI([[
CheckBox
  id: kunaiCheckBox
  font: cipsoftFont
  text: Usar Kunai
]])

bugMap.kunaiCheckBox.onCheckChange = function(widget, checked)
    storage.bugMap.useKunai = checked
end

if storage.bugMap.useKunai == nil then
    storage.bugMap.useKunai = false
end

bugMap.kunaiCheckBox:setChecked(storage.bugMap.useKunai)

UI.Label("ID da Kunai:")
local kunaiIdEdit = UI.TextEdit()
kunaiIdEdit:setText(tostring(storage.bugMap.kunaiId or 7382))
kunaiIdEdit.onTextChange = function(widget, text)
    local id = tonumber(text)
    if id then
        storage.bugMap.kunaiId = id
        bugMap.kunaiId         = id
    end
end

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
    for _, container in pairs(g_game.getContainers()) do
        for _, item in ipairs(container:getItems()) do
            if item:getId() == bugMap.kunaiId then
                return item
            end
        end
    end
end

bugMap.macro = macro(1, "Bug Map", function()
    if modules.game_console:isChatEnabled() or modules.corelib.g_keyboard.isCtrlPressed() then return end
    local pos = pos()
    for key, config in pairs(bugMap.directions) do
        if bugMap.isKeyPressed(key) then
            if storage.bugMapCheck or config.direction then
                if config.direction then
                    turn(config.direction)
                end
                local tile = g_map.getTile({x = pos.x + config.x, y = pos.y + config.y, z = pos.z})
                if tile then
                    local topThing = tile:getTopUseThing()
                    if storage.bugMap.useKunai and bugMap.findKunai() and not bugMap.hasStairs(tile) then
                        return useWith(bugMap.kunaiId, topThing)
                    else
                        return g_game.use(topThing)
                    end
                end
            end
        end
    end
end)
