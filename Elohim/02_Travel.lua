storage.travelConfig = storage.travelConfig or {
    npcs = {},
    keyword = ""
}

local travelUI = nil
local waitingKeyword = false
local waitingCities = false
local nearNpc = nil

local function cleanCityName(s)
    s = (s or ""):trim()
    s = s:gsub("^[%p%s]+", ""):gsub("[%p%s]+$", "")
    return s ~= "" and s or nil
end

local function parseCities(text)
    local citiesStr = text:match("[Pp]ara (.+)[%.!]?%s*[Aa]onde")
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

NPC.say = function(text)
    if (g_game.getClientVersion() >= 810) then
        g_game.talkChannel(11, 0, text)
    else
        return say(text)
    end
end

local function closeTravelUI()
    if travelUI then
        travelUI:destroy()
        travelUI = nil
    end
end

local cityBtnUI = [[
UIWidget
  background-color: #00000000
  border-width: 1
  border-color: #446688
  color: #FFFFFF
  font: verdana-11px-rounded
  text-align: center
  focusable: true
  height: 26
]]

local function openTravelUI(npcName, cities)
    closeTravelUI()

    local COLS       = 4
    local CELL_H     = 26
    local CELL_SPACE = 4
    local MARGIN_V   = 8
    local TITLE_H    = 35
    local LABEL_H    = 24
    local FOOTER_H   = 40
    local rows       = math.ceil(#cities / COLS)
    local gridH      = rows * CELL_H + math.max(0, rows - 1) * CELL_SPACE
    local totalH     = TITLE_H + LABEL_H + MARGIN_V + gridH + MARGIN_V + FOOTER_H
    totalH           = math.max(totalH, 130)

    travelUI = setupUI([[
UIWidget
  border-width: 1
  border-color: #446688
  focusable: true
  phantom: false
  draggable: true
  background-color: #0d0d1aEE
  @onEscape: self:hide()

  Panel
    id: titlebar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 34
    background-color: #080810

    Label
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      text: TRAVEL SYSTEM
      color: #cc44cc
      font: verdana-11px-rounded

    Label
      id: npcNameLabel
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 10
      color: #4ACC4A
      font: verdana-11px-rounded
      text-auto-resize: true

  UIWidget
    anchors.top: titlebar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    background-color: #446688

  Label
    id: destLabel
    anchors.top: prev.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 8
    text: ESCOLHA O DESTINO
    color: #556677
    font: verdana-11px-rounded

  Panel
    id: cityPanel
    layout:
      type: grid
      cell-size: 85 26
      cell-spacing: 4
      num-columns: 4
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: destLabel.bottom
    anchors.bottom: separator.top
    margin: 8 10 8 10

  UIWidget
    id: separator
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-bottom: 5
    margin-left: 8
    margin-right: 8
    height: 1
    background-color: #1a2a3a

  UIWidget
    id: closeBtn
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: 70
    height: 22
    margin-bottom: 6
    margin-right: 8
    text: FECHAR
    background-color: #00000000
    border-width: 1
    border-color: #664444
    color: #cc8888
    font: verdana-11px-rounded
    text-align: center
    focusable: true
]], g_ui.getRootWidget())

    travelUI:setSize({width = 400, height = totalH})
    travelUI:setPosition({
        x = math.floor((g_ui.getRootWidget():getWidth()  - 400) / 2),
        y = math.floor((g_ui.getRootWidget():getHeight() - totalH) / 2)
    })

    travelUI.titlebar.npcNameLabel:setText(npcName or "")

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
        local btn = setupUI(cityBtnUI, travelUI.cityPanel)
        btn:setText(city)
        btn.onClick = function()
            NPC.say(city)
            schedule(600, function() NPC.say("yes") end)
            closeTravelUI()
        end
        btn.onMouseEnter = function(widget)
            widget:setBorderColor('#cc44cc')
            widget:setColor('#cc44cc')
        end
        btn.onMouseLeave = function(widget)
            widget:setBorderColor('#446688')
            widget:setColor('#FFFFFF')
        end
    end

    travelUI.closeBtn.onClick = closeTravelUI
end

local npcEntryUI = [[
Panel
  background-color: alpha
  height: 26
  focusable: true
  margin-bottom: 3

  Label
    id: lbl
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 8
    font: verdana-11px-rounded
    color: #cc44cc
    text-auto-resize: true

  UIWidget
    id: statusDot
    anchors.right: btn.left
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 6
    width: 8
    height: 8
    background-color: #2a5a2a
    image-color: #2a5a2a

  UIWidget
    id: btn
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 6
    width: 18
    height: 18
    text: X
    background-color: #00000000
    border-width: 1
    border-color: #664444
    color: #cc8888
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  $focus:
    background-color: #1a1a2a
    border-width: 1
    border-color: #446688
]]

local npcConfigUI = setupUI([[
UIWidget
  id: travelWindow
  size: 290 330
  border-width: 1
  border-color: #446688
  focusable: true
  phantom: false
  draggable: true
  background-color: #0d0d1aEE
  visible: false
  @onEscape: self:hide()

  Panel
    id: titlebar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 34
    background-color: #080810

    Label
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      text: TRAVEL SYSTEM
      color: #cc44cc
      font: verdana-11px-rounded

    Label
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 10
      text: NPCS CADASTRADOS
      color: #556677
      font: verdana-11px-rounded

  UIWidget
    anchors.top: titlebar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    background-color: #446688

  TextList
    id: npcList
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    anchors.bottom: separator.top
    margin: 8 8 8 8
    background-color: #00000000
    image-color: #00000000
    border-width: 0
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
    margin-left: 8
    margin-right: 8
    height: 1
    background-color: #1a2a3a

  TextEdit
    id: addEdit
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    width: 145
    height: 22
    margin-bottom: 6
    margin-left: 8
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
    margin-bottom: 6
    margin-left: 4
    text: + ADD
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #88aacc
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  UIWidget
    id: closeBtn
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    width: 65
    height: 22
    margin-bottom: 6
    margin-right: 8
    text: FECHAR
    background-color: #00000000
    border-width: 1
    border-color: #664444
    color: #cc8888
    font: verdana-11px-rounded
    text-align: center
    focusable: true
]], g_ui.getRootWidget())

npcConfigUI:hide()
npcConfigUI:setPosition({
    x = math.floor((g_ui.getRootWidget():getWidth()  - 290) / 2),
    y = math.floor((g_ui.getRootWidget():getHeight() - 330) / 2)
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

npcConfigUI.closeBtn.onClick = function()
    npcConfigUI:hide()
end

local npcListWidget = npcConfigUI.npcList

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

npcConfigUI.addBtn.onClick = function()
    local name = npcConfigUI.addEdit:getText():trim()
    if name ~= "" then
        table.insert(storage.travelConfig.npcs, name)
        npcConfigUI.addEdit:setText("")
        refreshNpcList()
    end
end

UI.Button("NPCs de Travel", function()
    refreshNpcList()
    npcConfigUI.addEdit:setText("")
    npcConfigUI:show()
    npcConfigUI:raise()
    npcConfigUI:focus()
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
                NPC.say("hi")
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
        local keyword = text:match("{(%a+)}")
        if keyword then
            storage.travelConfig.keyword = keyword
            waitingKeyword = false
            waitingCities = true
            schedule(400, function()
                NPC.say(keyword)
            end)
        end
        return
    end

    if waitingCities then
        local cities = parseCities(text)
        if #cities > 0 then
            waitingCities = false
            openTravelUI(name, cities)
        end
        return
    end
end)