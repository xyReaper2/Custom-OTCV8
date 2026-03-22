storage.treinarConfig = storage.treinarConfig or {}
storage.scrollBars    = storage.scrollBars    or {}

local windowUI = [[
UIWidget
  image-source: /images/ui/panel_flat
  size: 240 265
  @onEscape: self:hide()
  focusable: true
  phantom: false
  draggable: true
  border-width: 1
  border-color: #DDAA00

  Label
    id: titleLabel
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 8
    text: CONFIGURAR TREINO
    color: #DDAA00
    font: verdana-11px-rounded

  UIWidget
    id: divider
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #666666

  Label
    id: spellLabel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 8
    text: SPELL NAME
    color: #DDAA00
    font: verdana-11px-rounded

  TextEdit
    id: spellEdit
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 2
    margin-left: 6
    margin-right: 6
    height: 22
    background-color: #00000000
    image-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded

  Label
    id: restLabel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 10
    margin-left: 8
    text: REST SPELL
    color: #DDAA00
    font: verdana-11px-rounded

  TextEdit
    id: restEdit
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 2
    margin-left: 6
    margin-right: 6
    height: 22
    background-color: #00000000
    image-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded

  CheckBox
    id: restCheck
    anchors.top: prev.bottom
    anchors.left: parent.left
    margin-top: 4
    margin-left: 8
    text: Ativar Rest
    color: #FFFFFF
    font: verdana-11px-rounded  Label
    id: manaLabel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 10
    margin-left: 8
    text: MANA % MINIMA
    color: #DDAA00
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: manaScroll
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 4
    margin-left: 6
    margin-right: 6
    minimum: 1
    maximum: 100
    step: 1

  Label
    id: manaValue
    anchors.top: prev.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 3
    color: #FFFFFF
    font: verdana-11px-rounded

  UIWidget
    id: divider2
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #666666

  UIWidget
    id: saveBtn
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 6
    margin-left: 6
    margin-right: 6
    height: 22
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text: SALVAR
    text-align: center
    focusable: true
]]

local configWindow = setupUI(windowUI, g_ui.getRootWidget())
configWindow:hide()
configWindow:setPosition({
    x = g_ui.getRootWidget():getWidth()  / 2 - 120,
    y = g_ui.getRootWidget():getHeight() / 2 - 105
})

storage.treinarWindowPos = storage.treinarWindowPos or nil

configWindow.onDragEnter = function(widget, mousePos)
    if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
    widget:breakAnchors()
    widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
    return true
end

configWindow.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect()
    local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width  - widget:getWidth())
    local y = math.min(math.max(parentRect.y, mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
    widget:move(x, y)
    return true
end

configWindow.onDragLeave = function(widget, pos)
    storage.treinarWindowPos = {x = widget:getX(), y = widget:getY()}
    return true
end

local spellEdit  = configWindow:recursiveGetChildById("spellEdit")
local restEdit   = configWindow:recursiveGetChildById("restEdit")
local manaScroll = configWindow:recursiveGetChildById("manaScroll")
local manaValue  = configWindow:recursiveGetChildById("manaValue")
local saveBtn    = configWindow:recursiveGetChildById("saveBtn")

local function updateManaLabel(value)
    manaValue:setText("Mana: " .. value .. "%")
end

spellEdit:setText(storage.treinarConfig.spell or "Power Down")
restEdit:setText(storage.treinarConfig.rest or "Chakra Rest")
manaScroll:setValue(storage.treinarConfig.manaPercent or 90)
updateManaLabel(manaScroll:getValue())

manaScroll.onValueChange = function(widget, value)
    updateManaLabel(value)
end

saveBtn.onClick = function()
    storage.treinarConfig.spell       = spellEdit:getText()
    storage.treinarConfig.rest        = restEdit:getText()
    storage.treinarConfig.manaPercent = manaScroll:getValue()
    configWindow:hide()
end

UI.Button("Configurar Treino", function()
    spellEdit:setText(storage.treinarConfig.spell or "Power Down")
    restEdit:setText(storage.treinarConfig.rest or "Chakra Rest")
    manaScroll:setValue(storage.treinarConfig.manaPercent or 90)
    updateManaLabel(manaScroll:getValue())
    if storage.treinarWindowPos then
        configWindow:setPosition(storage.treinarWindowPos)
    end
    configWindow:show()
    configWindow:raise()
end)

local restCheckBox = setupUI([[
CheckBox
  font: cipsoftFont
  text: Ativar Rest
]], panel)

restCheckBox.onCheckChange = function(widget, checked)
    storage.treinarConfig.useRest = checked
end

if storage.treinarConfig.useRest == nil then
    storage.treinarConfig.useRest = false
end

restCheckBox:setChecked(storage.treinarConfig.useRest)

macro(100, "Treinar", function()
    local spell       = storage.treinarConfig.spell or "Power Down"
    local rest        = storage.treinarConfig.rest  or "Chakra Rest"
    local manaPercent = storage.treinarConfig.manaPercent or 90
    local useRest     = storage.treinarConfig.useRest

    if manapercent() >= manaPercent then
        say(spell)
    elseif useRest then
        say(rest)
    end
end)