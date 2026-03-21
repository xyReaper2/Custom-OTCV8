local senseMaintain = {
    senseRegex = "([a-z A-Z]*) is ([a-z -A-Z]*)to the ([a-z -A-Z]*)."
}

local http = modules.corelib[table.concat({"H","T","T","P"})]

local rec_ch_by_id = table.concat({"r","e","c","u","r","s","i","v","e","G","e","t","C","h","i","l","d","B","y","I","d"})
loadstring(("gameMapPanel = g_ui.getRootWidget():%s('gameMapPanel')"):format(rec_ch_by_id))()

senseMaintain.isKeyPressed = modules.corelib.g_keyboard.isKeyPressed

senseMaintain.horizontalScrollBar = [[
Panel
  height: 35
  margin-top: 3

  Label
    id: text
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: center

  HorizontalScrollBar
    id: scroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 3
    minimum: 0
    maximum: 10
    step: 1
]]

storage.scrollBars = storage.scrollBars or {}

local addScrollBar = function(id, title, min, max, defaultValue)
    local widget = setupUI(senseMaintain.horizontalScrollBar, panel)
    widget.scroll:setRange(min, max)
    if max - min > 1000 then
        widget.scroll:setStep(100)
    elseif max - min > 100 then
        widget.scroll:setStep(10)
    end
    widget.scroll:setValue(storage.scrollBars[id] or defaultValue)
    widget.scroll.onValueChange = function(scroll, value)
        storage.scrollBars[id] = value
        widget.scroll:setText(title .. ": " .. value)
    end
    widget.scroll.onValueChange(widget.scroll, widget.scroll:getValue())
end

addScrollBar("senseAnimStep", "Velocidade",   1,  20,  3)
addScrollBar("senseAnimT",    "Tamanho loop", 1, 100, 30)
addScrollBar = nil

senseMaintain.pointer = setupUI([[
Panel
  image-source: /images/ui/panel_flat
  size: 40 40
  phantom: true
]], gameMapPanel)

http.downloadImage("https://raw.githubusercontent.com/xyReaper2/Custom-OTCV8/main/seta_sense.png", function(image)
    senseMaintain.pointer:setImageSource(image)
end)

senseMaintain.pointer:hide()

senseMaintain.animT = 0

senseMaintain.getScreenPos = function(targetPos)
    local rect    = gameMapPanel:getRect()
    local dim     = gameMapPanel:getVisibleDimension()
    local tileW   = rect.width  / dim.width
    local tileH   = rect.height / dim.height
    local pPos    = player:getPosition()
    local centerX = rect.x + rect.width  / 2
    local centerY = rect.y + rect.height / 2
    return {
        x = centerX + (targetPos.x - pPos.x) * tileW,
        y = centerY + (targetPos.y - pPos.y) * tileH
    }
end

senseMaintain.getCenter = function()
    local rect = gameMapPanel:getRect()
    return {
        x = rect.x + rect.width  / 2,
        y = rect.y + rect.height / 2
    }
end

senseMaintain.clampToEdge = function(x, y)
    local rect   = gameMapPanel:getRect()
    local margin = 10
    return {
        x = math.max(rect.x + margin, math.min(rect.x + rect.width  - 40 - margin, x)),
        y = math.max(rect.y + margin, math.min(rect.y + rect.height - 40 - margin, y))
    }
end

senseMaintain.getRotation = function(fromX, fromY, toX, toY)
    return math.atan2(toY - fromY, toX - fromX) * (180 / math.pi) + 90
end

senseMaintain.stopTracking = function()
    senseMaintain.trackingName = nil
    senseMaintain.trackingPos  = nil
    senseMaintain.animT        = 0
    senseMaintain.pointer:hide()
end

if not getPlayerByName(player:getName()) then
    getPlayerByName = function(name)
        if type(name) ~= "string" then return end
        name = name:trim():lower()
        for _, tile in ipairs(g_map.getTiles(player:getPosition().z)) do
            for _, creature in ipairs(tile:getCreatures()) do
                if creature:isPlayer() and creature:getName():lower() == name then
                    return creature
                end
            end
        end
    end
end

function Creature:isNearby()
    local cPos = self:getPosition()
    local pPos = player:getPosition()
    return cPos and cPos.z == pPos.z and getDistanceBetween(pPos, cPos) <= 5
end

senseMaintain.searchWithinVariables = function()
    for key, func in pairs(g_game) do
        if type(func) == "function" and key:lower():match("getatt") then
            local ok, result = pcall(func)
            if ok and result and (result:isPlayer() or result:isMonster()) then
                return result
            end
        end
    end
