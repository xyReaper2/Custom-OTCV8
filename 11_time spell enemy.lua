timeEnemy = {};
enemy_data = {spells={}};
storage._enemy = storage._enemy or {};
local dir = configDir .. "/storage";
local path = dir .. "/" .. g_game.getWorldName() .. ".json";

if not g_resources.directoryExists(dir) then
    g_resources.makeDir(dir);
end

timeEnemy.save = function()
    local status, result = pcall(json.encode, enemy_data, 4);
    if status then
        g_resources.writeFileContents(path, result);
    end
end

timeEnemy.load = function()
    local data = enemy_data;
    if modules._G.g_resources.fileExists(path) then
        local content = modules._G.g_resources.readFileContents(path);
        local status, result = pcall(json.decode, content);
        if status then
            data = result;
        else
            warn("Erro ao decodificar o arquivo JSON: " .. result);
        end
    else
        timeEnemy.save();
    end
    enemy_data = data;
    enemy_data.spells  = enemy_data.spells  or {};
    enemy_data.enabled = enemy_data.enabled ~= false and (enemy_data.enabled or false);
end

local spellEntryTimeSpell = [[
UIWidget
  background-color: alpha
  focusable: true
  height: 28
  margin-bottom: 3

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-left: 8

  Label
    id: text
    anchors.left: prev.right
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 8
    font: verdana-11px-rounded
    color: #FFFFFF
    text-auto-resize: true

  Label
    id: acLabel
    anchors.right: cdLabel.left
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 5
    font: verdana-11px-rounded
    text-auto-resize: true
    background-color: #1a3a3a
    padding: 2 5

  Label
    id: cdLabel
    anchors.right: removeBtn.left
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 5
    font: verdana-11px-rounded
    text-auto-resize: true
    background-color: #3a1a1a
    padding: 2 5

  UIWidget
    id: removeBtn
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 8
    width: 15
    height: 15
    text: X
    color: #FF4444
    font: verdana-11px-rounded
    text-align: center
    focusable: true
    background-color: #00000000

  $focus:
    background-color: #ffffff11
]];

local timer_add = [[
Label
  text-auto-resize: true
  font: verdana-11px-rounded
  color: orange
  margin-bottom: 5
  text-offset: 3 1
]];

timeEnemy.buttons = setupUI([[
Panel
  height: 90
  BotSwitch
    id: title
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr('Time Spell Enemy')
  Button
    id: settings
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Setup
  CheckBox
    id: target
    anchors.top: settings.bottom
    anchors.left: parent.left
    margin-top: 3
    margin-left: 5
    text: Targets
    width: 68
    tooltip: Time Spell Targets
    checked: false
  CheckBox
    id: enemy
    anchors.top: target.bottom
    anchors.left: parent.left
    margin-top: 3
    margin-left: 5
    text: Enemies
    width: 68
    tooltip: Time Spell Enemies
    checked: false
  CheckBox
    id: guild
    anchors.top: enemy.bottom
    anchors.left: parent.left
    margin-top: 3
    margin-left: 5
    text: Guilds
    width: 68
    tooltip: Time Spell Guilds
    checked: false
]]);

timeEnemy.widget = setupUI([[
Panel
  text: - TIME SPELL ENEMY -
  size: 350 400
  anchors.right: parent.right
  anchors.top: parent.top
  margin-right: 10
  margin-top: 150
  text-align: top
  opacity: 0.9
  phantom: false
  focusable: true
  draggable: true

  ScrollablePanel
    id: enemyList
    layout:
      type: verticalBox
    anchors.fill: parent
    margin-top: 20
    margin-left: 10
    margin-right: 10
    margin-bottom: 10

]], g_ui.getRootWidget());

storage.timeEnemyPos = storage.timeEnemyPos or {x = 900, y = 150}
timeEnemy.widget:setPosition(storage.timeEnemyPos)

timeEnemy.widget.onDragEnter = function(widget, mousePos)
    if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
    widget:breakAnchors()
    widget.ref = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
    return true
end

timeEnemy.widget.onDragMove = function(widget, mousePos)
    local r = widget:getParent():getRect()
    local x = math.min(math.max(r.x, mousePos.x - widget.ref.x), r.x + r.width - widget:getWidth())
    local y = math.min(math.max(r.y, mousePos.y - widget.ref.y), r.y + r.height - widget:getHeight())
    widget:move(x, y)
    storage.timeEnemyPos = {x = x, y = y}
    return true
