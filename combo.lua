panel = mainTab

local SAVE_DIR  = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/combo/"
local SAVE_FILE = SAVE_DIR .. player:getName() .. ".json"

if not g_resources.directoryExists(SAVE_DIR) then
  g_resources.makeDir(SAVE_DIR)
end

local allConfigs = {}

local function newProfile(name)
  return {name = name, spells = {}, stopKey = ""}
end

local currentProfileIndex = 1
local config = {}
local currentPlayerName = player:getName()

local saveConfig         = function() end
local savePlayerConfigs  = function() end
local loadPlayerConfigs  = function() return {} end
local rebuildProfileList = function() end
local switchProfile      = function() end

local function tableSize(t)
  local n = 0
  for _ in pairs(t) do n = n + 1 end
  return n
end

local comboContext = setupUI([[
Panel
  height: 17
  BotSwitch
    id: macro
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Combo')
  Button
    id: configs
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Config
]])

local rec = "recursiveGetChildById"
local battlePanel = g_ui.getRootWidget()[rec](g_ui.getRootWidget(), "battlePanel")
local gameRoot    = g_ui.getRootWidget()[rec](g_ui.getRootWidget(), "gameRootPanel")

comboContext.window = setupUI([[
MainWindow
  !text: tr('Combo - Configuracao')
  size: 620 500
  Panel
    id: mainPanel
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.fill: parent
    margin: 5
    ComboBox
      id: playerList
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      margin: 5 5 0 5
      height: 20
    Panel
      id: profileBar
      anchors.top: playerList.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 28
      margin: 4 5 0 5
      image-source: /images/ui/panel_flat
      image-border: 4
      Label
        text: Perfil:
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 6
        text-auto-resize: true
      ComboBox
        id: configList
        anchors.left: prev.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 4
        width: 150
        height: 20
      Button
        id: addProfile
        text: +
        anchors.left: configList.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 5
        width: 22
        height: 20
      Button
        id: removeProfile
        text: -
        anchors.left: addProfile.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 3
        width: 22
        height: 20
      Label
        text: Nome:
        anchors.left: removeProfile.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 10
        text-auto-resize: true
      TextEdit
        id: profileName
        anchors.left: prev.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 4
        height: 20
        width: 110
    Panel
      id: listButtons
      anchors.top: profileBar.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 24
      margin: 3 5 0 5
      Button
        id: moveUp
        text: Cima
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 65
        height: 20
      Button
        id: moveDown
        text: Baixo
        anchors.left: moveUp.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 5
        width: 65
        height: 20
    TextList
      id: comboList
      anchors.top: listButtons.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: addPanel.top
      margin: 3 5 3 5
      image-border: 3
      image-source: /images/ui/textedit
      vertical-scrollbar: comboListScroll
    VerticalScrollBar
      id: comboListScroll
      anchors.top: comboList.top
      anchors.bottom: comboList.bottom
      anchors.right: comboList.right
      step: 10
      pixels-scroll: true
    Panel
      id: addPanel
      anchors.bottom: actionPanel.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 78
      margin: 0 5 3 5
      image-source: /images/ui/panel_flat
      image-border: 4
      Label
        text: -- Adicionar Magia --
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 14
        margin: 4 0 0 0
        text-align: center
        font: verdana-11px-rounded
      Label
        id: lblSpell
        text: Nome da Magia:
        anchors.top: prev.bottom
        anchors.left: parent.left
        margin: 5 0 0 8
        text-auto-resize: true
      TextEdit
        id: spellName
        anchors.top: lblSpell.bottom
        anchors.left: parent.left
        margin: 2 0 0 8
        height: 21
        width: 160
      Label
        id: lblCooldown
        text: Cooldown (s):
        anchors.top: lblSpell.top
        anchors.left: spellName.right
        margin: 0 0 0 12
        text-auto-resize: true
      HorizontalScrollBar
        id: cooldownScroll
        anchors.top: spellName.top
        anchors.left: spellName.right
        margin: 2 0 0 12
        width: 90
        height: 15
        step: 1
      Label
        id: lblDistance
        text: Distancia:
        anchors.top: lblSpell.top
        anchors.left: cooldownScroll.right
        margin: 0 0 0 12
        text-auto-resize: true
      HorizontalScrollBar
        id: distanceScroll
        anchors.top: spellName.top
        anchors.left: cooldownScroll.right
        margin: 2 0 0 12
        width: 75
        height: 15
        step: 1
      Label
        id: lblStopKey
        text: Tecla Parar:
        anchors.top: lblSpell.top
        anchors.left: distanceScroll.right
        margin: 0 0 0 12
        text-auto-resize: true
      TextEdit
        id: stopKey
        anchors.top: lblStopKey.bottom
        anchors.left: distanceScroll.right
        margin: 3 0 0 12
        height: 21
        width: 75
      Label
        id: stopKeyLabel
        anchors.centerIn: stopKey
        text-auto-resize: true
    Panel
      id: actionPanel
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 35
      margin: 0 5 5 5
      image-source: /images/ui/panel_flat
      image-border: 4
      Button
        id: addButton
        text: + Add
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 6
        width: 70
        height: 22
      Button
        id: findCDButton
        text: CD
        anchors.left: addButton.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 4
        width: 40
        height: 22
      Button
        id: testComboButton
        text: Testar
        anchors.left: findCDButton.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 4
        width: 55
        height: 22
      Button
        id: pvpButton
        text: PvP
        anchors.left: testComboButton.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 4
        width: 40
        height: 22
      Button
        id: exportButton
        text: Exportar
        anchors.left: pvpButton.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 4
        width: 65
        height: 22
      Button
        id: importButton
        text: Importar
        anchors.left: exportButton.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 4
        width: 65
        height: 22
      Label
        id: displayLabel
        text: .
        anchors.left: importButton.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 6
        text-auto-resize: true
      Button
        id: closeButton
        text: Fechar
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        margin-right: 6
        width: 60
        height: 22
]], g_ui.getRootWidget())

local mp = comboContext.window.mainPanel
comboContext.mainPanel                 = mp
comboContext.mainPanel.comboList       = mp.comboList
comboContext.mainPanel.configList      = mp.profileBar.configList
comboContext.mainPanel.addProfile      = mp.profileBar.addProfile
comboContext.mainPanel.removeProfile   = mp.profileBar.removeProfile
comboContext.mainPanel.profileName     = mp.profileBar.profileName
comboContext.mainPanel.moveUp          = mp.listButtons.moveUp
comboContext.mainPanel.moveDown        = mp.listButtons.moveDown
comboContext.mainPanel.spellName       = mp.addPanel.spellName
comboContext.mainPanel.cooldownScroll  = mp.addPanel.cooldownScroll
comboContext.mainPanel.distanceScroll  = mp.addPanel.distanceScroll
comboContext.mainPanel.stopKey         = mp.addPanel.stopKey
comboContext.mainPanel.stopKeyLabel    = mp.addPanel.stopKeyLabel
comboContext.mainPanel.addButton       = mp.actionPanel.addButton
comboContext.mainPanel.findCDButton    = mp.actionPanel.findCDButton
comboContext.mainPanel.testComboButton = mp.actionPanel.testComboButton
comboContext.mainPanel.pvpButton       = mp.actionPanel.pvpButton
comboContext.mainPanel.displayLabel    = mp.actionPanel.displayLabel
comboContext.mainPanel.closeButton     = mp.actionPanel.closeButton
comboContext.mainPanel.exportButton    = mp.actionPanel.exportButton
comboContext.mainPanel.importButton    = mp.actionPanel.importButton
comboContext.mainPanel.playerList      = mp.playerList

local allPlayers = {}

local function loadPlayerConfigs(playerName)
  local file = SAVE_DIR .. playerName .. ".json"
  local cfgs = {}
  if g_resources.fileExists(file) then
    local ok, result = pcall(function() return json.decode(g_resources.readFileContents(file)) end)
    if ok and result then
      if result.profiles then cfgs = result.profiles
      elseif result.spells then cfgs = {result}; cfgs[1].name = cfgs[1].name or "Combo 1"
      elseif type(result) == "table" and result[1] then cfgs = result end
    end
  end
  if #cfgs == 0 then
    cfgs[1] = newProfile("Combo 1")
    cfgs[2] = newProfile("Combo 2")
  end
  for _, cfg in ipairs(cfgs) do
    cfg.spells  = cfg.spells  or {}
    cfg.stopKey = cfg.stopKey or ""
    for _, spell in pairs(cfg.spells) do
      if type(spell) == "table" then spell.cooldownTime = 0 end
    end
  end
  return cfgs
end

local function savePlayerConfigs(playerName, cfgs)
  local file = SAVE_DIR .. playerName .. ".json"
  local data = {player = playerName, profiles = cfgs}
  local ok, result = pcall(function() return json.encode(data, 2) end)
  if ok then g_resources.writeFileContents(file, result) end
end

local function loadPlayerConfigs_real(playerName)
  local file = SAVE_DIR .. playerName .. ".json"
  local cfgs = {}
  if g_resources.fileExists(file) then
    local ok, result = pcall(function() return json.decode(g_resources.readFileContents(file)) end)
    if ok and result then
      if result.profiles then cfgs = result.profiles
      elseif result.spells then cfgs = {result}; cfgs[1].name = cfgs[1].name or "Combo 1"
      elseif type(result) == "table" and result[1] then cfgs = result end
    end
  end
  if #cfgs == 0 then
    cfgs[1] = newProfile("Combo 1")
    cfgs[2] = newProfile("Combo 2")
  end
  for _, cfg in ipairs(cfgs) do
    cfg.spells  = cfg.spells  or {}
    cfg.stopKey = cfg.stopKey or ""
    for _, spell in pairs(cfg.spells) do
      if type(spell) == "table" then spell.cooldownTime = 0 end
    end
  end
  return cfgs
