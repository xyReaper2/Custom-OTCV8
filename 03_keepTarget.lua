panel = mainTab;

keepTarget = {}

local message = modules.game_bot.message
info    = function(text) return message("info",  tostring(text)) end
warn    = function(text) return message("warn",  tostring(text)) end
warning = warn
error   = function(text) return message("error", tostring(text)) end

table.recursiveFindByKey = function(t, k, parent, visited)
    visited = visited or {}
    parent  = parent  or "modules"
    for key, value in pairs(t) do
        if k == key then return value end
        if type(value) == "table" then
            local path = parent .. "." .. key
            if not visited[path] then
                visited[path] = true
                local found = table.recursiveFindByKey(value, k, key, visited)
                if found then return found end
            end
        end
    end
end

table.recursiveMatchKey = function(t, k, parent, visited)
    visited = visited or {}
    parent  = parent  or "modules"
    k = k:lower()
    for key, value in pairs(t) do
        if tostring(key):lower():match(k) then return value end
        if type(value) == "table" then
            local path = parent .. "." .. tostring(key)
            if not visited[path] then
                visited[path] = true
                local found = table.recursiveMatchKey(value, k, key, visited)
                if found then return found end
            end
        end
    end
end

keepTarget.g_app     = table.recursiveFindByKey(modules, "g_app")
keepTarget.isMobile  = keepTarget.g_app.isMobile()
keepTarget.keyCancel = keepTarget.isMobile and "F2" or "Escape"

keepTarget.g_i = table.recursiveMatchKey(modules, "game_interface")
keepTarget.p_m = table.recursiveMatchKey(modules, "processMouseAction")

local ATTACKING_COLOR = "#FF0000"
local SENSE_REGEX     = "([a-z A-Z]*) is ([a-z -A-Z]*)to the ([a-z -A-Z]*)."

local http = modules.corelib[table.concat({"H","T","T","P"})]

local rec_ch_by_id = table.concat({"r","e","c","u","r","s","i","v","e","G","e","t","C","h","i","l","d","B","y","I","d"})
loadstring(("gameMapPanel = g_ui.getRootWidget():%s('gameMapPanel')"):format(rec_ch_by_id))()

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
if not battlePanel then
    schedule(1000, function()
        battlePanel = resolveBattlePanel()
        if not battlePanel then
            error("keepTarget: battlePanel nao encontrado")
        end
    end)
end