end

timeEnemy.interface = setupUI([[
UIWidget
  id: timeEnemyWindow
  size: 500 380
  border-width: 1
  border-color: #446688
  focusable: true
  phantom: false
  draggable: true
  background-color: #111111EE
  @onEscape: self:hide()

  Label
    id: titleLabel
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 8
    text: TIME SPELL ENEMY
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
    background-color: #333333

  Panel
    id: inputArea
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 120
    background-color: #00000000
    margin: 8 8 0 8

    Label
      anchors.top: parent.top
      anchors.left: parent.left
      margin-left: 70
      text: SPELL NAME
      color: #888888
      font: verdana-11px-rounded
      text-auto-resize: true

    TextEdit
      id: spellName
      anchors.top: prev.bottom
      anchors.left: parent.left
      margin-top: 3
      width: 220
      height: 22
      background-color: #00000000
      image-color: #00000000
      border-width: 1
      border-color: #446688
      color: #FFFFFF
      font: verdana-11px-rounded

    Label
      anchors.top: parent.top
      anchors.left: spellName.right
      margin-left: 90
      text: ON SCREEN
      color: #888888
      font: verdana-11px-rounded
      text-auto-resize: true

    TextEdit
      id: onScreen
      anchors.top: prev.bottom
      anchors.left: spellName.right
      anchors.right: parent.right
      margin-top: 3
      margin-left: 10
      height: 22
      background-color: #00000000
      image-color: #00000000
      border-width: 1
      border-color: #446688
      color: #FFFFFF
      font: verdana-11px-rounded

    Label
      anchors.top: spellName.bottom
      anchors.left: parent.left
      margin-top: 8
      margin-left: 70
      text: CD ATIVO (s)
      color: #888888
      font: verdana-11px-rounded
      text-auto-resize: true

    HorizontalScrollBar
      id: cooldownAtivo
      anchors.top: prev.bottom
      anchors.left: parent.left
      margin-top: 3
      width: 220
      height: 15
      minimum: 0
      maximum: 360
      step: 1

    Label
      anchors.top: spellName.bottom
      anchors.left: cooldownAtivo.right
      margin-top: 8
      margin-left: 90
      text: CD TOTAL (s)
      color: #888888
      font: verdana-11px-rounded
      text-auto-resize: true

    HorizontalScrollBar
      id: cooldownTotal
      anchors.top: prev.bottom
      anchors.left: cooldownAtivo.right
      anchors.right: parent.right
      margin-top: 3
      margin-left: 10
      height: 15
      minimum: 0
      maximum: 360
      step: 1

  UIWidget
    id: addButton
    anchors.top: inputArea.bottom
    anchors.right: parent.right
    margin-top: 8
    margin-right: 8
    width: 110
    height: 22
    text: + ADICIONAR
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  UIWidget
    anchors.top: addButton.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 8
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #333333

  Label
    id: spellsLabel
    anchors.top: prev.bottom
    anchors.left: parent.left
    margin-top: 6
    margin-left: 180
    text: SPELLS CADASTRADAS
    color: #888888
    font: verdana-11px-rounded
    text-auto-resize: true

  TextList
    id: spellList
    anchors.top: spellsLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: separator.top
    margin-top: 4
    margin-left: 8
    margin-right: 8
    margin-bottom: 4
    background-color: #00000000
    image-color: #00000000
    vertical-scrollbar: spellListScrollbar

  VerticalScrollBar
    id: spellListScrollbar
    anchors.top: spellList.top
    anchors.bottom: spellList.bottom
    anchors.right: spellList.right
    step: 14
    pixels-scroll: true

  UIWidget
    id: separator
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: bottomBar.top
    margin-bottom: 5
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #333333

  Panel
    id: bottomBar
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 30
    background-color: #00000000
    margin-bottom: 5

    ComboBox
      id: worldSettings
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      width: 80
      margin-left: 8

    CheckBox
      id: target
      anchors.left: worldSettings.right
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 8
      text: Targets
      width: 68
      color: #AAAAAA
      font: verdana-11px-rounded

    CheckBox
      id: enemy
      anchors.left: target.right
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
      text: Enemies
      width: 72
      color: #AAAAAA
      font: verdana-11px-rounded

    CheckBox
      id: guild
      anchors.left: enemy.right
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
      text: Guilds
      width: 65
      color: #AAAAAA
      font: verdana-11px-rounded

    Label
      id: warnText
      anchors.left: guild.right
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 8
      color: #FFFF00
      font: verdana-11px-rounded
      text-auto-resize: true

    UIWidget
      id: closeButton
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 8
      width: 70
      height: 22
      text: FECHAR
      background-color: #00000000
      border-width: 1
      border-color: #446688
      color: #FFFFFF
      font: verdana-11px-rounded
      text-align: center
      focusable: true

]], g_ui.getRootWidget())

