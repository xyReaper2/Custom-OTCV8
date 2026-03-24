storage.travelConfig = storage.travelConfig or {
    npcs = {},
    keyword = ""
}

local travelUI = nil
local npcConfigUI = nil
local waitingKeyword = false
local waitingCities = false
local nearNpc = nil

local function cleanCityName(s)
    s = (s or ""):trim()
    s = s:gsub("^[%p%s]+", ""):gsub("[%p%s]+$", "")
    return s ~= "" and s or nil
end

local function parseCities(text)
    local citiesStr = text:match("[Pp]ara (.-)[%.!]?%s*[Aa]onde")
    if not citiesStr then
        citiesStr = text:match("[Pp]ara (.+)%.")
    end
    if not citiesStr then return {} end

    citiesStr = citiesStr:gsub(" e ", ", ")
    citiesStr = citiesStr:gsub("[{}]", "")

    local cities = {}
    for city in citiesStr:gmatch("[^,]+") do
        local cleaned = cleanCityName(city)
        if cleaned then
            table.insert(cities, cleaned)
        end
    end
    return cities
end


local function detectKeyword(text)
    local patterns = {
        "para%s*{([^}]+)}%s*para",
        "para%s*{([^}]+)}%s*qualquer",
        "para%s+(%a+)%s+para",
        "para%s+(%a+)%s+qualquer",
        "(travel)%s+(%a+)",
        "(transport)%s+(%a+)",
        "(travel)%s*{([^}]+)}",
        "(transport)%s*{([^}]+)}",
        "onde%s+posso%s+ir%s+para%s*{([^}]+)}",
        "(go)%s+to%s+(%a+)",
        "(destinations?)%s+(%a+)",
        "para%s+(%a+)"
    }
    
    for _, pattern in ipairs(patterns) do
        local match = text:lower():match(pattern)
        if match then
            match = match:gsub("[%{%}]", ""):trim()
            if match ~= "cidade" and match ~= "cidades" and match ~= "lugar" and 
               match ~= "local" and match ~= "onde" and match ~= "qualquer" and
               match ~= "ir" and match ~= "go" then
                return match
            end
        end
    end
    
    local fallback = text:lower():match("para%s+(%a+)")
    if fallback and fallback ~= "cidade" and fallback ~= "cidades" then
        return fallback
    end
    
    return nil
end

local function closeTravelUI()
    if travelUI then
        travelUI:destroy()
        travelUI = nil
    end
end