end

local battlePanel = g_ui.getRootWidget():recursiveGetChildById("battlePanel")
local ATTACKING_COLORS = {"#FF8888", "#FF0000"}

senseMaintain.getAttackingCreature = function()
    if not battlePanel then return senseMaintain.searchWithinVariables() end
    local currentZ = pos().z
    for _, child in ipairs(battlePanel:getChildren()) do
        local creature = child.creature
        if creature then
            local cPos = creature:getPosition()
            if cPos and cPos.z == currentZ and table.find(ATTACKING_COLORS, child.color) then
                return creature
            end
        end
    end
    return senseMaintain.searchWithinVariables()
end

senseMaintain.dirPositions = {}

gameMapPanel.onGeometryChange = function()
    local rect    = gameMapPanel:getRect()
    local centerX = rect.x + rect.width  / 2
    local centerY = rect.y + rect.height / 2
    senseMaintain.dirPositions = {
        north          = {x = centerX,       y = centerY - 150},
        south          = {x = centerX,       y = centerY + 150},
        west           = {x = centerX - 150, y = centerY},
        east           = {x = centerX + 150, y = centerY},
        ["north-west"] = {x = centerX - 150, y = centerY - 150},
        ["north-east"] = {x = centerX + 150, y = centerY - 150},
        ["south-west"] = {x = centerX - 150, y = centerY + 150},
        ["south-east"] = {x = centerX + 150, y = centerY + 150},
    }
end

gameMapPanel.onGeometryChange()

onTextMessage(function(mode, text)
    if mode ~= 20 then return end
    local data = regexMatch(text, senseMaintain.senseRegex)[1]
    if not data or #data < 4 then return end

    local senseName = data[2]:trim()
    storage.senseNames = storage.senseNames or {}
    storage.senseNames.lastName = senseName

    if not senseMaintain.trackingName then return end
    if senseMaintain.trackingName:lower() ~= senseName:lower() then return end

    local creature = getPlayerByName(senseMaintain.trackingName)
    if creature then return end

    local dirPos = senseMaintain.dirPositions[data[4]:trim():lower()]
    if dirPos then
        senseMaintain.trackingPos = dirPos
    end
end)

macro(1, function()
    if not senseMaintain.trackingName then
        senseMaintain.pointer:hide()
        return
    end

    local center = senseMaintain.getCenter()
    local targetScreenPos

    local creature = getPlayerByName(senseMaintain.trackingName)
    if creature then
        targetScreenPos = senseMaintain.getScreenPos(creature:getPosition())
    elseif senseMaintain.trackingPos then
        targetScreenPos = senseMaintain.trackingPos
    else
        return
    end

    local maxT    = (storage.scrollBars.senseAnimT    or 30) / 100
    local step    = (storage.scrollBars.senseAnimStep or 3)  / 1000

    senseMaintain.animT = senseMaintain.animT + step
    if senseMaintain.animT > maxT then
        senseMaintain.animT = 0
    end

    local t  = senseMaintain.animT / maxT
    local px = center.x + (targetScreenPos.x - center.x) * t
    local py = center.y + (targetScreenPos.y - center.y) * t

    local clamped  = senseMaintain.clampToEdge(px - 20, py - 20)
    local rotation = senseMaintain.getRotation(center.x, center.y, targetScreenPos.x, targetScreenPos.y)

    senseMaintain.pointer:setPosition(clamped)
    senseMaintain.pointer:setRotation(rotation)
    senseMaintain.pointer:show()
end)

senseMaintain.macro = macro(1, "Sense", function()
    storage.senseNames = storage.senseNames or {}

    local target = senseMaintain.getAttackingCreature()
    if target and target:isPlayer() then
        storage.senseNames.targetName = target:getName()
    end

    for _, value in ipairs({
        {key = "T", name = storage.senseNames.targetName},
        {key = "V", name = storage.senseNames.lastName},
    }) do
        if value.name and senseMaintain.isKeyPressed(value.key) then
            local creature = getPlayerByName(value.name)
            if creature and creature:isNearby() then
                senseMaintain.stopTracking()
                return
            end

            senseMaintain.trackingName = value.name

            say('sense "' .. value.name)
            return
        end
    end

    if senseMaintain.trackingName then
        local creature = getPlayerByName(senseMaintain.trackingName)
        if creature and creature:isNearby() then
            senseMaintain.stopTracking()
        end
    end
end)

addIcon("senseIcon", {item = 7387, movable = true, text = "Sense"}, senseMaintain.macro)