timeEnemy.interface:hide()
timeEnemy.interface:setPosition({
  x = math.floor((g_ui.getRootWidget():getWidth()  - 500) / 2),
  y = math.floor((g_ui.getRootWidget():getHeight() - 380) / 2)
})

storage.timeEnemyInterfacePos = storage.timeEnemyInterfacePos or nil

timeEnemy.interface.onDragEnter = function(widget, mousePos)
  if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
  widget:breakAnchors()
  widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
  return true
end

timeEnemy.interface.onDragMove = function(widget, mousePos, moved)
  local parentRect = widget:getParent():getRect()
  local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
  local y = math.min(math.max(parentRect.y, mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
  widget:move(x, y)
  return true
end

timeEnemy.interface.onDragLeave = function(widget, pos)
  storage.timeEnemyInterfacePos = {x = widget:getX(), y = widget:getY()}
  return true
end

timeEnemy.interface.spellName     = timeEnemy.interface.inputArea.spellName
timeEnemy.interface.onScreen      = timeEnemy.interface.inputArea.onScreen
timeEnemy.interface.cooldownTotal = timeEnemy.interface.inputArea.cooldownTotal
timeEnemy.interface.cooldownAtivo = timeEnemy.interface.inputArea.cooldownAtivo
timeEnemy.interface.addButton     = timeEnemy.interface.addButton
timeEnemy.interface.worldSettings = timeEnemy.interface.bottomBar.worldSettings
timeEnemy.interface.warnText      = timeEnemy.interface.bottomBar.warnText
timeEnemy.interface.closeButton   = timeEnemy.interface.bottomBar.closeButton
timeEnemy.buttons.target          = timeEnemy.buttons.target
timeEnemy.buttons.enemy           = timeEnemy.buttons.enemy
timeEnemy.buttons.guild           = timeEnemy.buttons.guild

local iTarget = timeEnemy.interface.bottomBar.target
local iEnemy  = timeEnemy.interface.bottomBar.enemy
local iGuild  = timeEnemy.interface.bottomBar.guild

local function hide_logic()
  if not timeEnemy.interface:isVisible() then
    if storage.timeEnemyInterfacePos then
      timeEnemy.interface:setPosition(storage.timeEnemyInterfacePos)
    end
    timeEnemy.interface:show()
  else
    timeEnemy.interface:hide()
    timeEnemy.save()
  end
end

local warning_text = function(text)
    local widget = timeEnemy.interface.warnText;
    widget:setVisible(true);
    widget:setText(text);
    schedule(2000, function()
        widget:setText("");
        widget:setVisible(false);
    end);
end

timeEnemy.interface.closeButton.onClick = hide_logic;
timeEnemy.buttons.settings.onClick = hide_logic;
timeEnemy.buttons.title.onClick = function(widget)
    enemy_data.enabled = not enemy_data.enabled;
    widget:setOn(enemy_data.enabled);
    timeEnemy.widget:setVisible(enemy_data.enabled);
    timeEnemy.save();
end

timeEnemy.clear = function()
    timeEnemy.interface.spellName:setText("");
    timeEnemy.interface.onScreen:setText("");
    timeEnemy.interface.cooldownAtivo:setValue(0);
    timeEnemy.interface.cooldownTotal:setValue(0);
end

timeEnemy.addOption = function()
    local worldName = g_game.getWorldName();
    timeEnemy.interface.worldSettings:addOption(worldName);
    timeEnemy.interface.worldSettings:setOption(worldName);
end

timeEnemy.checkBoxes = function()
    iTarget:setChecked(enemy_data.target or false);
    iEnemy:setChecked(enemy_data.enemy or false);
    iGuild:setChecked(enemy_data.guild or false);
    timeEnemy.buttons.target:setChecked(enemy_data.target or false);
    timeEnemy.buttons.enemy:setChecked(enemy_data.enemy or false);
    timeEnemy.buttons.guild:setChecked(enemy_data.guild or false);
end

timeEnemy.onLoading = function()
    timeEnemy.load();
    timeEnemy.checkBoxes();
    timeEnemy.clear();
    timeEnemy.addOption();
    timeEnemy.refreshList();
    timeEnemy.buttons.title:setOn(enemy_data.enabled or false);
    timeEnemy.widget:setVisible(enemy_data.enabled or false);
end

timeEnemy.refreshList = function()
    for i, child in pairs(timeEnemy.interface.spellList:getChildren()) do
        child:destroy();
    end
    enemy_data.spells = enemy_data.spells or {};
    for index, entry in ipairs(enemy_data.spells) do
        local label = setupUI(spellEntryTimeSpell, timeEnemy.interface.spellList);

        label.enabled:setChecked(entry.enabled);
        label.enabled.onClick = function(widget)
            entry.enabled = not entry.enabled;
            label.enabled:setChecked(entry.enabled);
            timeEnemy.save();
        end;

        label.text:setText(entry.spellName .. " -> " .. entry.onScreen);
        label.acLabel:setText("AC " .. entry.cooldownActive .. "s");
        label.acLabel:setColor("#00CCCC");
        label.cdLabel:setText("CD " .. entry.cooldownTotal .. "s");
        label.cdLabel:setColor("#CC4444");

        label:setTooltip("On Screen: " .. entry.onScreen .. " | CD Ativo: " .. entry.cooldownActive .. " | CD Total: " .. entry.cooldownTotal);

        label.removeBtn.onClick = function(widget)
            table.remove(enemy_data.spells, index);
            timeEnemy.save();
            timeEnemy.refreshList();
        end;

        label.onDoubleClick = function(widget)
            timeEnemy.interface.spellName:setText(entry.spellName);
            timeEnemy.interface.onScreen:setText(entry.onScreen);
            timeEnemy.interface.cooldownAtivo:setValue(entry.cooldownActive);
            timeEnemy.interface.cooldownTotal:setValue(entry.cooldownTotal);
            table.remove(enemy_data.spells, index);
            timeEnemy.save();
            timeEnemy.refreshList();
        end;
    end
end

timeEnemy.doCheckCreature = function(name)
    if (name == player:getName():lower()) then
        return false;
    end
    if (enemy_data.target and g_game.isAttacking()) then
        local attacking = g_game.getAttackingCreature();
        if attacking and attacking:getName() == name then
            return true;
        end
    end
    if enemy_data.enemy then
        local findCreature = getCreatureByName(name);
        if not findCreature then return false; end
        if (findCreature:getEmblem() ~= 1) then
            return true;
        end
    end
    if enemy_data.guild then
        local findCreature = getCreatureByName(name);
        if not findCreature then return false; end
        if ((findCreature:getEmblem() ~= 1) or findCreature:isPartyMember()) then
            return true;
        end
    end
    return false;
end

timeEnemy.interface.cooldownAtivo.onValueChange = function(widget, value)
    widget:setText(value .. "s");
end

timeEnemy.interface.cooldownTotal.onValueChange = function(widget, value)
    widget:setText(value .. "s");
end

iTarget.onCheckChange = function(widget, checked)
    enemy_data.target = checked;
    timeEnemy.buttons.target:setChecked(checked);
    timeEnemy.save();
end

iEnemy.onCheckChange = function(widget, checked)
    enemy_data.enemy = checked;
    timeEnemy.buttons.enemy:setChecked(checked);
    timeEnemy.save();
end

iGuild.onCheckChange = function(widget, checked)
    enemy_data.guild = checked;
    timeEnemy.buttons.guild:setChecked(checked);
    timeEnemy.save();
end

timeEnemy.buttons.target.onCheckChange = function(widget, checked)
    enemy_data.target = checked;
    iTarget:setChecked(checked);
    timeEnemy.save();
end

timeEnemy.buttons.enemy.onCheckChange = function(widget, checked)
    enemy_data.enemy = checked;
    iEnemy:setChecked(checked);
    timeEnemy.save();
end

timeEnemy.buttons.guild.onCheckChange = function(widget, checked)
    enemy_data.guild = checked;
    iGuild:setChecked(checked);
    timeEnemy.save();
end

timeEnemy.interface.addButton.onClick = function()
    local spellName     = timeEnemy.interface.spellName:getText():lower():trim();
    local onScreen      = timeEnemy.interface.onScreen:getText();
    local cooldownAtivo = timeEnemy.interface.cooldownAtivo:getValue();
    local cooldownTotal = timeEnemy.interface.cooldownTotal:getValue();

    if not spellName or spellName:len() == 0 then
        warning_text("Spell Name Invalida.");
        return;
    end
    if not onScreen or onScreen:len() == 0 then
        warning_text("On Screen Invalida.");
        return;
    end
    if not cooldownAtivo or cooldownAtivo == 0 then
        warning_text("Cooldown Ativo Invalido.");
        return;
    end
    if not cooldownTotal or cooldownTotal == 0 then
        warning_text("Cooldown Total Invalido.");
        return;
    end

    enemy_data.spells = enemy_data.spells or {};
    table.insert(enemy_data.spells, {
        enabled        = true,
        spellName      = spellName,
        onScreen       = onScreen,
        cooldownActive = cooldownAtivo,
        cooldownTotal  = cooldownTotal
    });

    warning_text("Spell Inserida com Sucesso.");
    timeEnemy.save();
    timeEnemy.clear();
    timeEnemy.refreshList();
end

macro(100, function()
    if not timeEnemy.widget:isVisible() then return end
    timeEnemy.widget.enemyList:destroyChildren()
    storage._enemy = storage._enemy or {}

    for index = #storage._enemy, 1, -1 do
        if storage._enemy[index].totalCooldown <= os.time() then
            table.remove(storage._enemy, index)
        end
    end

    local grouped = {}
    local order = {}
    for _, entry in ipairs(storage._enemy) do
        if not grouped[entry.playerName] then
            grouped[entry.playerName] = {}
            table.insert(order, entry.playerName)
        end
        table.insert(grouped[entry.playerName], entry)
    end

    for _, name in ipairs(order) do
        table.sort(grouped[name], function(a, b)
            local aTime = a.activeCooldown >= os.time() and (a.activeCooldown - os.time()) or (a.totalCooldown - os.time())
            local bTime = b.activeCooldown >= os.time() and (b.activeCooldown - os.time()) or (b.totalCooldown - os.time())
            return aTime < bTime
        end)
    end

    table.sort(order, function(a, b)
        local aEntry = grouped[a][1]
        local bEntry = grouped[b][1]
        local aTime = aEntry.activeCooldown >= os.time() and (aEntry.activeCooldown - os.time()) or (aEntry.totalCooldown - os.time())
        local bTime = bEntry.activeCooldown >= os.time() and (bEntry.activeCooldown - os.time()) or (bEntry.totalCooldown - os.time())
        return aTime < bTime
    end)

    local now_t = os.time()

    for _, name in ipairs(order) do
        local header = setupUI(timer_add, timeEnemy.widget.enemyList)
        header:setColoredText({"[ " .. name .. " ] ", "yellow", "(" .. #grouped[name] .. ")", "orange"})

        for _, entry in ipairs(grouped[name]) do
            local label = setupUI(timer_add, timeEnemy.widget.enemyList)
            local remaining = entry.activeCooldown >= now_t
                and (entry.activeCooldown - now_t)
                or  (entry.totalCooldown - now_t)
            local warning = remaining <= 5

            if entry.activeCooldown >= now_t then
                local col = warning and "yellow" or "teal"
                label:setColoredText({
                    "  " .. entry.onScreen, "white",
                    "  [ AC: ", col,
                    remaining, col,
                    "s ]", col
                })
            else
                local col = warning and "yellow" or "red"
                label:setColoredText({
                    "  " .. entry.onScreen, "white",
                    "  [ CD: ", col,
                    remaining, col,
                    "s ]", col
                })
            end

            if warning then
                local visible = math.floor(now_t * 2) % 2 == 0
                label:setVisible(visible)
            end
        end
    end
end)

onTalk(function(name, level, mode, text, channelId, pos)
    if not timeEnemy.doCheckCreature(name) then return; end
    enemy_data.spells = enemy_data.spells or {};
    text = text:lower():trim();
    for _, entry in ipairs(enemy_data.spells) do
        if entry.enabled and (entry.spellName == text) then
            local activeCooldown = os.time() + entry.cooldownActive;
            local totalCooldown  = os.time() + entry.cooldownTotal;
            storage._enemy = storage._enemy or {};
            table.insert(storage._enemy, {
                playerName     = name,
                onScreen       = entry.onScreen,
                activeCooldown = activeCooldown,
                totalCooldown  = totalCooldown
            });
        end
    end
end);

timeEnemy.onLoading();