local function openTravelUI(cities)
    closeTravelUI()

    travelUI = setupUI([[
UIWidget
  size: 400 300
  border-width: 1
  border-color: #446688
  focusable: true
  phantom: false
  draggable: true
  background-color: #000000CC
  @onEscape: self:hide()

  Label
    id: titleLabel
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 8
    text: TRAVEL SYSTEM
    color: #FFFFFF
    font: verdana-11px-rounded

  UIWidget
    anchors.top: titleLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #446688

  ScrollablePanel
    id: cityPanel
    layout:
      type: grid
      cell-size: 85 26
      cell-spacing: 3
      num-columns: 4
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    anchors.bottom: separator.top
    margin: 8 8 8 8

  UIWidget
    id: separator
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-bottom: 5
    margin-left: 5
    margin-right: 5
    height: 1
    background-color: #446688

  UIWidget
    id: closeBtn
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: 70
    height: 22
    margin-bottom: 5
    margin-right: 5
    text: FECHAR
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text-align: center
    focusable: true
]], g_ui.getRootWidget())

    travelUI:setPosition({
        x = math.floor((g_ui.getRootWidget():getWidth()  - 400) / 2),
        y = math.floor((g_ui.getRootWidget():getHeight() - 300) / 2)
    })

    travelUI.onDragEnter = function(widget, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
        widget:breakAnchors()
        widget.ref = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
        return true
    end

    travelUI.onDragMove = function(widget, mousePos)
        local r = widget:getParent():getRect()
        local x = math.min(math.max(r.x, mousePos.x - widget.ref.x), r.x + r.width - widget:getWidth())
        local y = math.min(math.max(r.y, mousePos.y - widget.ref.y), r.y + r.height - widget:getHeight())
        widget:move(x, y)
        return true
    end

    for _, city in ipairs(cities) do
        local btn = setupUI([[
UIWidget
  background-color: #00000000
  border-width: 1
  border-color: #446688
  color: #FFFFFF
  font: verdana-11px-rounded
  text-align: center
  focusable: true
]], travelUI.cityPanel)
        btn:setText(city)
        btn.onClick = function()
            say(city)
            schedule(600, function() say("yes") end)
            closeTravelUI()
        end
    end

    travelUI.closeBtn.onClick = closeTravelUI
end

local npcEntryUI = [[
UIWidget
  background-color: alpha
  height: 18
  focusable: true

  Label
    id: lbl
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 5
    font: verdana-11px-rounded
    color: #FFFFFF
    text-auto-resize: true

  UIWidget
    id: btn
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 5
    width: 16
    height: 16
    text: X
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  $focus:
    background-color: #00000055
]]

local npcListWidget = nil

local function refreshNpcList()
    if not npcListWidget then return end
    npcListWidget:destroyChildren()
    for i, npcName in ipairs(storage.travelConfig.npcs) do
        local row = setupUI(npcEntryUI, npcListWidget)
        row.lbl:setText(npcName)
        local idx = i
        row.btn.onClick = function()
            table.remove(storage.travelConfig.npcs, idx)
            refreshNpcList()
        end
    end
end

UI.Button("NPCs de Travel", function()
    if npcConfigUI then
        npcConfigUI:destroy()
        npcConfigUI = nil
    end

    npcConfigUI = setupUI([[
UIWidget
  size: 280 320
  border-width: 1
  border-color: #446688
  focusable: true
  phantom: false
  draggable: true
  background-color: #000000CC
  @onEscape: self:hide()

  Label
    id: titleLabel
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 8
    text: TRAVEL SYSTEM
    color: #FFFFFF
    font: verdana-11px-rounded

  UIWidget
    anchors.top: titleLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #446688

  Label
    id: npcLabel
    anchors.top: prev.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 6
    text: NPCS NAME
    color: #cc44cc
    font: verdana-11px-rounded

  TextList
    id: npcList
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: npcLabel.bottom
    anchors.bottom: separator.top
    margin: 6 8 6 8
    background-color: #00000000
    image-color: #00000000
    border-width: 1
    border-color: #446688
    vertical-scrollbar: npcScrollbar

  VerticalScrollBar
    id: npcScrollbar
    anchors.top: npcList.top
    anchors.bottom: npcList.bottom
    anchors.right: npcList.right
    step: 14
    pixels-scroll: true

  UIWidget
    id: separator
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: addEdit.top
    margin-bottom: 5
    margin-left: 5
    margin-right: 5
    height: 1
    background-color: #446688

  TextEdit
    id: addEdit
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: 140
    height: 22
    margin-bottom: 5
    margin-left: 5
    background-color: #00000000
    image-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded

  UIWidget
    id: addBtn
    anchors.left: addEdit.right
    anchors.bottom: parent.bottom
    width: 50
    height: 22
    margin-bottom: 5
    margin-left: 4
    text: ADD
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  UIWidget
    id: closeBtn
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: 60
    height: 22
    margin-bottom: 5
    margin-right: 5
    text: FECHAR
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text-align: center
    focusable: true
]], g_ui.getRootWidget())

    npcConfigUI:setPosition({
        x = math.floor((g_ui.getRootWidget():getWidth()  - 280) / 2),
        y = math.floor((g_ui.getRootWidget():getHeight() - 320) / 2)
    })

    npcConfigUI.onDragEnter = function(widget, mousePos)
        if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
        widget:breakAnchors()
        widget.ref = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
        return true
    end

    npcConfigUI.onDragMove = function(widget, mousePos)
        local r = widget:getParent():getRect()
        local x = math.min(math.max(r.x, mousePos.x - widget.ref.x), r.x + r.width - widget:getWidth())
        local y = math.min(math.max(r.y, mousePos.y - widget.ref.y), r.y + r.height - widget:getHeight())
        widget:move(x, y)
        return true
    end

    npcListWidget = npcConfigUI.npcList
    refreshNpcList()

    npcConfigUI.addBtn.onClick = function()
        local name = npcConfigUI.addEdit:getText():trim()
        if name ~= "" then
            table.insert(storage.travelConfig.npcs, name)
            npcConfigUI.addEdit:setText("")
            refreshNpcList()
        end
    end

    npcConfigUI.closeBtn.onClick = function()
        npcConfigUI:destroy()
        npcConfigUI = nil
    end
end)

UI.Separator()

local function isNearNpc(npcName)
    local z = player:getPosition().z
    for _, tile in ipairs(g_map.getTiles(z)) do
        for _, creature in ipairs(tile:getCreatures()) do
            if creature:isNpc() and creature:getName():lower() == npcName:lower() then
                if getDistanceBetween(player:getPosition(), creature:getPosition()) <= 5 then
                    return true
                end
            end
        end
    end
    return false
end

macro(500, "Travel NPC", function()
    if waitingKeyword or waitingCities then return end
    for _, npcName in ipairs(storage.travelConfig.npcs) do
        if isNearNpc(npcName) then
            if nearNpc ~= npcName then
                nearNpc = npcName
                waitingKeyword = true
                say("hi")
            end
            return
        end
    end
    nearNpc = nil
end)

onTalk(function(name, level, mode, text, channelId, pos)
    local isConfiguredNpc = false
    for _, npcName in ipairs(storage.travelConfig.npcs) do
        if name:lower() == npcName:lower() then
            isConfiguredNpc = true
            break
        end
    end
    if not isConfiguredNpc then return end

    if waitingKeyword then
        local keyword = detectKeyword(text)
        if keyword then
            storage.travelConfig.keyword = keyword
            waitingKeyword = false
            waitingCities = true
            schedule(400, function()
                say(keyword)
            end)
        end
        return
    end

    if waitingCities then
        local cities = parseCities(text)
        if #cities > 0 then
            waitingCities = false
            openTravelUI(cities)
        end
        return
    end
end)