end

local function savePlayerConfigs_real(playerName, cfgs)
  local file = SAVE_DIR .. playerName .. ".json"
  local data = {player = playerName, profiles = cfgs}
  local ok, result = pcall(function() return json.encode(data, 2) end)
  if ok then g_resources.writeFileContents(file, result) end
end

loadPlayerConfigs = loadPlayerConfigs_real
savePlayerConfigs = savePlayerConfigs_real

currentPlayerName = player:getName()
allConfigs = loadPlayerConfigs(currentPlayerName)
config = allConfigs[1]

saveConfig = function()
  savePlayerConfigs(currentPlayerName, allConfigs)
end

comboContext.window:hide()
comboContext.mainPanel.displayLabel:setText("")
local rebuildProfileList
local msgOk
local msgErr

local function buildPlayerList()
  local cb = comboContext.mainPanel.playerList
  cb:clear()
  local files = g_resources.listDirectoryFiles(SAVE_DIR, false, false)
  allPlayers = {}
  for _, f in ipairs(files) do
    if f:find("%.json$") and not f:find("_pvp%.json$") and not f:find("_ranking%.txt$") then
      local name = f:gsub("%.json$", "")
      table.insert(allPlayers, name)
    end
  end
  if not table.find(allPlayers, currentPlayerName) then
    table.insert(allPlayers, currentPlayerName)
    savePlayerConfigs(currentPlayerName, allConfigs)
  end
  table.sort(allPlayers)
  for _, name in ipairs(allPlayers) do
    cb:addOption(name)
  end
  cb:setCurrentOption(currentPlayerName)
  if table.find(allPlayers, currentPlayerName) then
    allConfigs = loadPlayerConfigs(currentPlayerName)
    currentProfileIndex = 1
    config = allConfigs[1]
    schedule(1, function()
      rebuildProfileList()
      switchProfile(1)
    end)
  end
end

comboContext.mainPanel.playerList.onOptionChange = function(widget, text)
  if text == currentPlayerName then return end
  currentPlayerName = text
  allConfigs = loadPlayerConfigs(text)
  currentProfileIndex = 1
  config = allConfigs[1]
  saveConfig = function()
    savePlayerConfigs(currentPlayerName, allConfigs)
  end
  schedule(1, function()
    rebuildProfileList()
    switchProfile(1)
  end)
end

local function switchProfile(index)
  if not allConfigs[index] then return end
  currentProfileIndex = index
  config = allConfigs[index]
  local nameWidget = comboContext.mainPanel.profileName
  local stopWidget = comboContext.mainPanel.stopKey
  nameWidget.onTextChange = nil
  stopWidget.onTextChange = nil
  nameWidget:setText(config.name or "")
  stopWidget:setText(config.stopKey or "")
  nameWidget.onTextChange = function(_, text)
    allConfigs[currentProfileIndex].name = text
    rebuildProfileList()
    saveConfig()
  end
  local stopKeyLabel = comboContext.mainPanel.stopKeyLabel
  stopWidget.onTextChange = function(widget)
    widget:clearText()
  end
  stopKeyLabel:setText(allConfigs[currentProfileIndex].stopKey or "")
  schedule(1, function() comboContext.refresh() end)
end

rebuildProfileList = function()
  local cb = comboContext.mainPanel.configList
  cb:clear()
  for i, cfg in ipairs(allConfigs) do
    cb:addOption(cfg.name or ("Combo " .. i))
  end
  local current = allConfigs[currentProfileIndex]
  if current then
    cb:setCurrentOption(current.name or ("Combo " .. currentProfileIndex))
  end
end

comboContext.mainPanel.configList.onOptionChange = function(widget, text)
  for i, cfg in ipairs(allConfigs) do
    if (cfg.name or ("Combo " .. i)) == text then
      schedule(1, function() switchProfile(i) end)
      return
    end
  end
end

