UI.Separator()

storage = storage or {}
storage.treinarConfig = storage.treinarConfig or {}
storage.scrollBars    = storage.scrollBars    or {}

local windowUI = [[
UIWidget
  id: treinarWindow
  size: 240 240
  @onEscape: self:hide()
  focusable: true
  phantom: false
  draggable: true
  border-width: 1
  border-color: #DDAA00
  background-color: #000000CC

  Panel
    id: titleBar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 30
    background-color: #00000000

    Label
      id: titleLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      text: TREINAR
      color: #DDAA00
      font: verdana-11px-rounded

    Label
      id: statusDot
      anchors.right: statusLabel.left
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 4
      text: •
      color: #AA4444
      font: verdana-11px-rounded
      text-auto-resize: true

    Label
      id: statusLabel
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 10
      text: INATIVO
      color: #AA4444
      font: verdana-11px-rounded
      text-auto-resize: true

  UIWidget
    id: divider
    anchors.top: titleBar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #444444

  Label
    id: spellLabel
    anchors.top: divider.bottom
    anchors.left: parent.left
    margin-top: 8
    margin-left: 8
    text: SPELL NAME
    color: #888888
    font: verdana-11px-rounded
    text-auto-resize: true

  TextEdit
    id: spellEdit
    anchors.top: spellLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 2
    margin-left: 6
    margin-right: 6
    height: 22
    background-color: #00000000
    image-color: #00000000
    border-width: 1
    border-color: #DDAA00
    color: #FFFFFF
    font: verdana-11px-rounded

  Label
    id: restLabel
    anchors.top: spellEdit.bottom
    anchors.left: parent.left
    margin-top: 8
    margin-left: 8
    text: REST SPELL
    color: #888888
    font: verdana-11px-rounded
    text-auto-resize: true

  TextEdit
    id: restEdit
    anchors.top: restLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 2
    margin-left: 6
    margin-right: 6
    height: 22
    background-color: #00000000
    image-color: #00000000
    border-width: 1
    border-color: #DDAA00
    color: #FFFFFF
    font: verdana-11px-rounded

  CheckBox
    id: restCheck
    anchors.top: restEdit.bottom
    anchors.left: parent.left
    margin-top: 8
    margin-left: 8
    text: ATIVAR REST
    color: #FFFFFF
    font: verdana-11px-rounded

  Label
    id: manaLabel
    anchors.top: restCheck.bottom
    anchors.left: parent.left
    margin-top: 10
    margin-left: 8
    text: MANA % MINIMA
    color: #888888
    font: verdana-11px-rounded
    text-auto-resize: true

  Label
    id: manaValue
    anchors.top: restCheck.bottom
    anchors.right: parent.right
    margin-top: 10
    margin-right: 8
    color: #DDAA00
    font: verdana-11px-rounded
    text-auto-resize: true

  HorizontalScrollBar
    id: manaScroll
    anchors.top: manaLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 4
    margin-left: 6
    margin-right: 6
    height: 14
    minimum: 1
    maximum: 100
    step: 1

  UIWidget
    id: divider2
    anchors.top: manaScroll.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 12
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #444444

  UIWidget
    id: saveBtn
    anchors.top: divider2.bottom
    anchors.left: parent.left
    anchors.right: activateBtn.left
    margin-top: 6
    margin-left: 6
    margin-right: 4
    height: 20
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text: SALVAR
    text-align: center
    focusable: true

  UIWidget
    id: activateBtn
    anchors.top: divider2.bottom
    anchors.right: parent.right
    margin-top: 6
    margin-right: 6
    width: 75
    height: 20
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text: ATIVAR
    text-align: center
    focusable: true
]]

local root = g_ui.getRootWidget()
local configWindow = setupUI(windowUI, root)
configWindow:hide()
configWindow:setPosition({
    x = root:getWidth()  / 2 - 120,
    y = root:getHeight() / 2 - 145
})

storage.treinarWindowPos = storage.treinarWindowPos or nil

configWindow.onDragEnter = function(widget, mousePos)
    if modules and modules.corelib and modules.corelib.g_keyboard and not modules.corelib.g_keyboard.isCtrlPressed() then return false end
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

local spellEdit   = configWindow.spellEdit
local restEdit    = configWindow.restEdit
local restCheck   = configWindow.restCheck
local manaScroll  = configWindow.manaScroll
local manaValue   = configWindow.manaValue
local saveBtn     = configWindow.saveBtn
local activateBtn = configWindow.activateBtn
local statusLabel = configWindow.titleBar.statusLabel
local statusDot   = configWindow.titleBar.statusDot

local parentPanel = panel or root

local configBtn = setupUI([[
Button
  height: 17
  text: Config
]], parentPanel)

local treinarMacro = macro(100, "Treinar", function()
    if not storage.treinarConfig.macroActive then return end

    local spell       = storage.treinarConfig.spell or "Power Down"
    local rest        = storage.treinarConfig.rest  or "Chakra Rest"
    local manaPercent = storage.treinarConfig.manaPercent or 90
    local useRest     = storage.treinarConfig.useRest

    if manapercent and manapercent() >= manaPercent then
        say(spell)
    elseif useRest then
        say(rest)
    end
end)

local function setActive(value)
    storage.treinarConfig.macroActive = value
    treinarMacro:setOn(value)
    if value then
        statusLabel:setText("ATIVO")
        statusLabel:setColor("#44CC44")
        statusDot:setColor("#44CC44")
        activateBtn:setText("DESATIVAR")
    else
        treinarMacro:setOff()
        statusLabel:setText("INATIVO")
        statusLabel:setColor("#AA4444")
        statusDot:setColor("#AA4444")
        activateBtn:setText("ATIVAR")
    end
end

treinarMacro.onClick = function()
    setActive(not storage.treinarConfig.macroActive)
end

local function updateManaLabel(value)
    manaValue:setText(value .. "%")
end

spellEdit:setText(storage.treinarConfig.spell or "Power Down")
restEdit:setText(storage.treinarConfig.rest or "Chakra Rest")
manaScroll:setValue(storage.treinarConfig.manaPercent or 90)
updateManaLabel(manaScroll:getValue())

if storage.treinarConfig.useRest == nil then
    storage.treinarConfig.useRest = false
end
restCheck:setChecked(storage.treinarConfig.useRest)

if storage.treinarConfig.macroActive == nil then
    storage.treinarConfig.macroActive = false
end

setActive(storage.treinarConfig.macroActive)

manaScroll.onValueChange = function(widget, value)
    updateManaLabel(value)
end

restCheck.onCheckChange = function(widget, checked)
    storage.treinarConfig.useRest = checked
end

saveBtn.onClick = function()
    storage.treinarConfig.spell       = spellEdit:getText()
    storage.treinarConfig.rest        = restEdit:getText()
    storage.treinarConfig.manaPercent = manaScroll:getValue()
    storage.treinarConfig.useRest     = restCheck:isChecked()
    configWindow:hide()
end

activateBtn.onClick = function()
    setActive(not storage.treinarConfig.macroActive)
end

configBtn.onClick = function()
    spellEdit:setText(storage.treinarConfig.spell or "Power Down")
    restEdit:setText(storage.treinarConfig.rest or "Chakra Rest")
    manaScroll:setValue(storage.treinarConfig.manaPercent or 90)
    updateManaLabel(manaScroll:getValue())
    restCheck:setChecked(storage.treinarConfig.useRest or false)
    if storage.treinarWindowPos then
        configWindow:setPosition(storage.treinarWindowPos)
    end
    configWindow:show()
    configWindow:raise()
end