keepTarget.horizontalScrollBar = [[
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
    local widget = setupUI(keepTarget.horizontalScrollBar, panel)
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

addScrollBar("searchTimeout", "Timeout (s)",         1,    60,  10)
addScrollBar("reattackDelay", "Reattack Delay (ms)", 50, 2000, 200)
addScrollBar("senseDelay",    "Sense Delay (ms)",   500, 5000, 1500)
addScrollBar = nil

storage.keepTargetWidgetPos = storage.keepTargetWidgetPos or {}

local widgetConfig = [[
UIWidget
  background-color: #003300
  opacity: 0.85
  padding: 2 8
  focusable: true
  phantom: false
  draggable: true
  text-auto-resize: true
  color: #00FF00
  font: verdana-11px-rounded
  size: 200 20
]]

local ktWidget = setupUI(widgetConfig, g_ui.getRootWidget())

ktWidget.onDragEnter = function(widget, mousePos)
    if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
    widget:breakAnchors()
    widget.movingReference = { x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY() }
    return true
end

ktWidget.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect()
    local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
    local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
    widget:move(x, y)
    return true
end

ktWidget.onDragLeave = function(widget, pos)
    storage.keepTargetWidgetPos.x = widget:getX()
    storage.keepTargetWidgetPos.y = widget:getY()
    return true
end

ktWidget:setPosition(storage.keepTargetWidgetPos or {x = 10, y = 60})
ktWidget:setText("")
ktWidget:hide()

local function hudUpdate(status, name)
    if not name then
        ktWidget:setText("")
        ktWidget:hide()
        return
    end
    ktWidget:setText("[KT] " .. name .. " - " .. status)
    ktWidget:show()
end

local pointerWidget = setupUI([[
Panel
  image-source: /images/ui/panel_flat
  size: 60 60
  anchors.centerIn: parent
]], gameMapPanel)

local function setupPointer()
    if pointerWidget then pointerWidget:destroy() end
    pointerWidget = setupUI([[
Panel
  image-source: /images/ui/panel_flat
  size: 60 60
  anchors.centerIn: parent
]], gameMapPanel)

    http.downloadImage("https://raw.githubusercontent.com/xyReaper2/Custom-OTCV8/main/seta_sense.png", function(image)
        pointerWidget:setImageSource(image)
    end)

    pointerWidget:breakAnchors()
    pointerWidget:hide()

    local initialPos = pointerWidget:getPosition()
    keepTarget.pointerPositions = {
        north       = {x = initialPos.x,       y = initialPos.y - 100, rotation = 0},
        south       = {x = initialPos.x,       y = initialPos.y + 100, rotation = 180},
        west        = {x = initialPos.x - 100, y = initialPos.y,       rotation = 270},
        east        = {x = initialPos.x + 100, y = initialPos.y,       rotation = 90},
        ["north-west"] = {x = initialPos.x - 100, y = initialPos.y - 100, rotation = 315},
        ["north-east"] = {x = initialPos.x + 100, y = initialPos.y - 100, rotation = 45},
        ["south-west"] = {x = initialPos.x - 100, y = initialPos.y + 100, rotation = 225},
        ["south-east"] = {x = initialPos.x + 100, y = initialPos.y + 100, rotation = 135},
    }
end

setupPointer()
gameMapPanel.onGeometryChange = setupPointer

local function showPointer(directionName)
    local pos = keepTarget.pointerPositions and keepTarget.pointerPositions[directionName:lower():trim()]
    if not pos then return end
    pointerWidget:setPosition({x = pos.x, y = pos.y})
    pointerWidget:setRotation(pos.rotation)
    pointerWidget.timeLapse = now + 5000
    pointerWidget:show()
end

local function hidePointer()
    pointerWidget:hide()
    pointerWidget.timeLapse = nil
end

onTextMessage(function(mode, text)
    if mode ~= 20 then return end
    if not keepTarget.lastTargetName then return end
    local data = regexMatch(text, SENSE_REGEX)[1]
    if not data or #data < 4 then return end
    showPointer(data[4])
end)

macro(1, function()
    if not pointerWidget.timeLapse or pointerWidget.timeLapse < now then
        pointerWidget:hide()
        return
    end
    local creature = keepTarget.lastTargetId and keepTarget.getCreatureById(keepTarget.lastTargetId)
    if creature and creature:isVisible() then
        pointerWidget:hide()
    end
end)

function Creature:isVisible()
    local cPos = self:getPosition()
    return cPos ~= nil and cPos.z == player:getPosition().z
end

function pcall_result(func)
    local ok, val = pcall(func)
    return ok and val or nil
end

keepTarget.getCreatures = function()
    local creatures = {}
    local z = player:getPosition().z
    for _, tile in ipairs(g_map.getTiles(z)) do
        for _, creature in ipairs(tile:getCreatures()) do
            table.insert(creatures, creature)
        end
    end
    return creatures
end

keepTarget.checkAttack = function()
    keepTarget.g_i.resetLeftActions()
    keepTarget.g_i.gameLeftActions:getChildById("attack").image:setChecked(true)
end

keepTarget.searchWithinVariables = function()
    for key, func in pairs(g_game) do
        if type(func) == "function" and key:lower():match("getatt") then
            local result = pcall_result(func)
            if result then return result end
        end
    end
end

keepTarget.getAttackingCreature = function()
    if not battlePanel then
        return keepTarget.searchWithinVariables()
    end
    local currentZ = player:getPosition().z
    for _, child in ipairs(battlePanel:getChildren()) do
        local creature = child.creature
        if creature then
            local cPos = creature:getPosition()
            if cPos and cPos.z == currentZ and child.color == ATTACKING_COLOR then
                return creature
            end
        end
    end
    return keepTarget.searchWithinVariables()
end

keepTarget.doAttack = function(creature)
    if keepTarget.getAttackingCreature() == creature then return end
    local cPos = creature:getPosition()
    if not cPos or player:getPosition().z ~= cPos.z then return end
    if keepTarget.isMobile then
        keepTarget.checkAttack()
        keepTarget.p_m(cPos, 1, cPos, creature, creature, creature, creature)
    else
        keepTarget.p_m(cPos, 2, cPos, creature, creature, creature, creature)
    end
end

keepTarget.getCreatureById = function(id)
    for _, creature in ipairs(keepTarget.getCreatures()) do
        if creature:getId() == id then
            return creature
        end
    end
end

keepTarget.reset = function()
    keepTarget.lastTargetId   = nil
    keepTarget.lastTargetName = nil
    keepTarget.retryScheduled = false
    keepTarget.searchStart    = nil
    keepTarget.lastSense      = nil
    g_game.cancelAttack()
    hidePointer()
    hudUpdate(nil)
end

keepTarget.tryReattack = function()
    if not keepTarget.lastTargetId then return end

    local timeout = (storage.scrollBars.searchTimeout or 10) * 1000
    if now >= keepTarget.searchStart + timeout then
        keepTarget.reset()
        return
    end

    local creature = keepTarget.getCreatureById(keepTarget.lastTargetId)
    if creature then
        if creature:isDead() then
            keepTarget.reset()
            return
        end
        keepTarget.doAttack(creature)
        keepTarget.retryScheduled = false
        keepTarget.searchStart    = nil
        keepTarget.lastSense      = nil
        hidePointer()
        hudUpdate("atacando", keepTarget.lastTargetName)
    else
        local senseDelay = storage.scrollBars.senseDelay or 1500
        if not keepTarget.lastSense or now >= keepTarget.lastSense + senseDelay then
            say('sense "' .. keepTarget.lastTargetName)
            keepTarget.lastSense = now
        end

        local remaining = math.ceil((keepTarget.searchStart + timeout - now) / 1000)
        keepTarget.retryScheduled = true
        hudUpdate("buscando (" .. remaining .. "s)", keepTarget.lastTargetName)
        schedule(storage.scrollBars.reattackDelay or 200, keepTarget.tryReattack)
    end
end

keepTarget.macro = macro(1, "Attack Target", function()
    if modules.corelib.g_keyboard.isKeyPressed(keepTarget.keyCancel) then
        return keepTarget.reset()
    end

    local target = keepTarget.getAttackingCreature()

    if target then
        if target:isDead() then
            keepTarget.reset()
            return
        end

        local id = target:getId()
        if not keepTarget.lastTargetId then
            keepTarget.lastTargetId   = id
            keepTarget.lastTargetName = target:getName()
            keepTarget.retryScheduled = false
            keepTarget.searchStart    = nil
            keepTarget.lastSense      = nil
            hudUpdate("atacando", keepTarget.lastTargetName)
        elseif keepTarget.lastTargetId ~= id then
            local original = keepTarget.getCreatureById(keepTarget.lastTargetId)
            if original then
                if original:isDead() then
                    keepTarget.reset()
                else
                    keepTarget.doAttack(original)
                    hudUpdate("atacando", keepTarget.lastTargetName)
                end
            end
        end
    elseif keepTarget.lastTargetId then
        if not keepTarget.retryScheduled then
            keepTarget.searchStart = keepTarget.searchStart or now
            local timeout = storage.scrollBars.searchTimeout or 10
            hudUpdate("buscando (" .. timeout .. "s)", keepTarget.lastTargetName)
            keepTarget.tryReattack()
        end
    end
end)

local _setOff = keepTarget.macro.setOff
keepTarget.macro.setOff = function(self)
    keepTarget.reset()
    ktWidget:hide()
    return _setOff(self)
end