comboContext.mainPanel.addProfile.onClick = function()
  local name = "Combo " .. (#allConfigs + 1)
  table.insert(allConfigs, newProfile(name))
  saveConfig()
  rebuildProfileList()
  switchProfile(#allConfigs)
  msgOk("Perfil '" .. name .. "' criado!")
end

comboContext.mainPanel.removeProfile.onClick = function()
  if #allConfigs <= 1 then
    msgErr("Precisa ter ao menos 1 perfil.")
    return
  end
  table.remove(allConfigs, currentProfileIndex)
  saveConfig()
  currentProfileIndex = math.min(currentProfileIndex, #allConfigs)
  rebuildProfileList()
  switchProfile(currentProfileIndex)
  msgOk("Perfil removido.")
end

local function scrollSetup(widget, default, min, max)
  widget:setMinimum(min)
  widget:setMaximum(max)
  widget.onValueChange = function(w, v) w:setText(v) end
  widget:setValue(default)
end

scrollSetup(comboContext.mainPanel.cooldownScroll, 1, 0, 120)
scrollSetup(comboContext.mainPanel.distanceScroll, 1, 1, 20)

local function showMsg(text, color)
  local lbl = comboContext.mainPanel.displayLabel
  local token = now + 2500
  lbl._token = token
  lbl:setText(text)
  lbl:setColor(color)
  schedule(2500, function()
    if lbl._token ~= token then return end
    lbl:setText("")
  end)
end

msgOk  = function(t) showMsg(t, {r=0,   g=220, b=0,   a=255}) end
msgErr = function(t) showMsg(t, {r=255, g=0,   b=0,   a=255}) end

local spellEntry = [[
Label
  background-color: alpha
  text-offset: 18 5
  focusable: true
  height: 20
  font: verdana-11px-rounded
  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-left: 3
  $focus:
    background-color: #00000055
  Button
    id: remove
    text: x
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 8
    text-offset: 1 0
    width: 13
    height: 13
]]

local function hasPreviousChild(label)
  if label.index == 0 then return true end
  for _, v in pairs(config.spells) do
    if type(v) == "table" and v.index == label.index - 1 then return true end
  end
end

local function gameFocus()
  if gameRoot then gameRoot:focus() end
end

comboContext.convertedSpells = {}

function comboContext.refresh()
  for _, child in ipairs(comboContext.mainPanel.comboList:getChildren()) do
    child:destroy()
  end
  comboContext.convertedSpells = {}

  for key, label in pairs(config.spells) do
    if type(label) ~= "table" or not label.cooldown then goto continue end
    if not hasPreviousChild(label) then
      config.spells[key].index = label.index - 1
      return comboContext.refresh()
    end
    table.insert(comboContext.convertedSpells, {
      spellName = label.spellName,
      castKey   = key,
      distance  = label.distance,
      enabled   = label.enabled,
      index     = label.index,
      cooldown  = label.cooldown,
    })
    ::continue::
  end

  table.sort(comboContext.convertedSpells, function(a, b) return a.index < b.index end)

  comboContext.mainPanel.moveDown:setEnabled(false)
  comboContext.mainPanel.moveUp:setEnabled(false)

  for idx, v in ipairs(comboContext.convertedSpells) do
    local label   = config.spells[v.castKey]
    local widget  = setupUI(spellEntry, comboContext.mainPanel.comboList)
    local castKey = v.castKey

    widget.castKey = castKey

    local src = label.cdSource == "measured" and "auto" or "man"
    widget:setText(string.format(" %s  cd:%ds[%s]  dist:%d",
      label.spellName, label.cooldown, src, label.distance))

    widget:setTooltip(string.format(
      "Magia: %s\nCooldown: %ds [%s]\nDistance: %d tiles\nAtivo: %s",
      label.spellName,
      label.cooldown,
      label.cdSource == "measured" and "detectado auto" or "manual",
      label.distance,
      label.enabled ~= false and "sim" or "nao"))

    widget.onFocusChange = function(w, focused)
      if focused then
        comboContext.focusedChild = w
        comboContext.mainPanel.moveUp:setEnabled(idx > 1)
        comboContext.mainPanel.moveDown:setEnabled(idx < #comboContext.convertedSpells)
      else
        schedule(1, function()
          if comboContext.focusedChild == w then
            comboContext.focusedChild = nil
            comboContext.mainPanel.moveUp:setEnabled(false)
            comboContext.mainPanel.moveDown:setEnabled(false)
          end
        end)
      end
    end

    widget.onDoubleClick = function()
      config.spells[castKey] = nil
      comboContext.mainPanel.spellName:setText(label.spellName)
      comboContext.mainPanel.cooldownScroll:setValue(label.cooldown)
      comboContext.mainPanel.distanceScroll:setValue(label.distance)
      saveConfig()
      msgOk("Magia removida para edicao.")
      comboContext.refresh()
    end

    widget.enabled:setChecked(label.enabled ~= false)
    widget.enabled.onCheckChange = function(_, checked)
      label.enabled = checked
      saveConfig()
    end

    widget.remove.onClick = function()
      config.spells[castKey] = nil
      saveConfig()
      msgOk("Magia removida.")
      comboContext.refresh()
    end
  end
end

macro(500, function()
  if comboContext.window:isHidden() then return end
  local children = comboContext.mainPanel.comboList:getChildren()
  for idx, v in ipairs(comboContext.convertedSpells) do
    local spell  = config.spells[v.castKey]
    local widget = children[idx]
    if not spell or not widget then goto nextSpell end
    local src = spell.cdSource == "measured" and "auto" or "man"
    local remaining = (spell.cooldownTime or 0) > now
                      and math.ceil((spell.cooldownTime - now) / 1000) or 0
    if remaining > 0 then
      widget:setText(string.format(" %s  cd:%ds[%s]  dist:%d  [%ds]",
        spell.spellName, spell.cooldown, src, spell.distance, remaining))
      widget:setColor({r=255, g=100, b=100, a=255})
    else
      widget:setText(string.format(" %s  cd:%ds[%s]  dist:%d",
        spell.spellName, spell.cooldown, src, spell.distance))
      widget:setColor({r=200, g=200, b=200, a=255})
    end
    ::nextSpell::
  end
end)

comboContext.mainPanel.addButton.onClick = function()
  local spell    = comboContext.mainPanel.spellName:getText():lower():trim()
  local cooldown = tonumber(comboContext.mainPanel.cooldownScroll:getValue())
  local distance = tonumber(comboContext.mainPanel.distanceScroll:getValue())

  if #spell == 0 then return msgErr("Insira o nome da magia.") end
  if config.spells[spell] then return msgErr("Magia ja adicionada.") end

  config.spells[spell] = {
    spellName    = spell,
    distance     = distance,
    cooldown     = cooldown,
    cdSource     = "manual",
    enabled      = true,
    index        = tableSize(config.spells),
    cooldownTime = 0,
  }

  comboContext.mainPanel.spellName:setText("")
  comboContext.mainPanel.cooldownScroll:setValue(1)
  comboContext.mainPanel.distanceScroll:setValue(1)
  saveConfig()
  msgOk("Magia adicionada!")
  comboContext.refresh()
end

comboContext.mainPanel.moveUp.onClick = function()
  local child = comboContext.focusedChild
  if not child then return end
  local key = child.castKey
  local val = config.spells[key]
  if val.index == 0 then return end
  for k, v in pairs(config.spells) do
    if type(v) == "table" and v.index == val.index - 1 then
      config.spells[k].index = val.index
      break
    end
  end
  config.spells[key].index = val.index - 1
  saveConfig()
  comboContext.refresh()
end

comboContext.mainPanel.moveDown.onClick = function()
  local child = comboContext.focusedChild
  if not child then return end
  local key = child.castKey
  local val = config.spells[key]
  for k, v in pairs(config.spells) do
    if type(v) == "table" and v.index == val.index + 1 then
      config.spells[k].index = val.index
      break
    end
  end
  config.spells[key].index = val.index + 1
  saveConfig()
  comboContext.refresh()
end

local function encodeProfile(cfg)
  local data = {name = cfg.name, spells = cfg.spells, stopKey = cfg.stopKey}
  local ok, result = pcall(function() return json.encode(data) end)
  if not ok then return nil end
  local encoded = ""
  for i = 1, #result do
    encoded = encoded .. string.format("%02x", string.byte(result, i))
  end
  return encoded
end

local function decodeProfile(code)
  code = code:trim()
  if #code == 0 or #code % 2 ~= 0 then return nil end
  local result = ""
  for i = 1, #code, 2 do
    local byte = tonumber(code:sub(i, i+1), 16)
    if not byte then return nil end
    result = result .. string.char(byte)
  end
  local ok, data = pcall(function() return json.decode(result) end)
  if not ok or type(data) ~= "table" then return nil end
  return data
end

local exportWindow = setupUI([[
MainWindow
  !text: tr('Exportar Perfil')
  size: 480 175
  Panel
    id: panel
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.fill: parent
    margin: 5
    Label
      id: instrLabel
      text: Codigo do perfil atual — copie e envie para outro jogador:
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 16
      margin: 10 8 0 8
      text-align: center
      font: verdana-11px-rounded
    TextEdit
      id: codeBox
      anchors.top: instrLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin: 8 8 0 8
      height: 55
    Panel
      id: btnRow
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 32
      margin: 0 5 5 5
      image-source: /images/ui/panel_flat
      image-border: 4
      Button
        id: copyBtn
        text: Copiar Codigo
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 8
        width: 105
        height: 22
      Label
        id: statusLabel
        text: .
        anchors.left: copyBtn.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 10
        text-auto-resize: true
      Button
        id: closeBtn
        text: Fechar
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        margin-right: 8
        width: 65
        height: 22
]], g_ui.getRootWidget())

exportWindow:hide()
local exportPanel = exportWindow.panel

local function exportStatus(text, color)
  local lbl = exportPanel.btnRow.statusLabel
  local token = now + 2500
  lbl._token = token
  lbl:setText(text)
  lbl:setColor(color or {r=255,g=255,b=255,a=255})
  schedule(2500, function()
    if lbl._token ~= token then return end
    lbl:setText("")
  end)
end

exportPanel.btnRow.copyBtn.onClick = function()
  local code = exportPanel.codeBox:getText()
  if #code == 0 then return end
  g_window.setClipboardText(code)
  exportStatus("Copiado!", {r=0,g=220,b=0,a=255})
end

exportPanel.btnRow.closeBtn.onClick = function()
  exportWindow:hide()
  gameFocus()
end
exportWindow.onEscape = exportPanel.btnRow.closeBtn.onClick

comboContext.mainPanel.exportButton.onClick = function()
  local code = encodeProfile(config)
  if not code then
    msgErr("Erro ao exportar perfil.")
    return
  end
  exportPanel.codeBox:setText(code)
  exportPanel.btnRow.statusLabel:setText("")
  exportWindow:show()
  exportWindow:raise()
  exportWindow:focus()
end

local importWindow = setupUI([[
MainWindow
  !text: tr('Importar Perfil')
  size: 480 175
  Panel
    id: panel
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.fill: parent
    margin: 5
    Label
      id: instrLabel
      text: Cole o codigo recebido abaixo e clique em Importar:
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      height: 16
      margin: 10 8 0 8
      text-align: center
      font: verdana-11px-rounded
    TextEdit
      id: codeBox
      anchors.top: instrLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin: 8 8 0 8
      height: 55
    Panel
      id: btnRow
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 32
      margin: 0 5 5 5
      image-source: /images/ui/panel_flat
      image-border: 4
      Button
        id: pasteBtn
        text: Colar
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 8
        width: 60
        height: 22
      Button
        id: importBtn
        text: Importar
        anchors.left: pasteBtn.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 5
        width: 65
        height: 22
      Label
        id: statusLabel
        text: .
        anchors.left: importBtn.right
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 10
        text-auto-resize: true
      Button
        id: closeBtn
        text: Fechar
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        margin-right: 8
        width: 65
        height: 22
]], g_ui.getRootWidget())

importWindow:hide()
local importPanel = importWindow.panel

local function importStatus(text, color)
  local lbl = importPanel.btnRow.statusLabel
  local token = now + 2500
  lbl._token = token
  lbl:setText(text)
  lbl:setColor(color or {r=255,g=255,b=255,a=255})
  schedule(2500, function()
    if lbl._token ~= token then return end
    lbl:setText("")
  end)
end

importPanel.btnRow.pasteBtn.onClick = function()
  local text = g_window.getClipboardText()
  if text and #text:trim() > 0 then
    importPanel.codeBox:setText(text:trim())
    importStatus("Colado!", {r=0,g=220,b=0,a=255})
  else
    importStatus("Clipboard vazio.", {r=255,g=100,b=0,a=255})
  end
end

importPanel.btnRow.importBtn.onClick = function()
  local code = importPanel.codeBox:getText():trim()
  if #code == 0 then
    importStatus("Cole um codigo primeiro.", {r=255,g=100,b=0,a=255})
    return
  end
  local data = decodeProfile(code)
  if not data or not data.spells then
    importStatus("Codigo invalido!", {r=255,g=0,b=0,a=255})
    return
  end
  local name = (data.name or "Importado") .. " (importado)"
  local newProfile = {
    name    = name,
    spells  = data.spells,
    stopKey = data.stopKey or "",
  }
  for _, spell in pairs(newProfile.spells) do
    if type(spell) == "table" then spell.cooldownTime = 0 end
  end
  table.insert(allConfigs, newProfile)
  saveConfig()
  rebuildProfileList()
  switchProfile(#allConfigs)
  importStatus("Perfil '" .. name .. "' importado!", {r=0,g=220,b=0,a=255})
  msgOk("Perfil importado!")
end

importPanel.btnRow.closeBtn.onClick = function()
  importWindow:hide()
  gameFocus()
end
importWindow.onEscape = importPanel.btnRow.closeBtn.onClick

comboContext.mainPanel.importButton.onClick = function()
  importPanel.codeBox:setText("")
  importPanel.btnRow.statusLabel:setText("")
  importWindow:show()
  importWindow:raise()
  importWindow:focus()
  importPanel.codeBox:focus()
end

comboContext.mainPanel.closeButton.onClick = function()
  comboContext.window:hide()
  gameFocus()
end
comboContext.window.onEscape = comboContext.mainPanel.closeButton.onClick

onKeyDown(function(key)
  if comboContext.window:isHidden() then return end
  if not comboContext.mainPanel.stopKey:isFocused() then return end
  local stopKeyLabel = comboContext.mainPanel.stopKeyLabel
  if key == "Escape" then
    stopKeyLabel:clearText()
    allConfigs[currentProfileIndex].stopKey = ""
  else
    stopKeyLabel:setText(key)
    allConfigs[currentProfileIndex].stopKey = key
  end
  saveConfig()
end)

comboContext.configs.onClick = function()
  if comboContext.window:isHidden() then
    comboContext.window:show()
    comboContext.window:raise()
    comboContext.window:focus()
  else
    comboContext.window:hide()
    gameFocus()
  end
end

rebuildProfileList()
switchProfile(1)
buildPlayerList()

if storage.comboMacro == nil then storage.comboMacro = false end

local comboMacro = comboContext.macro
comboMacro:setOn(storage.comboMacro)

local function getTarget()
  local myPos = pos()
  if battlePanel then
    for _, child in pairs(battlePanel:getChildren()) do
      if child.creature then
        local cp = child.creature:getPosition()
        if cp and cp.z == myPos.z then
          if table.find({"#FF8888", "#FF0000"}, child.color) then
            return child.creature
          end
        end
      end
    end
  end
  for key, func in pairs(g_game) do
    if key:lower():find("getatt") then
      local ok, result = pcall(function() return func():getId() end)
      if ok then
        local c = getCreatureById(result)
        if c then return c end
      end
    end
  end
end

local stoppedByKey = false

local PVP_FILE = SAVE_DIR .. player:getName() .. "_pvp.json"

local pvpConfig = {profiles = {}, friends = {}}
if g_resources.fileExists(PVP_FILE) then
  local ok, result = pcall(function() return json.decode(g_resources.readFileContents(PVP_FILE)) end)
  if ok and result then
    pvpConfig = result
    pvpConfig.profiles = pvpConfig.profiles or {}
    pvpConfig.friends  = pvpConfig.friends  or {}
    for _, profile in ipairs(pvpConfig.profiles) do
      for _, spell in ipairs(profile.spells or {}) do
        spell.cooldownTime = 0
      end
    end
  end
end

local function savePvpConfig()
  local ok, result = pcall(function() return json.encode(pvpConfig, 2) end)
  if ok then g_resources.writeFileContents(PVP_FILE, result) end
end

local function isFriend(name)
  name = name:lower()
  for _, f in ipairs(pvpConfig.friends) do
    if f:lower() == name then return true end
  end
  return false
end

local attackers = {}

local function countAttackingPlayers()
  local currentTime = now
  local timeoutMs = (pvpPanel and pvpPanel.bottomRow and pvpPanel.bottomRow.timeoutScroll:getValue() or 5) * 1000
  for _, spec in ipairs(getSpectators(false)) do
    if spec:isPlayer() and spec:getId() ~= player:getId() then
      if spec:isTimedSquareVisible() and not isFriend(spec:getName()) then
        attackers[spec:getName()] = currentTime + timeoutMs
      end
    end
  end
  local count = 0
  for name, expiry in pairs(attackers) do
    if expiry > currentTime then
      count = count + 1
    else
      attackers[name] = nil
    end
  end
  return count
end

local function getActiveProfile(playerCount)
  local best = nil
  for _, profile in ipairs(pvpConfig.profiles) do
    if profile.enabled and playerCount >= profile.minPlayers then
      if not best or profile.minPlayers > best.minPlayers then
        best = profile
      end
    end
  end
  return best
end

comboContext.executeMacro = macro(50, function()
  if storage.pvpMacro and countAttackingPlayers() > 0 then return end

  if config.stopKey and #config.stopKey > 0 then
    if g_keyboard.isKeyPressed(config.stopKey) then
      if not stoppedByKey then
        stoppedByKey = true
        for _, spell in pairs(config.spells) do
          if type(spell) == "table" then spell.cooldownTime = 0 end
        end
      end
      return
    else
      stoppedByKey = false
    end
  end

  if stoppedByKey then return end

  local target = getTarget()
  if not target then return end

  local targetPos = target:getPosition()
  if not targetPos then return end

  local distance = getDistanceBetween(targetPos, pos())

  for _, entry in ipairs(comboContext.convertedSpells) do
    local spellData = config.spells[entry.castKey]
    if spellData and spellData.enabled then
      if (spellData.cooldownTime or 0) <= now then
        if distance <= spellData.distance then
          say(spellData.spellName)
        end
      end
    end
  end
end)

function comboMacro.onClick()
  storage.comboMacro = not storage.comboMacro
  comboMacro:setOn(storage.comboMacro)
  comboContext.executeMacro.setOn(storage.comboMacro)
  if not storage.comboMacro then
    for _, spell in pairs(config.spells) do
      if type(spell) == "table" then spell.cooldownTime = 0 end
    end
  end
end

onTalk(function(name, level, mode, text)
  if player:getName() ~= name then return end
  text = text:lower():trim()

  for key, spell in pairs(config.spells) do
    if type(spell) == "table" and spell.spellName == text then
      spell.cooldownTime = now + (spell.cooldown * 1000)
      break
    end
  end

  if detectCD then
    local detectSpell = cdPanel.spellInput:getText():lower():trim()
    if text == detectSpell then
      if spellTime[2] == detectSpell then
        local measuredMs  = now - spellTime[1]
        local measuredSec = math.max(1, math.ceil(measuredMs / 1000))
        comboContext.mainPanel.cooldownScroll:setValue(measuredSec)
        spellTime = {now, detectSpell}
        stopDetect()
        cdPanel.importButton:setEnabled(true)
        cdPanel.statusLabel:setColor({r=0, g=220, b=0, a=255})
        cdPanel.statusLabel:setText("CD detectado: " .. measuredSec .. "s!")
        msgOk("CD de '" .. detectSpell .. "' detectado: " .. measuredSec .. "s")
      else
        spellTime = {now, detectSpell}
        cdPanel.statusLabel:setText("1a vez OK, aguardando 2a...")
      end
    end
  end

  if storage.pvpMacro then
    for _, profile in ipairs(pvpConfig.profiles) do
      for _, spell in ipairs(profile.spells or {}) do
        if spell.spellName == text then
          spell.cooldownTime = now + (spell.cooldown * 1000)
        end
      end
    end
  end
end)

local detectCD  = false
local testSpell = false
local spellTime = {0, ""}
local cdPanel   = nil
local stopDetect = function() end

onTalk(function(name, level, mode, text)
  if player:getName() ~= name then return end
  text = text:lower():trim()

  for key, spell in pairs(config.spells) do
    if type(spell) == "table" and spell.spellName == text then
      spell.cooldownTime = now + (spell.cooldown * 1000)
      break
    end
  end

  if detectCD and cdPanel then
    local detectSpell = cdPanel.spellInput:getText():lower():trim()
    if text == detectSpell then
      if spellTime[2] == detectSpell then
        local measuredMs  = now - spellTime[1]
        local measuredSec = math.max(1, math.ceil(measuredMs / 1000))
        comboContext.mainPanel.cooldownScroll:setValue(measuredSec)
        spellTime = {now, detectSpell}
        detectCD  = false
        testSpell = false
        cdPanel.startButton:setEnabled(true)
        cdPanel.stopButton:setEnabled(false)
        cdPanel.importButton:setEnabled(true)
        cdPanel.statusLabel:setColor({r=0, g=220, b=0, a=255})
        cdPanel.statusLabel:setText("CD detectado: " .. measuredSec .. "s!")
        msgOk("CD de '" .. detectSpell .. "' detectado: " .. measuredSec .. "s")
      else
        spellTime = {now, detectSpell}
        cdPanel.statusLabel:setText("1a vez OK, aguardando 2a...")
      end
    end
  end

  if storage.pvpMacro then
    for _, profile in ipairs(pvpConfig.profiles) do
      for _, spell in ipairs(profile.spells or {}) do
        if spell.spellName == text then
          spell.cooldownTime = now + (spell.cooldown * 1000)
        end
      end
    end
  end
end)

local cdWindow = setupUI([[
MainWindow
  !text: tr('Detectar Cooldown')
  size: 320 160
  Panel
    id: panel
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.top: parent.top
    anchors.left: parent.left
    size: 280 115
    Label
      id: lblSpell
      text: Nome da Magia
      anchors.top: parent.top
      anchors.left: parent.left
      margin-top: 10
      margin-left: 15
    TextEdit
      id: spellInput
      anchors.top: lblSpell.bottom
      anchors.left: parent.left
      margin-top: 3
      margin-left: 15
      height: 21
      width: 140
    Label
      id: lblDistance
      text: Distance
      anchors.top: parent.top
      anchors.left: spellInput.right
      margin-top: 10
      margin-left: 10
    HorizontalScrollBar
      id: distanceInput
      anchors.top: lblDistance.bottom
      anchors.left: spellInput.right
      margin-top: 3
      margin-left: 10
      width: 80
      step: 1
    Label
      id: statusLabel
      text: Aguardando...
      anchors.top: spellInput.bottom
      anchors.left: parent.left
      margin-top: 8
      margin-left: 15
      text-auto-resize: true
    Button
      id: startButton
      text: Iniciar
      anchors.top: statusLabel.bottom
      anchors.left: parent.left
      margin-top: 8
      margin-left: 15
      width: 50
      height: 20
    Button
      id: stopButton
      text: Parar
      anchors.top: startButton.top
      anchors.left: startButton.right
      margin-left: 5
      width: 50
      height: 20
    Button
      id: importButton
      text: Importar
      anchors.top: startButton.top
      anchors.left: stopButton.right
      margin-left: 5
      width: 60
      height: 20
    Button
      id: closeBtn
      text: Fechar
      anchors.top: startButton.top
      anchors.left: importButton.right
      margin-left: 5
      width: 50
      height: 20
]], g_ui.getRootWidget())

cdWindow:hide()
cdPanel = cdWindow.panel

local function cdScrollSetup(widget, default, min, max)
  widget:setMinimum(min)
  widget:setMaximum(max)
  widget.onValueChange = function(w, v) w:setText(v) end
  widget:setValue(default)
end
cdScrollSetup(cdPanel.distanceInput, 1, 1, 20)

cdPanel.stopButton:setEnabled(false)
cdPanel.importButton:setEnabled(false)

local function stopDetect()
  detectCD  = false
  testSpell = false
  spellTime = {0, ""}
  cdPanel.startButton:setEnabled(true)
  cdPanel.stopButton:setEnabled(false)
  cdPanel.importButton:setEnabled(false)
  cdPanel.statusLabel:setColor({r=255, g=255, b=255, a=255})
end

cdPanel.importButton.onClick = function()
  local spell    = cdPanel.spellInput:getText():lower():trim()
  local cooldown = comboContext.mainPanel.cooldownScroll:getValue()
  local distance = cdPanel.distanceInput:getValue()

  if #spell == 0 then
    cdPanel.statusLabel:setText("Digite o nome da magia!")
    cdPanel.statusLabel:setColor({r=255, g=0, b=0, a=255})
    return
  end
  if config.spells[spell] then
    cdPanel.statusLabel:setText("Magia ja existe no combo!")
    cdPanel.statusLabel:setColor({r=255, g=150, b=0, a=255})
    return
  end

  config.spells[spell] = {
    spellName    = spell,
    distance     = distance,
    cooldown     = cooldown,
    cdSource     = "measured",
    enabled      = true,
    index        = tableSize(config.spells),
    cooldownTime = 0,
  }

  saveConfig()
  comboContext.refresh()
  cdPanel.statusLabel:setText("Importado com cd:" .. cooldown .. "s!")
  cdPanel.statusLabel:setColor({r=0, g=220, b=0, a=255})
  cdPanel.importButton:setEnabled(false)
end

cdPanel.closeBtn.onClick = function()
  stopDetect()
  cdWindow:hide()
end
cdWindow.onEscape = cdPanel.closeBtn.onClick

cdPanel.stopButton.onClick = function()
  stopDetect()
  cdPanel.statusLabel:setText("Parado.")
end

cdPanel.startButton.onClick = function()
  local spell = cdPanel.spellInput:getText():lower():trim()
  if #spell == 0 then
    cdPanel.statusLabel:setText("Digite o nome da magia!")
    cdPanel.statusLabel:setColor({r=255, g=0, b=0, a=255})
    return
  end
  if not g_game.isAttacking() then
    cdPanel.statusLabel:setText("Selecione um alvo primeiro!")
    cdPanel.statusLabel:setColor({r=255, g=0, b=0, a=255})
    return
  end
  detectCD  = true
  testSpell = true
  spellTime = {0, ""}
  cdPanel.startButton:setEnabled(false)
  cdPanel.stopButton:setEnabled(true)
  cdPanel.statusLabel:setColor({r=255, g=200, b=0, a=255})
  cdPanel.statusLabel:setText("Detectando '" .. spell .. "'...")
end

comboContext.mainPanel.findCDButton.onClick = function()
  if cdWindow:isHidden() then
    local spell = comboContext.mainPanel.spellName:getText():lower():trim()
    if #spell > 0 then cdPanel.spellInput:setText(spell) end
    cdWindow:show()
    cdWindow:raise()
    cdWindow:focus()
  else
    cdWindow:hide()
    stopDetect()
  end
end

macro(10, function()
  if testSpell then
    local spell = cdPanel.spellInput:getText():lower():trim()
    if #spell > 0 then say(spell) end
  end
end)

local testWindow = setupUI([[
MainWindow
  !text: tr('Testar Combinacoes')
  size: 560 460
  Panel
    id: panel
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.top: parent.top
    anchors.left: parent.left
    size: 520 415
    Label
      id: lblDuration
      text: Duracao (s)
      anchors.top: parent.top
      anchors.left: parent.left
      margin-top: 10
      margin-left: 15
    HorizontalScrollBar
      id: durationScroll
      anchors.top: lblDuration.bottom
      anchors.left: parent.left
      margin-top: 3
      margin-left: 15
      width: 100
      step: 1
    Label
      id: lblRepeats
      text: Repeticoes
      anchors.top: parent.top
      anchors.left: durationScroll.right
      margin-top: 10
      margin-left: 20
    HorizontalScrollBar
      id: repeatsScroll
      anchors.top: lblRepeats.bottom
      anchors.left: durationScroll.right
      margin-top: 3
      margin-left: 20
      width: 100
      step: 1
    Label
      id: progressLabel
      text: Progresso: 0%
      anchors.top: parent.top
      anchors.left: repeatsScroll.right
      margin-top: 10
      margin-left: 20
      text-auto-resize: true
    Label
      id: timeEstLabel
      text: Tempo est: --
      anchors.top: progressLabel.bottom
      anchors.left: repeatsScroll.right
      margin-top: 3
      margin-left: 20
      text-auto-resize: true
    Label
      id: statusLabel
      text: Aguardando...
      anchors.top: durationScroll.bottom
      anchors.left: parent.left
      margin-top: 8
      margin-left: 15
      text-auto-resize: true
    TextList
      id: resultList
      anchors.top: statusLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 5
      margin-left: 15
      margin-right: 15
      height: 240
      image-border: 3
      image-source: /images/ui/textedit
      vertical-scrollbar: resultScroll
    VerticalScrollBar
      id: resultScroll
      anchors.top: resultList.top
      anchors.bottom: resultList.bottom
      anchors.right: resultList.right
      step: 14
      pixels-scroll: true
    Button
      id: startButton
      text: Iniciar
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      margin-bottom: 10
      margin-left: 15
      width: 70
      height: 20
    Button
      id: stopButton
      text: Parar
      anchors.bottom: parent.bottom
      anchors.left: startButton.right
      margin-bottom: 10
      margin-left: 5
      width: 70
      height: 20
    Button
      id: applyButton
      text: Aplicar Melhor
      anchors.bottom: parent.bottom
      anchors.left: stopButton.right
      margin-bottom: 10
      margin-left: 5
      width: 90
      height: 20
    Button
      id: exportButton
      text: Exportar
      anchors.bottom: parent.bottom
      anchors.left: applyButton.right
      margin-bottom: 10
      margin-left: 5
      width: 70
      height: 20
    Button
      id: closeButton
      text: Fechar
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      margin-bottom: 10
      margin-right: 15
      width: 70
      height: 20
]], g_ui.getRootWidget())

testWindow:hide()
local testPanel = testWindow.panel

local function twScrollSetup(widget, default, min, max)
  widget:setMinimum(min)
  widget:setMaximum(max)
  widget.onValueChange = function(w, v) w:setText(v) end
  widget:setValue(default)
end
twScrollSetup(testPanel.durationScroll, 10, 3, 60)
twScrollSetup(testPanel.repeatsScroll,  2,  1, 5)

local testState = {
  running      = false,
  permutations = {},
  current      = 0,
  repeatsDone  = 0,
  damageAccum  = 0,
  results      = {},
  bestCombo    = nil,
  castActive   = false,
  castIndex    = 1,
  currentPerm  = nil,
}

local testCastMacro = macro(200, function()
  if not testState.castActive or not testState.running then return end
  local perm = testState.currentPerm
  if not perm or #perm == 0 then return end
  local key = perm[testState.castIndex]
  local spell = config.spells[key]
  if spell and (spell.cooldownTime or 0) <= now then
    say(spell.spellName)
    spell.cooldownTime = now + (spell.cooldown * 1000)
    testState.castIndex = testState.castIndex + 1
    if testState.castIndex > #perm then testState.castIndex = 1 end
  end
end)
testCastMacro.setOn(false)

local function getFirstNumber(text)
  local n = string.match(text, "%d+")
  return n and tonumber(n) or nil
end

local function fmtDmg(n)
  if n >= 1000000 then return string.format("%.1fM", n/1000000)
  elseif n >= 1000 then return string.format("%.1fk", n/1000)
  else return tostring(n) end
end

local function fmtTime(secs)
  if secs >= 3600 then return string.format("%dh%dm", math.floor(secs/3600), math.floor((secs%3600)/60))
  elseif secs >= 60 then return string.format("%dm%ds", math.floor(secs/60), secs%60)
  else return secs .. "s" end
end

local function permutations(arr)
  local result = {}
  local function perm(a, n)
    if n == 0 then
      local copy = {}
      for _, v in ipairs(a) do copy[#copy+1] = v end
      result[#result+1] = copy
      return
    end
    for i = 1, n do
      a[i], a[n] = a[n], a[i]
      perm(a, n - 1)
      a[i], a[n] = a[n], a[i]
    end
  end
  perm(arr, #arr)
  return result
end

local function comboLabel(perm)
  local names = {}
  for _, key in ipairs(perm) do
    local spell = config.spells[key]
    if spell then
      names[#names+1] = spell.spellName:match("^(%S+)") or spell.spellName
    end
  end
  return table.concat(names, " > ")
end

local function setStatus(text, color)
  testPanel.statusLabel:setText(text)
  testPanel.statusLabel:setColor(color or {r=255, g=255, b=255, a=255})
end

local function updateProgress()
  local total = #testState.permutations
  local done  = math.max(0, testState.current - 1)
  local pct   = total > 0 and math.floor((done / total) * 100) or 0
  testPanel.progressLabel:setText(string.format("Progresso: %d%%", pct))
  local remaining = total - done
  local duration  = testPanel.durationScroll:getValue()
  local repeats   = testPanel.repeatsScroll:getValue()
  local estSecs   = remaining * duration * repeats
  testPanel.timeEstLabel:setText("Tempo est: " .. fmtTime(estSecs))
end

local function rankColor(pos)
  if pos == 1 then return {r=0,   g=220, b=0,   a=255} end
  if pos == 2 then return {r=255, g=220, b=0,   a=255} end
  if pos == 3 then return {r=255, g=140, b=0,   a=255} end
  return {r=180, g=180, b=180, a=255}
end

local function rebuildRanking()
  for _, child in ipairs(testPanel.resultList:getChildren()) do child:destroy() end

  local sorted = {}
  for _, r in ipairs(testState.results) do sorted[#sorted+1] = r end
  table.sort(sorted, function(a, b) return a.avg > b.avg end)

  for i, r in ipairs(sorted) do
    local duration = testPanel.durationScroll:getValue()
    local dps      = duration > 0 and math.floor(r.avg / duration) or 0
    local lbl = g_ui.createWidget("Label", testPanel.resultList)
    lbl:setText(string.format("#%d %s | %s | %s/s", i, r.label, fmtDmg(r.avg), fmtDmg(dps)))
    lbl:setColor(rankColor(i))
    lbl:setPhantom(true)
    lbl:setTextAutoResize(true)
    lbl:setHeight(16)
  end
end

local function stopTest()
  testState.running    = false
  testState.castActive = false
  testCastMacro.setOn(false)
  if testPanel and not testPanel:isDestroyed() then
    testPanel.startButton:setEnabled(true)
    testPanel.stopButton:setEnabled(false)
    testPanel.applyButton:setEnabled(testState.bestCombo ~= nil)
    testPanel.exportButton:setEnabled(#testState.results > 0)
  end
  for _, spell in pairs(config.spells) do
    if type(spell) == "table" then spell.cooldownTime = 0 end
  end
end

local testDamage = 0

local function runNextPermutation()
  if not testState.running then return end

  testState.current = testState.current + 1
  updateProgress()

  if testState.current > #testState.permutations then
    rebuildRanking()
    stopTest()
    testPanel.progressLabel:setText("Progresso: 100%")
    testPanel.timeEstLabel:setText("Tempo est: 0s")
    local bestLabel = testState.bestCombo and comboLabel(testState.bestCombo) or "?"
    setStatus("Concluido! Melhor: " .. bestLabel, {r=0, g=220, b=0, a=255})
    return
  end

  testState.repeatsDone = 0
  testState.damageAccum = 0
  local perm     = testState.permutations[testState.current]
  local label    = comboLabel(perm)
  local repeats  = testPanel.repeatsScroll:getValue()
  local duration = testPanel.durationScroll:getValue()

  setStatus(string.format("[%d/%d] %s", testState.current, #testState.permutations, label), {r=255, g=200, b=0, a=255})

  local function runRepeat()
    if not testState.running then return end
    if testState.repeatsDone >= repeats then
      local avg   = math.floor(testState.damageAccum / repeats)
      local entry = {combo = perm, avg = avg, label = label}
      testState.results[#testState.results+1] = entry

      local best = testState.results[1]
      for _, r in ipairs(testState.results) do
        if r.avg > best.avg then best = r end
      end
      testState.bestCombo = best.combo

      rebuildRanking()
      runNextPermutation()
      return
    end

    testState.repeatsDone = testState.repeatsDone + 1
    testDamage = 0
    testState.castActive  = true
    testState.castIndex   = 1
    testState.currentPerm = perm
    testCastMacro.setOn(true)

    for _, spell in pairs(config.spells) do
      if type(spell) == "table" then spell.cooldownTime = 0 end
    end

    schedule(duration * 1000, function()
      testState.castActive = false
      testCastMacro.setOn(false)
      if not testState.running then return end
      testState.damageAccum = testState.damageAccum + testDamage
      local dps = duration > 0 and math.floor(testDamage / duration) or 0
      setStatus(string.format("[%d/%d] Rep %d/%d: %s (%s/s) | %s",
        testState.current, #testState.permutations,
        testState.repeatsDone, repeats,
        fmtDmg(testDamage), fmtDmg(dps), label), {r=255, g=200, b=0, a=255})
      runRepeat()
    end)
  end

  runRepeat()
end

onTextMessage(function(mode, text)
  if not testState.running then return end
  if not text:lower():find("loses") then return end
  local n = getFirstNumber(text)
  if n then testDamage = testDamage + n end
end)

local function factorialStr(n)
  local f = 1
  for i = 2, n do f = f * i end
  return f
end

testPanel.startButton.onClick = function()
  if testState.running then return end

  if not g_game.isAttacking() then
    setStatus("Sem alvo! Ataque um monstro primeiro.", {r=255, g=0, b=0, a=255})
    return
  end

  local keys = {}
  for key, spell in pairs(config.spells) do
    if type(spell) == "table" and spell.enabled then
      keys[#keys+1] = key
    end
  end
  if #keys < 2 then
    setStatus("Precisa de pelo menos 2 magias ativas!", {r=255, g=0, b=0, a=255})
    return
  end

  local totalPerms = factorialStr(#keys)
  local duration   = testPanel.durationScroll:getValue()
  local repeats    = testPanel.repeatsScroll:getValue()
  local estSecs    = totalPerms * duration * repeats

  if totalPerms > 24 then
    setStatus(string.format("AVISO: %d combinacoes! ~%s. Reduza as magias.", totalPerms, fmtTime(estSecs)), {r=255, g=80, b=0, a=255})
    return
  end

  for _, child in ipairs(testPanel.resultList:getChildren()) do child:destroy() end

  testState.running      = true
  testState.permutations = permutations(keys)
  testState.current      = 0
  testState.results      = {}
  testState.bestCombo    = nil
  testDamage             = 0

  testPanel.startButton:setEnabled(false)
  testPanel.stopButton:setEnabled(true)
  testPanel.applyButton:setEnabled(false)
  testPanel.exportButton:setEnabled(false)
  testPanel.progressLabel:setText("Progresso: 0%")
  testPanel.timeEstLabel:setText("Tempo est: " .. fmtTime(estSecs))

  setStatus(string.format("Iniciando %d combinacoes (~%s)...", totalPerms, fmtTime(estSecs)), {r=255, g=200, b=0, a=255})

  runNextPermutation()
end

testPanel.stopButton:setEnabled(false)
testPanel.applyButton:setEnabled(false)
testPanel.exportButton:setEnabled(false)

testPanel.stopButton.onClick = function()
  stopTest()
  setStatus("Parado pelo usuario.", {r=255, g=100, b=100, a=255})
end

testPanel.applyButton.onClick = function()
  if not testState.bestCombo then return end
  for i, key in ipairs(testState.bestCombo) do
    if config.spells[key] then config.spells[key].index = i - 1 end
  end
  saveConfig()
  comboContext.refresh()
  setStatus("Melhor combo aplicado!", {r=0, g=220, b=0, a=255})
  msgOk("Melhor combo aplicado!")
end

testPanel.exportButton.onClick = function()
  if #testState.results == 0 then return end

  local sorted = {}
  for _, r in ipairs(testState.results) do sorted[#sorted+1] = r end
  table.sort(sorted, function(a, b) return a.avg > b.avg end)

  local duration = testPanel.durationScroll:getValue()
  local lines    = {"=== Ranking de Combinacoes ===", "Duracao: " .. duration .. "s | Repeticoes: " .. testPanel.repeatsScroll:getValue()}
  for i, r in ipairs(sorted) do
    local dps = duration > 0 and math.floor(r.avg / duration) or 0
    lines[#lines+1] = string.format("#%d %s | media: %s | DPS: %s", i, r.label, fmtDmg(r.avg), fmtDmg(dps))
  end

  local exportFile = SAVE_DIR .. player:getName() .. "_ranking.txt"
  g_resources.writeFileContents(exportFile, table.concat(lines, "\n"))
  setStatus("Exportado: " .. exportFile, {r=0, g=220, b=0, a=255})
  msgOk("Ranking exportado!")
end

testPanel.closeButton.onClick = function()
  stopTest()
  testWindow:hide()
end
testWindow.onEscape = testPanel.closeButton.onClick

comboContext.mainPanel.testComboButton.onClick = function()
  if testState.running then
    setStatus("Pare o teste antes de fechar!", {r=255, g=100, b=0, a=255})
    testWindow:show()
    testWindow:raise()
    return
  end
  if testWindow:isHidden() then
    testWindow:show()
    testWindow:raise()
    testWindow:focus()
  else
    testWindow:hide()
  end
end

comboContext.window.onDestroy = function()
  stopTest()
end

local currentPvpProfile = nil
local pvpActive = false

storage.pvpWidgetPos = storage.pvpWidgetPos or {x=50, y=50}

local pvpWidget = setupUI([[
UIWidget
  background-color: black
  opacity: 0.8
  padding: 2 6
  focusable: true
  phantom: false
  draggable: true
  text-auto-resize: true
  font: verdana-11px-rounded
]], g_ui.getRootWidget())

pvpWidget:setText("Atacando: 0")
pvpWidget:setColor({r=255, g=200, b=0, a=255})
pvpWidget:setPosition({x = storage.pvpWidgetPos.x, y = storage.pvpWidgetPos.y})
pvpWidget:hide()

pvpWidget.onDragEnter = function(widget, mousePos)
  if not g_keyboard.isCtrlPressed() then return false end
  widget:breakAnchors()
  widget.ref = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
  return true
end

pvpWidget.onDragMove = function(widget, mousePos)
  local r = widget:getParent():getRect()
  local x = math.min(math.max(r.x, mousePos.x - widget.ref.x), r.x + r.width - widget:getWidth())
  local y = math.min(math.max(r.y, mousePos.y - widget.ref.y), r.y + r.height - widget:getHeight())
  widget:move(x, y)
  storage.pvpWidgetPos = {x=x, y=y}
  return true
end

local pvpSpellEntry = [[
Label
  background-color: alpha
  text-offset: 5 4
  focusable: false
  height: 16
  font: verdana-11px-rounded
]]

local pvpProfileEntry = [[
Label
  background-color: alpha
  text-offset: 22 3
  focusable: true
  height: 18
  font: verdana-11px-rounded
  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-left: 3
  $focus:
    background-color: #00000055
]]

local pvpWindow = setupUI([[
MainWindow
  !text: tr('PvP Perfis')
  size: 620 460
  Panel
    id: panel
    image-source: /images/ui/panel_flat
    image-border: 6
    anchors.fill: parent
    margin: 5
    Panel
      id: leftPanel
      image-source: /images/ui/panel_flat
      image-border: 4
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.bottom: bottomRow.top
      width: 190
      margin: 5 5 5 5
      Label
        text: Perfis
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 16
        margin: 6 0 0 0
        text-align: center
        font: verdana-11px-rounded
      TextList
        id: profileList
        anchors.top: prev.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: profileButtons.top
        margin: 3 5 3 5
        image-border: 3
        image-source: /images/ui/textedit
        vertical-scrollbar: profileScroll
      VerticalScrollBar
        id: profileScroll
        anchors.top: profileList.top
        anchors.bottom: profileList.bottom
        anchors.right: profileList.right
        step: 10
        pixels-scroll: true
      Panel
        id: profileButtons
        anchors.bottom: friendSection.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 28
        margin: 0 5 3 5
        Button
          id: addProfile
          text: + Perfil
          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter
          width: 60
          height: 22
        Button
          id: removeProfile
          text: Remover
          anchors.left: addProfile.right
          anchors.verticalCenter: parent.verticalCenter
          margin-left: 5
          width: 60
          height: 22
      Panel
        id: friendSection
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 130
        margin: 0 5 5 5
        image-source: /images/ui/panel_flat
        image-border: 4
        Label
          text: Friends (ignorar)
          anchors.top: parent.top
          anchors.left: parent.left
          anchors.right: parent.right
          height: 16
          margin: 5 0 0 0
          text-align: center
          font: verdana-11px-rounded
        TextList
          id: friendList
          anchors.top: prev.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: friendInput.top
          margin: 3 5 3 5
          image-border: 3
          image-source: /images/ui/textedit
          vertical-scrollbar: friendScroll
        VerticalScrollBar
          id: friendScroll
          anchors.top: friendList.top
          anchors.bottom: friendList.bottom
          anchors.right: friendList.right
          step: 10
          pixels-scroll: true
        Panel
          id: friendInput
          anchors.bottom: parent.bottom
          anchors.left: parent.left
          anchors.right: parent.right
          height: 28
          margin: 0 3 3 3
          TextEdit
            id: friendName
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            margin-left: 5
            height: 20
            width: 120
          Button
            id: addFriend
            text: +
            anchors.left: friendName.right
            anchors.verticalCenter: parent.verticalCenter
            margin-left: 5
            width: 25
            height: 22
    Panel
      id: rightPanel
      image-source: /images/ui/panel_flat
      image-border: 4
      anchors.top: parent.top
      anchors.left: leftPanel.right
      anchors.right: parent.right
      anchors.bottom: bottomRow.top
      margin: 5 5 5 0
      Panel
        id: topConfig
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 55
        margin: 5 5 5 5
        image-source: /images/ui/panel_flat
        image-border: 4
        Label
          text: Nome
          anchors.top: parent.top
          anchors.left: parent.left
          margin: 5 0 0 8
          text-auto-resize: true
        TextEdit
          id: profileName
          anchors.top: prev.bottom
          anchors.left: parent.left
          margin: 2 0 0 8
          height: 21
          width: 120
        Label
          text: Min. Players
          anchors.top: parent.top
          anchors.left: profileName.right
          margin: 5 0 0 8
          text-auto-resize: true
        HorizontalScrollBar
          id: minPlayers
          anchors.top: prev.bottom
          anchors.left: profileName.right
          margin: 5 0 0 8
          width: 85
          height: 15
          step: 1
        Label
          text: Tecla
          anchors.top: parent.top
          anchors.left: minPlayers.right
          margin: 5 0 0 8
          text-auto-resize: true
        TextEdit
          id: hotkey
          anchors.top: prev.bottom
          anchors.left: minPlayers.right
          margin: 2 0 0 8
          height: 21
          width: 60
          editable: false
          background-color: #000000
          color: #000000
      Label
        text: Magias do Perfil
        anchors.top: topConfig.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 16
        margin: 5 0 0 0
        text-align: center
        font: verdana-11px-rounded
      TextList
        id: spellList
        anchors.top: prev.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: spellInput.top
        margin: 3 5 3 5
        image-border: 3
        image-source: /images/ui/textedit
        vertical-scrollbar: spellScroll
      VerticalScrollBar
        id: spellScroll
        anchors.top: spellList.top
        anchors.bottom: spellList.bottom
        anchors.right: spellList.right
        step: 10
        pixels-scroll: true
      Panel
        id: spellInput
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 55
        margin: 0 5 5 5
        image-source: /images/ui/panel_flat
        image-border: 4
        Label
          text: Magia
          anchors.top: parent.top
          anchors.left: parent.left
          margin: 5 0 0 8
          text-auto-resize: true
        TextEdit
          id: spellName
          anchors.top: prev.bottom
          anchors.left: parent.left
          margin: 2 0 0 8
          height: 21
          width: 130
        Label
          text: CD(s)
          anchors.top: parent.top
          anchors.left: spellName.right
          margin: 5 0 0 8
          text-auto-resize: true
        HorizontalScrollBar
          id: cdScroll
          anchors.top: prev.bottom
          anchors.left: spellName.right
          margin: 5 0 0 8
          width: 70
          height: 15
          step: 1
        Label
          text: Dist
          anchors.top: parent.top
          anchors.left: cdScroll.right
          margin: 5 0 0 8
          text-auto-resize: true
        HorizontalScrollBar
          id: distScroll
          anchors.top: prev.bottom
          anchors.left: cdScroll.right
          margin: 5 0 0 8
          width: 60
          height: 15
          step: 1
        Button
          id: addSpell
          text: Adicionar
          anchors.top: parent.top
          anchors.right: parent.right
          margin: 5 8 0 0
          width: 65
          height: 22
    Panel
      id: bottomRow
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      height: 35
      margin: 0 5 5 5
      image-source: /images/ui/panel_flat
      image-border: 4
      Label
        id: statusLabel
        text: .
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        margin-left: 8
        text-auto-resize: true
      Label
        id: lblTimeout
        text: Timeout(s)
        anchors.right: timeoutScroll.left
        anchors.verticalCenter: parent.verticalCenter
        margin-right: 5
        text-auto-resize: true
      HorizontalScrollBar
        id: timeoutScroll
        anchors.right: pvpSwitch.left
        anchors.verticalCenter: parent.verticalCenter
        margin-right: 8
        width: 70
        height: 15
        step: 1
      BotSwitch
        id: pvpSwitch
        anchors.right: closeButton.left
        anchors.verticalCenter: parent.verticalCenter
        margin-right: 8
        width: 80
        text: PvP ON
      Button
        id: closeButton
        text: Fechar
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        margin-right: 8
        width: 70
        height: 22
      Label
        id: attackingLabel
        text: Atacando: 0
        anchors.left: pvpSwitch.left
        anchors.bottom: parent.bottom
        margin-bottom: -13
        text-auto-resize: true
]], g_ui.getRootWidget())

pvpWindow:hide()
local pvpPanel = pvpWindow.panel
pvpWindow.panel.rightPanel.topConfig.hotkey:setBackgroundColor({r=0, g=0, b=0, a=255})
pvpWindow.panel.rightPanel.topConfig.hotkey:setColor({r=255, g=255, b=255, a=255})

local function pvpScrollSetup(widget, default, min, max)
  widget:setMinimum(min)
  widget:setMaximum(max)
  widget.onValueChange = function(w, v) w:setText(v) end
  widget:setValue(default)
end
pvpScrollSetup(pvpPanel.rightPanel.topConfig.minPlayers, 1, 1, 10)
pvpScrollSetup(pvpPanel.rightPanel.spellInput.cdScroll, 1, 0, 120)
pvpScrollSetup(pvpPanel.rightPanel.spellInput.distScroll, 1, 1, 20)
pvpScrollSetup(pvpPanel.bottomRow.timeoutScroll, 5, 1, 30)

pvpPanel.rightPanel.minPlayers  = pvpPanel.rightPanel.topConfig.minPlayers
pvpPanel.rightPanel.profileName = pvpPanel.rightPanel.topConfig.profileName
pvpPanel.rightPanel.hotkey      = pvpPanel.rightPanel.topConfig.hotkey

pvpPanel.rightPanel.hotkey:setBackgroundColor({r=0, g=0, b=0, a=255})
pvpPanel.rightPanel.hotkey:setColor({r=255, g=255, b=255, a=255})
pvpPanel.rightPanel.hotkey.onClick = function(widget)
  local capturing = true
  onKeyPress(function(key)
    if not capturing then return end
    capturing = false
    if key == "Escape" then
      widget:setText("")
      if selectedProfileIndex then
        pvpConfig.profiles[selectedProfileIndex].hotkey = ""
        savePvpConfig()
        refreshProfileList()
      end
    else
      widget:setText(key)
      if selectedProfileIndex then
        pvpConfig.profiles[selectedProfileIndex].hotkey = key
        savePvpConfig()
        refreshProfileList()
      end
    end
    widget:setBackgroundColor({r=0, g=0, b=0, a=255})
    widget:setColor({r=255, g=255, b=255, a=255})
  end)
end

local refreshProfileList
local refreshSpellList

pvpPanel.rightPanel.minPlayers.onValueChange = function(widget, value)
  widget:setText(tostring(value))
  if not selectedProfileIndex then return end
  pvpConfig.profiles[selectedProfileIndex].minPlayers = value
  savePvpConfig()
  if refreshProfileList then refreshProfileList() end
end

local function refreshFriendList()
  local list = pvpPanel.leftPanel.friendSection.friendList
  for _, child in ipairs(list:getChildren()) do child:destroy() end
  for i, name in ipairs(pvpConfig.friends) do
    local w = setupUI([[
Label
  background-color: alpha
  text-offset: 5 3
  focusable: true
  height: 16
  font: verdana-11px-rounded
  $focus:
    background-color: #00000055
]], list)
    w:setText(name)
    w.onDoubleClick = function()
      table.remove(pvpConfig.friends, i)
      savePvpConfig()
      refreshFriendList()
    end
  end
end

pvpPanel.leftPanel.friendSection.friendInput.addFriend.onClick = function()
  local name = pvpPanel.leftPanel.friendSection.friendInput.friendName:getText():trim()
  if #name == 0 then return end
  for _, f in ipairs(pvpConfig.friends) do
    if f:lower() == name:lower() then return end
  end
  table.insert(pvpConfig.friends, name)
  pvpPanel.leftPanel.friendSection.friendInput.friendName:setText("")
  savePvpConfig()
  refreshFriendList()
end

local function pvpStatus(text, color)
  pvpPanel.bottomRow.statusLabel:setText(text)
  pvpPanel.bottomRow.statusLabel:setColor(color or {r=255,g=255,b=255,a=255})
end

refreshSpellList = function(profile)
  local list = pvpPanel.rightPanel.spellList
  for _, child in ipairs(list:getChildren()) do child:destroy() end
  if not profile then return end
  for i, spell in ipairs(profile.spells or {}) do
    local w = setupUI(pvpSpellEntry, list)
    w:setText(string.format(" %s  cd:%ds  dist:%d", spell.spellName, spell.cooldown, spell.distance))
    w.onDoubleClick = function()
      table.remove(profile.spells, i)
      savePvpConfig()
      refreshSpellList(profile)
    end
  end
end

refreshProfileList = function()
  local list = pvpPanel.leftPanel.profileList
  for _, child in ipairs(list:getChildren()) do child:destroy() end
  for i, profile in ipairs(pvpConfig.profiles) do
    local w = setupUI(pvpProfileEntry, list)
    w:setText(string.format("%s [%d+]%s", profile.name, profile.minPlayers, profile.hotkey and profile.hotkey ~= "" and " ["..profile.hotkey.."]" or ""))
    w.enabled:setChecked(profile.enabled ~= false)
    w.enabled.onCheckChange = function(_, checked)
      profile.enabled = checked
      savePvpConfig()
    end
    w.onFocusChange = function(widget, focused)
      if not focused then return end
      selectedProfileIndex = i
      pvpPanel.rightPanel.profileName:setText(profile.name)
      pvpPanel.rightPanel.minPlayers:setValue(profile.minPlayers)
      pvpPanel.rightPanel.hotkey:setText(profile.hotkey or "")
      refreshSpellList(profile)
      pvpStatus("Perfil selecionado: " .. profile.name, {r=255,g=200,b=0,a=255})
    end
  end
end

pvpPanel.leftPanel.profileButtons.addProfile.onClick = function()
  local newProfile = {
    name       = "Perfil " .. (#pvpConfig.profiles + 1),
    minPlayers = #pvpConfig.profiles + 1,
    enabled    = true,
    spells     = {},
  }
  table.insert(pvpConfig.profiles, newProfile)
  savePvpConfig()
  refreshProfileList()
  pvpStatus("Perfil criado.", {r=0,g=220,b=0,a=255})
end

pvpPanel.leftPanel.profileButtons.removeProfile.onClick = function()
  if not selectedProfileIndex then return end
  table.remove(pvpConfig.profiles, selectedProfileIndex)
  selectedProfileIndex = nil
  refreshSpellList(nil)
  pvpPanel.rightPanel.profileName:setText("")
  savePvpConfig()
  refreshProfileList()
  pvpStatus("Perfil removido.", {r=255,g=100,b=100,a=255})
end

pvpPanel.rightPanel.profileName.onTextChange = function(_, text)
  if not selectedProfileIndex then return end
  pvpConfig.profiles[selectedProfileIndex].name = text
  savePvpConfig()
  refreshProfileList()
end

pvpPanel.rightPanel.spellInput.addSpell.onClick = function()
  if not selectedProfileIndex then
    pvpStatus("Selecione um perfil primeiro.", {r=255,g=0,b=0,a=255})
    return
  end
  local spell    = pvpPanel.rightPanel.spellInput.spellName:getText():lower():trim()
  local cooldown = pvpPanel.rightPanel.spellInput.cdScroll:getValue()
  local distance = pvpPanel.rightPanel.spellInput.distScroll:getValue()
  if #spell == 0 then
    pvpStatus("Insira o nome da magia.", {r=255,g=0,b=0,a=255})
    return
  end
  local profile = pvpConfig.profiles[selectedProfileIndex]
  table.insert(profile.spells, {spellName=spell, cooldown=cooldown, distance=distance, cooldownTime=0})
  pvpPanel.rightPanel.spellInput.spellName:setText("")
  savePvpConfig()
  refreshSpellList(profile)
  pvpStatus("Magia adicionada.", {r=0,g=220,b=0,a=255})
end

if storage.pvpMacro == nil then storage.pvpMacro = false end
pvpPanel.bottomRow.pvpSwitch:setOn(storage.pvpMacro)
if storage.pvpMacro then pvpWidget:show() end

pvpPanel.bottomRow.pvpSwitch.onClick = function()
  storage.pvpMacro = not storage.pvpMacro
  pvpPanel.bottomRow.pvpSwitch:setOn(storage.pvpMacro)
  if storage.pvpMacro then
    pvpWidget:show()
  else
    pvpWidget:hide()
    pvpWidget:setText("Atacando: 0")
    attackers = {}
    currentPvpProfile = nil
    lastProfileName = ""
    for _, profile in ipairs(pvpConfig.profiles) do
      for _, spell in ipairs(profile.spells or {}) do
        spell.cooldownTime = 0
      end
    end
  end
end

pvpPanel.bottomRow.closeButton.onClick = function()
  pvpWindow:hide()
end
pvpWindow.onEscape = pvpPanel.bottomRow.closeButton.onClick

comboContext.mainPanel.pvpButton.onClick = function()
  if pvpWindow:isHidden() then
    pvpWindow:show()
    pvpWindow:raise()
    pvpWindow:focus()
    refreshProfileList()
  else
    pvpWindow:hide()
  end
end

local function isHotkeyPressed(hotkey)
  if not hotkey or #hotkey == 0 then return false end
  return g_keyboard.isKeyPressed(hotkey)
end

macro(200, function()
  if not storage.pvpMacro then return end
  if not storage.comboMacro then return end

  local playerCount = countAttackingPlayers()

  for _, profile in ipairs(pvpConfig.profiles) do
    if profile.enabled and profile.hotkey and #profile.hotkey > 0 then
      if isHotkeyPressed(profile.hotkey) then
        if profile.name ~= lastProfileName then
          lastProfileName = profile.name
          for _, p in ipairs(pvpConfig.profiles) do
            for _, spell in ipairs(p.spells or {}) do spell.cooldownTime = 0 end
          end
          pvpStatus("Perfil (tecla): " .. profile.name, {r=255,g=200,b=0,a=255})
          msgOk("PvP: " .. profile.name)
        end
        break
      end
    end
  end
  local profile = nil
  for _, p in ipairs(pvpConfig.profiles) do
    if p.name == lastProfileName then profile = p break end
  end
  if not profile then
    profile = getActiveProfile(playerCount) or getActiveProfile(1)
  end

  local lines = {"Atacando: " .. playerCount}
  for name, expiry in pairs(attackers) do
    if expiry > now then
      lines[#lines+1] = "  > " .. name
    end
  end
  if profile then
    lines[#lines+1] = "Perfil: " .. profile.name
  end
  pvpWidget:setText(table.concat(lines, "\n"))

  if playerCount > 0 then
    pvpWidget:setColor({r=255, g=80, b=80, a=255})
  else
    pvpWidget:setColor({r=255, g=200, b=0, a=255})
  end

  if not pvpWindow:isHidden() then
    pvpPanel.bottomRow.attackingLabel:setText("Atacando: " .. playerCount)
  end

  if not g_game.isAttacking() then return end

  local target = getTarget()
  if not target then return end

  if playerCount == 0 then
    if lastProfileName ~= "" then
      lastProfileName = ""
      for _, p in ipairs(pvpConfig.profiles) do
        for _, spell in ipairs(p.spells or {}) do spell.cooldownTime = 0 end
      end
    end
    return
  end

  if not profile then return end

  if profile.name ~= lastProfileName then
    lastProfileName = profile.name
    for _, p in ipairs(pvpConfig.profiles) do
      for _, spell in ipairs(p.spells or {}) do spell.cooldownTime = 0 end
    end
    pvpStatus("Perfil ativo: " .. profile.name .. " (" .. playerCount .. " players)", {r=255,g=200,b=0,a=255})
    msgOk("PvP: " .. profile.name)
  end

  local targetPos = target:getPosition()
  if not targetPos then return end
  local distance = getDistanceBetween(targetPos, pos())

  for _, spell in ipairs(profile.spells) do
    if (spell.cooldownTime or 0) <= now and distance <= spell.distance then
      say(spell.spellName)
      spell.cooldownTime = now + (spell.cooldown * 1000)
    end
  end
end)

local lastProfileName = ""

refreshProfileList()
refreshFriendList()

addIcon("comboIcon", {item = 8053, text = "Combo"}, comboContext.executeMacro)

comboContext.refresh()