panel = mainTab;
os = os or modules.os;

local DIR_NORTH = 0;
local DIR_EAST = 1;
local DIR_SOUTH = 2;
local DIR_WEST = 3;

local TYPE_FUGA = "Fugas";
local TYPE_TRAP = "Traps";
local TYPE_STACK = "Stack";
local TYPE_RETA = "Retas";
local TYPE_BUFF = "Buffs";
local TYPE_NORMAL = "Especiais";

local ESPECIAIS_OPTIONS = {TYPE_FUGA, TYPE_TRAP, TYPE_STACK, TYPE_RETA, TYPE_BUFF, TYPE_NORMAL};
local STOP_ITER = {TYPE_FUGA, TYPE_TRAP};
local SHOW_SPELL_TIME = {TYPE_FUGA, TYPE_TRAP, TYPE_NORMAL};
local WASD_KEYS = {"W", "A", "S", "D", "E", "Z", "Q", "C"};
local ARROW_KEYS = {"Up", "Down", "Left", "Right"};
local DELAYS = {};
battlePanel = "battlePanel = g_ui.getRootWidget():%s('battlePanel')";
gameMapPanel = "gameMapPanel = g_ui.getRootWidget():%s('gameMapPanel')";
gameRootPanel = "gameRootPanel = g_ui.getRootWidget():%s('gameRootPanel')";

local rec_ch_by_id = {"r", "e", "c", "u", "r", "s", "i", "v", "e", "G", "e", "t", "C", "h", "i", "l", "d", "B", "y", "I", "d"};
rec_ch_by_id = table.concat(rec_ch_by_id);
for _, val in ipairs({battlePanel, gameMapPanel, gameRootPanel}) do
  local content = val:format(rec_ch_by_id);
  loadstring(content)();
end

local isMobile = modules._G.g_app.isMobile();
local START_POS = {x = 50, y = 50};
local ATTACKING_COLORS = {'#FF8888', '#FF0000'};
local isMainKeyPressed = function()
  if (isMobile) then
    return modules.corelib.g_keyboard.isKeyPressed("F2");
  else
    return modules.corelib.g_keyboard.isCtrlPressed();
  end
end

local TITLE = "Especiais - Config";
local characterName = g_game.getCharacterName();
local worldName = g_game.getWorldName();

storage.especiaisConfig = storage.especiaisConfig or {};
storage.especiaisConfig[worldName] = storage.especiaisConfig[worldName] or {};
if (storage.especiaisConfig[characterName]) then
  storage.especiaisConfig[worldName][characterName] = storage.especiaisConfig[characterName];
  storage.especiaisConfig[characterName] = nil;
end
storage.especiaisConfig[worldName][characterName] = storage.especiaisConfig[worldName][characterName] or {};

local config = storage.especiaisConfig[worldName][characterName];
if (config.macroActive == nil) then
  config.macroActive = true;
end
config.spells = config.spells or {};

for spell, value in pairs(config.spells) do
  if (not value.index) then
    config.spells[spell] = nil;
  elseif (not value.castSpellName) then
    value.castSpellName = spell;
  end
  if (value.type == TYPE_STACK and value.activeTotal) then
    value.distance = 5;
    value.activeTotal = nil;
  end
end

onCreatureHealthPercentChange(function(creature, percent)
  if (creature ~= player) then return; end
  if (not percent) then return; end
  if (creature.percent) then
    local diff = percent - creature.percent;
    if (diff >= 60) then
      for spellName, entry in pairs(config.spells) do
        if (entry.type == TYPE_FUGA) then
          entry.activeTime = nil;
        end
      end
    end
  end
  creature.percent = percent;
end)

local IMPORT = storage.fugasConfig and storage.fugasConfig[characterName];
IMPORT = IMPORT and IMPORT.spells;
if (IMPORT) then
  for spell, value in pairs(IMPORT) do
    if (type(value) ~= "table") then
      if (config.spells[spell]) then
        config.spells[spell] = nil
      end
    else
      if (not config.spells[spell]) then
        config.spells[spell] = {};
        local SPELL_VALUE = config.spells[spell];
        SPELL_VALUE.castSpellName = key;
        SPELL_VALUE.spellName = value.spellName;
        SPELL_VALUE.cooldownTotal = value.cooldown;
        SPELL_VALUE.activeTotal = value.active;
        SPELL_VALUE.type = TYPE_FUGA;
        SPELL_VALUE.percent = 100;
        SPELL_VALUE.enabled = value.enabled;
        SPELL_VALUE.index = table.size(config.spells) + 1;
      end
    end
  end
end

config.attackers = config.attackers or {};

message = modules.game_bot.message;
info = function(text) return message("info", tostring(text)); end
warn = function(text) return message("warn", tostring(text)); end
warning = warn;
error = function(text) return message("error", tostring(text)); end

function string:ucwords()
    local cases = {" ", ":", ""};
    for index, case in ipairs(cases) do
        cases[case] = true;
        cases[index] = nil;
    end
    local newStr = "";
    self = self:lower();
    for i = 1, #self do
        local str = self:sub(i, i);
        local previous = self:sub(i - 1, i - 1);
        if (cases[previous]) then
            str = str:upper();
        end
        newStr = newStr .. str;
    end
    return newStr:trim();
end

local function ORANGE_RAINBOW(widget, color, status)
  if (not status) then
    if (color.g > 117) then
      color.g = color.g - 1;
    elseif color.b < 24 then
      color.b = color.b + 1;
    else
      status = true;
    end
  else
    if (color.b > 0) then
      color.b = color.b - 1;
    elseif (color.g < 165) then
      color.g = color.g + 1;
    else
      status = nil;
    end
  end
  widget:setColor(color);
  schedule(50, function()
    ORANGE_RAINBOW(widget, color, status);
  end)
end

local spellsCaster = setupUI([[
Panel
  height: 17
  BotSwitch
    id: macro
    anchors.top: parent.top
    anchors.left: parent.left
    text-align: center
    width: 130
    !text: tr("Especiais")
  Button
    id: configs
    anchors.top: prev.top
    anchors.left: prev.right
    anchors.right: parent.right
    margin-left: 3
    height: 17
    text: Config
]]);

spellsCaster.configs.onClick = function()
  spellsCaster.window:show();
  spellsCaster.doGameFocus();
end

spellsCaster.widgets = {};

local ASSERT_DIR_KEYS = {
  ["W"] = "Up",
  ["S"] = "South",
  ["A"] = "Left",
  ["D"] = "Right"
}

spellsCaster.stackDirections = {
  ["W"] = function(fromPos, toPos, further)
    if (fromPos.y < toPos.y) then
      local distance = math.abs(fromPos.y - toPos.y);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end,
  ["D"] = function(fromPos, toPos, further)
    if (fromPos.x > toPos.x) then
      local distance = math.abs(fromPos.x - toPos.x);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end,
  ["S"] = function(fromPos, toPos, further)
    if (fromPos.y > toPos.y) then
      local distance = math.abs(fromPos.y - toPos.y);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end,
  ["A"] = function(fromPos, toPos, further)
     if (fromPos.x < toPos.x) then
      local distance = math.abs(fromPos.x - toPos.x);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end,
  ["C"] = function(fromPos, toPos, further)
    if (fromPos.x > toPos.x and fromPos.y > toPos.y) then
      local distance = spellsCaster.preciseDistance(fromPos, toPos);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end,
  ["Z"] = function(fromPos, toPos, further)
    if (fromPos.x < toPos.x and fromPos.y > toPos.y) then
      local distance = spellsCaster.preciseDistance(fromPos, toPos);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end,
  ["Q"] = function(fromPos, toPos, further)
    if (fromPos.x < toPos.x and fromPos.y < toPos.y) then
      local distance = spellsCaster.preciseDistance(fromPos, toPos);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end,
  ["E"] = function(fromPos, toPos, further)
     if (fromPos.x > toPos.x and fromPos.y < toPos.y) then
      local distance = spellsCaster.preciseDistance(fromPos, toPos);
      if (not further or further.distance < distance) then
        return true, distance;
      end
    end
  end
};

for key, value in pairs(ASSERT_DIR_KEYS) do
  spellsCaster.stackDirections[value] = spellsCaster.stackDirections[key];
end

spellsCaster.getSpectators = function(multifloor)
  local specs = getSpectators(multifloor);
  if (#specs == 0) then
    local tiles = g_map.getTiles(posz());
    for _, tile in ipairs(tiles) do
      for _, spec in ipairs(tile:getCreatures()) do
        table.insert(specs, spec);
      end
    end
  end
  return specs;
end

function spellsCaster:getStackingMonster(dir, entry)
  local isInCorrectDirection = spellsCaster.stackDirections[dir];
  if (not isInCorrectDirection) then return; end
  local stack;
  local specs = spellsCaster.getSpectators();
  local pos = pos();
  for _, spec in ipairs(specs) do
    local specPos = spec:getPosition();
    local status, distance = isInCorrectDirection(specPos, pos, stack);
    if (status and spec:isMonster()) then
      if (getDistanceBetween(specPos, pos) <= entry.distance) then
        if (spec:canShoot()) then
          stack = {spec=spec, distance=distance};
        end
      end
    end
  end
  return stack and stack.spec;
end

function spellsCaster.preciseDistance(p1, p2)
    local distx = math.abs(p1.x - p2.x);
    local disty = math.abs(p1.y - p2.y);
    return math.sqrt(distx * distx + disty * disty);
end

function spellsCaster.correctDirection()
    local dir = player:getDirection();
  return dir <= 3 and dir or dir < 6 and 1 or 3;
end

function spellsCaster.getLowestBetween(p1, p2)
  local distx = math.abs(p1.x - p2.x);
  local disty = math.abs(p1.y - p2.y);
  return math.min(distx, disty);
end

spellsCaster.directions = {
  {x = 0, y = -1},
  {x = 1, y = 0},
  {x = 0, y = 1},
  {x = -1, y = 0}
};

function spellsCaster:getUsePosition(pos)
  local nearestPosition;
  local playerPos = player:getPosition();
  local targetPos = pos;
  local distance = {x = math.abs(playerPos.x - pos.x), y = math.abs(playerPos.y - pos.y)};
  if (distance.y >= distance.x) then
    if (
      (targetPos.y > playerPos.y) or
      (targetPos.y < playerPos.y and targetPos.x < playerPos.x) or
      (targetPos.y < playerPos.x and targetPos.x > playerPos.x)
    ) then
      targetPos.x = targetPos.x + 1
    elseif (
      (targetPos.x > playerPos.x) or
      (targetPos.x < playerPos.x and targetPos.y > playerPos.x) or
      (targetPos.x > playerPos.y and targetPos.x < playerPos.x)
    ) then
      targetPos.x = targetPos.x - 1
    end
  else
    if (
      (targetPos.x < playerPos.x) or
      (targetPos.y > playerPos.y) or
      (targetPos.x > playerPos.x and targetPos.y > playerPos.y)
    ) then
      targetPos.y = targetPos.y + 1
    elseif (
      (targetPos.y < playerPos.y) or
      (targetPos.y > playerPos.y and targetPos.x > playerPos.x) or
      (targetPos.x < playerPos.x and targetPos.y < playerPos.y)
    ) then
      targetPos.y = targetPos.y - 1
    end
  end
  return targetPos;
end

function spellsCaster:canUseReta(creature)
  local creaturePos = creature:getPosition();
  if (not creaturePos) then return; end
  local playerPos = pos();
  local distance = getDistanceBetween(playerPos, creaturePos);
  local lowest = self.getLowestBetween(playerPos, creaturePos);
  if (distance > 0 and distance <= 4 and lowest == 0) then
    local direction = self.correctDirection();
    if (playerPos.x > creaturePos.x) then
      turn(DIR_WEST);
      return direction == DIR_WEST;
    elseif (playerPos.x < creaturePos.x) then
      turn(DIR_EAST);
      return direction == DIR_EAST;
    elseif (playerPos.y > creaturePos.y) then
      turn(DIR_NORTH);
      return direction == DIR_NORTH;
    elseif (playerPos.y < creaturePos.y) then
      turn(DIR_SOUTH);
      return direction == DIR_SOUTH;
    end
  elseif (distance <= 1) then
    if (lowest ~= 0 or distance == 0) then
      local closestPos;
      for _, dir in ipairs(self.directions) do
        local pos = {x = creaturePos.x + dir.x, y = creaturePos.y + dir.y, z = creaturePos.z};
        if (
          not closestPos or
          self.preciseDistance(pos, playerPos) < self.preciseDistance(closestPos, playerPos)
        ) then
          local tile = g_map.getTile(pos);
          if (tile and tile:isWalkable() and tile:isPathable()) then
            closestPos = pos;
          end
        end
      end
      if (closestPos) then
        player:autoWalk(closestPos);
        DELAYS.Retas = now + 300;
        return;
      end
    end
  else
    local pos = self:getUsePosition(creaturePos);
    if (not pos) then return; end
    local tile = g_map.getTile(pos);
    if (not tile) then return; end
    g_game.use(tile:getTopThing());
  end
end

local SAVE_DIR  = "/bot/" .. modules.game_bot.contentsPanel.config:getCurrentOption().text .. "/especiais/"
local SAVE_FILE = SAVE_DIR .. worldName .. "_" .. characterName .. ".json"

if not g_resources.directoryExists(SAVE_DIR) then
  g_resources.makeDir(SAVE_DIR)
end

local function saveEspeciaisConfig()
  local ok, result = pcall(function() return json.encode(config, 2) end)
  if ok then g_resources.writeFileContents(SAVE_FILE, result) end
end

if g_resources.fileExists(SAVE_FILE) then
  local ok, result = pcall(function() return json.decode(g_resources.readFileContents(SAVE_FILE)) end)
  if ok and result then
    for k, v in pairs(result) do
      if k ~= "attackers" then
        config[k] = v
      end
    end
    for spell, value in pairs(config.spells) do
      if type(value) == "table" then
        value.cooldownTime = nil
        value.activeTime   = nil
      end
    end
  end
end

local emergencyHpHistory = {}
local emergencyTriggered  = false
local EMERGENCY_DROP      = config.emergencyDrop or 15

local function checkEmergency(currentHp)
  local now_s = os.time()
  table.insert(emergencyHpHistory, {hp = currentHp, time = now_s})
  while #emergencyHpHistory > 0 and now_s - emergencyHpHistory[1].time > 1 do
    table.remove(emergencyHpHistory, 1)
  end
  if #emergencyHpHistory >= 2 then
    local oldest = emergencyHpHistory[1].hp
    local drop = oldest - currentHp
    if drop >= EMERGENCY_DROP then
      return true
    end
  end
  return false
end

local reactionDamageThreshold = config.reactionDamage or 10
local lastHpAbsolute = nil

spellsCaster.getAttackersSum = function()
  local attackers = table.size(config.attackers);
  attackers = attackers < 6 and attackers or 6;
  return attackers * 5;
end

spellsCaster.autoPercentage = function()
  local sumPercent = spellsCaster.getAttackersSum();
  local percent = 45 + sumPercent;
  return percent;
end

onTextMessage(function(mode, text)
  if (not text:find("attack by")) then return; end
  for _, spec in ipairs(spellsCaster.getSpectators()) do
    if (spec:isPlayer()) then
      local specName = spec:getName();
      if (text:find(specName)) then
        config.attackers[specName] = os.time() + 1;
        break
      end
    end
  end
end)

macro(1, function()
  for name, time in pairs(config.attackers) do
    if (time < os.time() or time - 1 > os.time()) then
      config.attackers[name] = nil;
    end
  end
end)

onCreatureHealthPercentChange(function(creature, percent)
  if creature ~= player then return end
  if not percent then return end
  if not lastHpAbsolute then
    lastHpAbsolute = percent
    return
  end
  local dmgPct = lastHpAbsolute - percent
  if dmgPct >= reactionDamageThreshold then
    if spellsCaster.spells and spellsCaster.spells[TYPE_BUFF] then
      for _, value in ipairs(spellsCaster.spells[TYPE_BUFF]) do
        local entry = config.spells[value.castSpellName]
        if entry and entry.enabled and entry.reactionBuff then
          if not entry.cooldownTime or entry.cooldownTime < os.time() then
            say(entry.spellName)
            entry.cooldownTime = os.time() + entry.cooldownTotal
            saveEspeciaisConfig()
            break
          end
        end
      end
    end
  end
  lastHpAbsolute = percent
end)

spellsCaster.canCast = function(entry, ignoreCD)
  if (not entry.enabled) then return; end
  if (entry.type == TYPE_BUFF and storage.sealedTypes and storage.sealedTypes.buff and storage.sealedTypes.buff >= os.time()) then return; end
  if (not ignoreCD) then
    if (entry.cooldownTime and entry.cooldownTime >= os.time() and entry.cooldownTime - entry.cooldownTotal <= os.time()) then return false; end
  end

  if (entry.type == TYPE_STACK) then
    if (not entry.selectedKeys) then
      entry.selectedKeys = entry.key == "WASD" and WASD_KEYS or ARROW_KEYS;
    end
    local isMousePressed = g_mouse.isPressed(3);
    for _, dir in ipairs(entry.selectedKeys) do
      if (isMousePressed and modules.corelib.g_keyboard.isKeyPressed(dir)) then
        local creature = spellsCaster:getStackingMonster(dir, entry);
        if (creature) then
          g_game.attack(creature);
          creature:setText("STACKING!", "green");
          schedule(200, function()
            g_game.cancelAttack()
            schedule(800, function()
              creature:clearText();
            end)
          end);
          return true;
        end
      end
    end
  elseif (entry.type == TYPE_RETA) then
    local target = spellsCaster.getAttackingCreature();
    if (target) then
      if (entry.key == "AUTO" or modules.corelib.g_keyboard.isKeyPressed(entry.key)) then
        if (spellsCaster:canUseReta(target)) then
          return true;
        end
      end
    end
  else
    if (entry.key) then
      if (entry.key ~= 'AUTO') then
        if (modules.corelib.g_keyboard.isKeyPressed(entry.key)) then
          return true;
        end
      elseif (entry.type ~= TYPE_FUGA) then
        if (entry.type ~= TYPE_BUFF) then
          local target = spellsCaster.getAttackingCreature();
          if not target then return false end
          if not target:isPlayer() then return false end
          if entry.targetPercent then
            local tp = target:getHealthPercent()
            if tp and tp > entry.targetPercent then return false end
          end
          return true;
        else
          if entry.autoReactivate then
            local inPvp = table.size(config.attackers) > 0
            return inPvp
          end
          return true;
        end
      end
    end
    if (entry.percent) then
      local healthPercent = hppercent();
      local percent = entry.percent;
      if (percent == 100) then
        return healthPercent < spellsCaster.autoPercentage();
      else
        percent = percent + spellsCaster.getAttackersSum();
        percent = percent > 90 and 90 or percent;
        return healthPercent < percent;
      end
    end
  end
end

spellsCaster.hasAnyActive = function(type)
  local spells = spellsCaster.spells[type];
  if (#spells == 0) then return; end
  local os_time = os.time();
  for _, value in ipairs(spells) do
    local castName = value.castSpellName;
    local entry = config.spells[castName];
    if entry.enableLifes and entry.lifes and entry.lifes > 0 and entry.activeTime and entry.activeTime > os_time then
      return true;
    end
    if (entry.activeTime and entry.activeTime > os_time and entry.activeTotal and entry.activeTime - entry.activeTotal < os_time) then
      return true;
    end
    if (entry.cooldownTime and entry.cooldownTime > os_time) then
      return true;
    end
  end
end

spellsCaster.getFugaEffectivePercent = function(entry)
  if not entry.percent then return 999 end
  if entry.percent == 100 then
    return spellsCaster.autoPercentage()
  else
    local p = entry.percent + spellsCaster.getAttackersSum()
    return p > 90 and 90 or p
  end
end

spellsCaster.doCasting = function(type)
  local delay = DELAYS[type];
  if (delay and delay >= now) then return; end
  local spells = spellsCaster.spells[type];
  if (#spells == 0) then return; end
  if (table.find(STOP_ITER, type) and spellsCaster.hasAnyActive(type)) then return; end

  local sorted = spells;
  if (type == TYPE_FUGA) then
    sorted = {};
    for _, v in ipairs(spells) do
      table.insert(sorted, v);
    end
    table.sort(sorted, function(a, b)
      local ea = config.spells[a.castSpellName];
      local eb = config.spells[b.castSpellName];
      local pa = ea and spellsCaster.getFugaEffectivePercent(ea) or 0;
      local pb = eb and spellsCaster.getFugaEffectivePercent(eb) or 0;
      if (pa ~= pb) then return pa > pb; end
      return a.index < b.index;
    end);
  end

  local ignoreCD = false
  if type == TYPE_FUGA then
    local currentHp = hppercent()
    if checkEmergency(currentHp) and not emergencyTriggered then
      emergencyTriggered = true
      ignoreCD = true
      schedule(3000, function() emergencyTriggered = false end)
      warn("EMERGENCIA! Fuga ignorando cooldown!")
    end
  end

  for _, value in ipairs(sorted) do
    local entry = config.spells[value.castSpellName];
    if (entry and spellsCaster.canCast(entry, ignoreCD)) then
      if (entry.type ~= TYPE_BUFF) then
        stopCombo = now + 300;
        if (entry.type == TYPE_FUGA) then
          regen_delay = now + 300;
        end
      end
      DELAYS[type] = now + 300;
      saveEspeciaisConfig()
      return say(entry.spellName);
    end
  end
end

spellsCaster.baseMacro = macro(1, function()
  if (not config.macroActive) then return; end
  if (not spellsCaster.spells) then return; end
  if (isInPz()) then return; end
  for _, type in ipairs(ESPECIAIS_OPTIONS) do
    spellsCaster.doCasting(type);
  end
end)

spellsCaster.visibleMacro = spellsCaster.macro;

function spellsCaster.visibleMacro.onClick(widget)
  config.macroActive = not config.macroActive;
  status = config.macroActive;
  widget:setOn(status);
  spellsCaster.refreshSpells();
end

local status, result = pcall(function() spellsCaster.visibleMacro:setOn(config.macroActive) end);
if (not status) then return reload(); end

spellsCaster.destroyWidget = function(key)
  spellsCaster.widgets[key]:destroy();
  spellsCaster.widgets[key] = nil;
end

spellsCaster.destroyAllWidgets = function()
  for _, child in ipairs(spellsCaster.window.mainPanel.especiaisList:getChildren()) do
    child:destroy();
  end
  for key, widget in pairs(spellsCaster.widgets) do
    spellsCaster.destroyWidget(key);
  end
end

spellsCaster.widget = [[
UIWidget
  background-color: black
  padding: 0 5
  text-auto-resize: true
]];

spellsCaster.setupWidget = function(key)
  spellsCaster.widgets[key] = setupUI(spellsCaster.widget, g_ui.getRootWidget());
  local widget = spellsCaster.widgets[key];
  spellsCaster.doRemoveMouseMove(key);
  widget.pressed = false;
  local widgetPos;
  if (key ~= 'battlingStatus') then
    widgetPos = config.spells[key].pos;
  else
    widgetPos = config.battlePos;
  end
  widget:setPosition(widgetPos or START_POS);
end

spellsCaster.doRemoveMouseMove = function(key)
  local widget = spellsCaster.widgets[key];
  widget.onDragEnter = nil;
  widget.onDragMove = nil;
  widget:setFocusable(false);
  widget:setPhantom(true);
  widget:setDraggable(false);
  widget:setOpacity(0.7);
end

spellsCaster.doSetMouseMove = function(key)
  local widget = spellsCaster.widgets[key];
  widget:setFocusable(true);
  widget:setPhantom(false);
  widget:setDraggable(true);
  widget:setOpacity(1);

  widget.onDragEnter = function(widget, mousePos)
    widget:breakAnchors();
    widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()};
    return true;
  end

  widget.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect();
    local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth());
    local y = math.min(math.max(parentRect.y - widget:getParent():getMarginTop(), mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight());
    widget:move(x, y);
    local pos = {x = x, y = y};
    if (key ~= 'battlingStatus') then
      config.spells[key].pos = pos;
    else
      config.battlePos = pos;
    end
    return true;
  end
end

function spellsCaster:setInfoContent(widget)
  local attackingPlayers = table.size(config.attackers);
  widget:setColor(attackingPlayers == 0 and "white" or "red");
  local content = "Oponentes: " .. attackingPlayers;
  local spells = self.getAllFromSameType(TYPE_FUGA);
  local percentCast;
  for _, entry in ipairs(spells) do
    if (not entry.cooldownTime and entry.enabled) then
      percentCast = entry.percent;
      break
    end
  end
  if (percentCast) then
    local percentSum = self.getAttackersSum();
    content = content .. " | Fuga in: " .. percentSum + percentCast .. "%";
  end
  widget:setText(content);
end

macro(1, function()
  if (not spellsCaster.widgets) then return; end
  local status = config.macroActive;
  if (not status) then return; end
  local pressed = isMainKeyPressed();
  local time = os.time();

  for key, widget in pairs(spellsCaster.widgets) do
    if (widget.pressedKey ~= pressed) then
      if (pressed) then
        spellsCaster.doSetMouseMove(key);
      else
        spellsCaster.doRemoveMouseMove(key);
      end
      widget.pressedKey = pressed;
    end
    if (key ~= "battlingStatus") then
      local storage = config.spells[key];
      local keyStr = storage and storage.key and storage.key ~= "AUTO" and " [" .. storage.key .. "]" or "";
      key = key:ucwords();
      local shownText, shownColor = key .. keyStr .. ": OK!", "green";
      if (storage and storage.activeTime and storage.activeTime >= time) then
        local sum = storage.activeTime - time;
        shownText = key .. keyStr .. ": " .. sum .. "s";
        if storage.enableLifes and storage.lifes and storage.lifes > 0 then
          shownText = "VIDAS:" .. storage.lifes .. " | " .. shownText;
        end
        shownColor = "orange";
      elseif (storage and storage.cooldownTime and storage.cooldownTime >= time) then
        local sum = storage.cooldownTime - time;
        shownText = key .. keyStr .. ": " .. sum .. "s";
        shownColor = "red";
      elseif storage.enableMultiple and storage.count and storage.count > 0 then
        shownText = "COUNT:" .. storage.count .. " | " .. key .. keyStr .. ": OK!";
        shownColor = "green";
      elseif (storage.cooldownTime or storage.activeTime) then
        storage.cooldownTime, storage.activeTime = nil, nil;
        if storage.enableMultiple then storage.canReset = false; storage.count = 3; end
        if storage.enableLifes then storage.lifes = 0; end
        if storage.enableRevive then storage.alreadyChecked = false; end
      end
      widget:setText(shownText);
      widget:setColor(shownColor);
    else
      spellsCaster:setInfoContent(widget);
    end
  end
end)

onTalk(function(name, level, mode, text)
  if (characterName ~= name) then return; end
  if (mode ~= 44) then return; end
  text = text:lower():trim();
  local castedSpell = config.spells[text];
  if (not castedSpell) then return; end
  if (castedSpell.cooldownTime and castedSpell.cooldownTime >= os.time()) then return; end

  if castedSpell.type == TYPE_FUGA then
    if castedSpell.enableLifes then
      castedSpell.activeTime   = os.time() + (castedSpell.activeTotal or 0);
      castedSpell.cooldownTime = os.time() + castedSpell.cooldownTotal;
      castedSpell.lifes        = castedSpell.amountLifes;
    elseif castedSpell.enableRevive and not castedSpell.alreadyChecked then
      castedSpell.cooldownTime   = os.time() + castedSpell.cooldownTotal;
      castedSpell.activeTime     = os.time() + (castedSpell.activeTotal or 0);
      castedSpell.alreadyChecked = true;
    elseif castedSpell.enableMultiple then
      if castedSpell.count and castedSpell.count > 0 then
        castedSpell.count      = castedSpell.count - 1;
        castedSpell.activeTime = os.time() + (castedSpell.activeTotal or 0);
        if castedSpell.count == 0 then
          castedSpell.cooldownTime = os.time() + castedSpell.cooldownTotal;
          castedSpell.canReset     = true;
        end
      end
    else
      castedSpell.cooldownTime = os.time() + castedSpell.cooldownTotal;
      if (castedSpell.activeTotal and castedSpell.activeTotal > 0) then
        castedSpell.activeTime = os.time() + castedSpell.activeTotal;
      end
    end
  else
    castedSpell.cooldownTime = os.time() + castedSpell.cooldownTotal;
    if (castedSpell.activeTotal and castedSpell.activeTotal > 0) then
      castedSpell.activeTime = os.time() + castedSpell.activeTotal;
    end
  end
end)

onTextMessage(function(mode, text)
  for key, spell in pairs(config.spells) do
    if spell.type == TYPE_FUGA and spell.enableLifes then
      if text:lower():find('morreu e renasceu') and spell.activeTime and spell.activeTime >= os.time() then
        spell.lifes = spell.lifes - 1;
        if spell.lifes <= 0 then spell.activeTime = nil; end
      end
    end
  end
end)

spellsCaster.searchWithinVariables = function()
  for key, func in pairs(g_game) do
    key = key:lower();
    if (key:match("getatt") and type(func) == "function") then
      local result = func();
      if (result) then
        if (result:isPlayer() or result:isMonster()) then
          return result;
        end
      end
    end
  end
end

spellsCaster.getAttackingCreature = function()
  local pos = pos();
  for _, child in ipairs(battlePanel:getChildren()) do
    local creature = child.creature;
    if (creature) then
      local creaturePos = creature:getPosition();
      if (creaturePos and creaturePos.z == pos.z) then
        if (table.find(ATTACKING_COLORS, child.color)) then
          return creature;
        end
      end
    end
  end
  return spellsCaster.searchWithinVariables();
end

spellsCaster.window = setupUI([[
MainWindow
  size: 670 300

  Panel
    id: mainPanel
    image-source: /images/ui/panel_flat
    anchors.top: parent.top
    anchors.left: parent.left
    image-border: 6
    size: 630 245

    TextList
      id: especiaisList
      anchors.left: parent.left
      anchors.top: parent.top
      size: 285 200
      image-border: 3
      image-source: /images/ui/textedit
      margin-top: 30
      margin-left: 10
      vertical-scrollbar: especiaisListScroll

    VerticalScrollBar
      id: especiaisListScroll
      anchors.top: especiaisList.top
      anchors.bottom: especiaisList.bottom
      anchors.right: especiaisList.right
      step: 10
      pixels-scroll: true

    Panel
      id: rightPanel
      anchors.top: parent.top
      anchors.left: especiaisList.right
      anchors.right: parent.right
      anchors.bottom: addButton.top
      margin: 5 5 0 8

      Label
        id: spellNameLabel
        text: Nome da Magia
        anchors.top: parent.top
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      TextEdit
        id: spellName
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: spellNameLabel.left
        margin: 5 5 0 0
        height: 21

      Label
        id: castSpellNameLabel
        text: Magia que Fala
        anchors.top: spellNameLabel.bottom
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      CheckBox
        id: sameAsAbove
        tooltip: Igual ao acima
        anchors.right: castSpellNameLabel.left
        anchors.top: spellName.bottom
        margin: 8 3 0 0

      TextEdit
        id: castSpellName
        anchors.top: spellName.bottom
        anchors.left: parent.left
        anchors.right: sameAsAbove.left
        margin: 5 3 0 0
        height: 21

      Label
        id: cooldownLabel
        text: Cooldown
        anchors.top: castSpellNameLabel.bottom
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      Button
        id: moveUp
        text: ^
        tooltip: Mover para cima
        anchors.right: cooldownLabel.left
        anchors.top: castSpellNameLabel.bottom
        size: 12 12
        margin: 8 3 0 0

      HorizontalScrollBar
        id: cooldownScroll
        anchors.top: castSpellNameLabel.bottom
        anchors.left: parent.left
        anchors.right: moveUp.left
        margin: 10 3 0 0
        height: 15
        step: 1

      Label
        id: activeLabel
        text: Active
        anchors.top: cooldownLabel.bottom
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      Button
        id: moveDown
        text: ^
        tooltip: Mover para baixo
        anchors.right: activeLabel.left
        anchors.top: cooldownLabel.bottom
        size: 12 12
        margin: 8 3 0 0

      HorizontalScrollBar
        id: activeScroll
        anchors.top: cooldownLabel.bottom
        anchors.left: parent.left
        anchors.right: moveDown.left
        margin: 10 3 0 0
        height: 15
        step: 1

      Label
        id: keyLabel
        text: Tecla
        anchors.top: activeLabel.bottom
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      CheckBox
        id: automaticUse
        tooltip: Automatico
        anchors.right: keyLabel.left
        anchors.top: activeLabel.bottom
        margin: 8 3 0 0

      TextEdit
        id: keyToPress_textBox
        anchors.top: activeLabel.bottom
        anchors.left: parent.left
        anchors.right: automaticUse.left
        margin: 5 3 0 0
        height: 21

      Label
        id: keyToPress
        anchors.centerIn: keyToPress_textBox
        text-auto-resize: true

      HorizontalScrollBar
        id: percentScroll
        anchors.top: activeLabel.bottom
        anchors.left: parent.left
        anchors.right: automaticUse.left
        margin: 10 3 0 0
        height: 15
        step: 1

      CheckBox
        id: WASD
        text: WASD
        anchors.top: activeLabel.bottom
        anchors.left: parent.left
        margin-top: 10
        text-auto-resize: true

      CheckBox
        id: SETAS
        text: SETAS
        anchors.top: WASD.top
        anchors.left: WASD.right
        margin-left: 5
        text-auto-resize: true

      Label
        id: lblEmergency
        text: Emerg%
        anchors.top: keyLabel.bottom
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      HorizontalScrollBar
        id: emergencyScroll
        anchors.top: keyLabel.bottom
        anchors.left: parent.left
        anchors.right: lblEmergency.left
        margin: 10 5 0 0
        height: 15
        step: 1

      Label
        id: lblReaction
        text: Reacao%
        anchors.top: keyLabel.bottom
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      HorizontalScrollBar
        id: reactionScroll
        anchors.top: keyLabel.bottom
        anchors.left: parent.left
        anchors.right: lblReaction.left
        margin: 10 5 0 0
        height: 15
        step: 1

      Label
        id: lblTargetPct
        text: Alvo%
        anchors.top: keyLabel.bottom
        anchors.right: parent.right
        margin-top: 8
        text-auto-resize: true

      HorizontalScrollBar
        id: targetPctScroll
        anchors.top: keyLabel.bottom
        anchors.left: parent.left
        anchors.right: lblTargetPct.left
        margin: 10 5 0 0
        height: 15
        step: 1

      CheckBox
        id: reactionBuffCheck
        text: Buff de Reacao
        anchors.top: keyLabel.bottom
        anchors.left: parent.left
        margin-top: 8
        text-auto-resize: true

      CheckBox
        id: autoReactivateCheck
        text: Auto Reativar
        anchors.top: reactionBuffCheck.bottom
        anchors.left: parent.left
        margin-top: 5
        text-auto-resize: true

      CheckBox
        id: reviveCheck
        text: Revive
        anchors.top: emergencyScroll.bottom
        anchors.left: parent.left
        margin-top: 10
        text-auto-resize: true

      CheckBox
        id: lifesCheck
        text: Lifes
        anchors.top: reviveCheck.top
        anchors.left: reviveCheck.right
        margin-left: 12
        text-auto-resize: true

      CheckBox
        id: multipleCheck
        text: Multiple
        anchors.top: reviveCheck.top
        anchors.left: lifesCheck.right
        margin-left: 12
        text-auto-resize: true

      SpinBox
        id: lifesValue
        anchors.top: reviveCheck.bottom
        anchors.left: parent.left
        margin-top: 5
        size: 40 20
        minimum: 1
        maximum: 10
        step: 1
        editable: true
        focusable: true

    Button
      id: addButton
      !text: tr("Adicionar")
      anchors.bottom: parent.bottom
      anchors.left: especiaisList.right
      margin-bottom: 5
      margin-left: 55

    Button
      id: closeButton
      text: Close
      anchors.bottom: parent.bottom
      anchors.right: parent.right
      width: 75
      margin-right: 15
      margin-bottom: 5

    Label
      id: displayLabel
      !text: tr('')
      anchors.top: parent.top
      anchors.right: closeButton.left
      text-auto-resize: true
      margin-right: 10
      margin-top: 8
      margin-left: 5

    ComboBox
      id: configList
      anchors.top: parent.top
      anchors.left: especiaisList.left
      margin-top: 5
      text-offset: 3 0

    ComboBox
      id: typeList
      anchors.top: prev.top
      anchors.left: prev.right
      text-offset: 3 0
      margin-left: 5

    Button
      id: importButton
      !text: tr("Importar")
      anchors.top: prev.top
      anchors.left: prev.right
      margin-left: 15

  Panel
    id: logoPanel
    anchors.top: parent.top
    anchors.right: parent.right
    size: 300 410
    margin-top: -115
    margin-right: -195
]], g_ui.getRootWidget())

spellsCaster.window:setText(TITLE);
function spellsCaster.window:setText() end;
ORANGE_RAINBOW(spellsCaster.window, {r = 255, g = 165, b = 0, a = 255});
spellsCaster.window.mainPanel.especiaisList:setBackgroundColor({a = 0})

spellsCaster.mainPanel = spellsCaster.window.mainPanel;

local rp = spellsCaster.window.mainPanel.rightPanel
spellsCaster.mainPanel.spellName           = rp.spellName
spellsCaster.mainPanel.castSpellName       = rp.castSpellName
spellsCaster.mainPanel.sameAsAbove         = rp.sameAsAbove
spellsCaster.mainPanel.cooldownScroll      = rp.cooldownScroll
spellsCaster.mainPanel.cooldownLabel       = rp.cooldownLabel
spellsCaster.mainPanel.activeScroll        = rp.activeScroll
spellsCaster.mainPanel.activeLabel         = rp.activeLabel
spellsCaster.mainPanel.keyToPress_textBox  = rp.keyToPress_textBox
spellsCaster.mainPanel.keyToPress          = rp.keyToPress
spellsCaster.mainPanel.keyLabel            = rp.keyLabel
spellsCaster.mainPanel.percentScroll       = rp.percentScroll
spellsCaster.mainPanel.automaticUse        = rp.automaticUse
spellsCaster.mainPanel.WASD                = rp.WASD
spellsCaster.mainPanel.SETAS               = rp.SETAS
spellsCaster.mainPanel.moveUp              = rp.moveUp
spellsCaster.mainPanel.moveDown            = rp.moveDown
spellsCaster.mainPanel.reactionBuffCheck   = rp.reactionBuffCheck
spellsCaster.mainPanel.autoReactivateCheck = rp.autoReactivateCheck
spellsCaster.mainPanel.emergencyScroll     = rp.emergencyScroll
spellsCaster.mainPanel.lblEmergency        = rp.lblEmergency
spellsCaster.mainPanel.reactionScroll      = rp.reactionScroll
spellsCaster.mainPanel.lblReaction         = rp.lblReaction
spellsCaster.mainPanel.targetPctScroll     = rp.targetPctScroll
spellsCaster.mainPanel.lblTargetPct        = rp.lblTargetPct
spellsCaster.mainPanel.spellNameLabel      = rp.spellNameLabel
spellsCaster.mainPanel.castSpellNameLabel  = rp.castSpellNameLabel
spellsCaster.mainPanel.reviveCheck         = rp.reviveCheck
spellsCaster.mainPanel.lifesCheck          = rp.lifesCheck
spellsCaster.mainPanel.multipleCheck       = rp.multipleCheck
spellsCaster.mainPanel.lifesValue          = rp.lifesValue

spellsCaster.mainPanel.moveDown:setRotation(180);

spellsCaster.window.mainPanel.percentScroll:hide();
spellsCaster.window.mainPanel.moveUp:hide();
spellsCaster.window.mainPanel.moveDown:hide();
spellsCaster.window.mainPanel.WASD:hide();
spellsCaster.window.mainPanel.SETAS:hide();
spellsCaster.window.mainPanel.reactionBuffCheck:hide();
spellsCaster.window.mainPanel.autoReactivateCheck:hide();
spellsCaster.window.mainPanel.targetPctScroll:hide();
spellsCaster.window.mainPanel.lblTargetPct:hide();
spellsCaster.window.mainPanel.emergencyScroll:hide();
spellsCaster.window.mainPanel.lblEmergency:hide();
spellsCaster.window.mainPanel.reactionScroll:hide();
spellsCaster.window.mainPanel.lblReaction:hide();
spellsCaster.window.mainPanel.reviveCheck:hide();
spellsCaster.window.mainPanel.lifesCheck:hide();
spellsCaster.window.mainPanel.multipleCheck:hide();
spellsCaster.window.mainPanel.lifesValue:hide();

local function scrollSetupExtra(widget, default, min, max, suffix)
  widget:setMinimum(min)
  widget:setMaximum(max)
  widget.onValueChange = function(w, v) w:setText(v .. (suffix or "")) end
  widget:setValue(default)
end

scrollSetupExtra(spellsCaster.window.mainPanel.targetPctScroll, 50, 1, 100, "%")
scrollSetupExtra(spellsCaster.window.mainPanel.emergencyScroll, EMERGENCY_DROP, 5, 50, "%")
scrollSetupExtra(spellsCaster.window.mainPanel.reactionScroll, reactionDamageThreshold, 1, 50, "%")

spellsCaster.window.mainPanel.emergencyScroll.onValueChange = function(w, v)
  w:setText(v .. "%")
  EMERGENCY_DROP = v
  config.emergencyDrop = v
  saveEspeciaisConfig()
end

spellsCaster.window.mainPanel.reactionScroll.onValueChange = function(w, v)
  w:setText(v .. "%")
  reactionDamageThreshold = v
  config.reactionDamage = v
  saveEspeciaisConfig()
end

spellsCaster.window.mainPanel.WASD.onCheckChange = function(widget, checked)
  checked = not checked;
  local SETAS = spellsCaster.window.mainPanel.SETAS;
  if (SETAS:isChecked() ~= checked) then
    SETAS:setChecked(checked);
  end
end

spellsCaster.window.mainPanel.SETAS.onCheckChange = function(widget, checked)
  checked = not checked;
  local WASD = spellsCaster.window.mainPanel.WASD;
  if (WASD:isChecked() ~= checked) then
    WASD:setChecked(checked);
  end
end

spellsCaster.window.mainPanel.lifesCheck.onCheckChange = function(widget, checked)
  if checked then
    spellsCaster.window.mainPanel.multipleCheck:hide();
    spellsCaster.window.mainPanel.lifesValue:show();
  else
    spellsCaster.window.mainPanel.multipleCheck:show();
    spellsCaster.window.mainPanel.lifesValue:hide();
  end
end

spellsCaster.window:hide();

if (isMobile) then
  error("Stack esta desativado no mobile, para mover os icones, use o botao de volume.");
  table.remove(ESPECIAIS_OPTIONS, table.find(ESPECIAIS_OPTIONS, TYPE_STACK));
end
for index = 1, #ESPECIAIS_OPTIONS do
  local option = ESPECIAIS_OPTIONS[index];
  spellsCaster.mainPanel.typeList:addOption(option);
end

if (type(config.selected) ~= "table") then
  config.selected = {};
end

spellsCaster.selected = config.selected;
spellsCaster.selected.config = spellsCaster.selected.config or characterName;
spellsCaster.selected.type = spellsCaster.selected.type or ESPECIAIS_OPTIONS[1];

spellsCaster.isEditing = true;
local NORMAL_CHANGER = function(widget, checked)
  spellsCaster.mainPanel.percentScroll:hide();
  local textBox = spellsCaster.mainPanel.keyToPress_textBox;
  local keyBox = spellsCaster.mainPanel.keyToPress;
  textBox:show();
  keyBox:show();
  spellsCaster.mainPanel.keyToPress_textBox:setEnabled(not checked);
  if checked then
    spellsCaster.mainPanel.keyToPress:clearText();
  else
    spellsCaster.mainPanel.keyToPress:setText(spellsCaster.mainPanel.keyToPress.oldKey);
  end
  spellsCaster.isEditing = not checked;
end

spellsCaster.mainPanel.keyToPress_textBox.oldWidth = spellsCaster.mainPanel.keyToPress_textBox:getWidth();

local PERCENT_CHANGER = function(widget, checked)
  local textBox = spellsCaster.mainPanel.keyToPress_textBox
  local percentScroll = spellsCaster.mainPanel.percentScroll;
  if (checked) then
    spellsCaster.mainPanel.keyLabel:setText("Percent");
    percentScroll:show();
    textBox:setWidth(textBox.oldWidth / 2);
    percentScroll:setWidth(textBox.oldWidth / 2 + 15);
  else
    spellsCaster.mainPanel.keyLabel:setText("Tecla");
    textBox:setWidth(textBox.oldWidth);
    percentScroll:hide();
  end
  spellsCaster.isEditing = true;
end

local doScrollSetup = function(widget, defaultValue, min, max, notTime)
  widget:setMinimum(min);
  widget:setMaximum(max);
  if (widget:getId() ~= "percentScroll") then
    widget.onValueChange = function(widget, value)
      local append = not notTime and "s" or "";
      widget:setText(value .. append);
    end
  else
    widget.onValueChange = function(widget, value)
      widget:setText(value ~= 100 and value .. "%" or "AUTO%");
    end
  end
  widget:setValue(100);
  widget:setValue(defaultValue);
end

spellsCaster.mainPanel.typeList.onOptionChange = function(widget, text)
  local type = text;
  spellsCaster.selected.type = type;
  local self = spellsCaster.mainPanel.automaticUse;
  local textBox = spellsCaster.mainPanel.keyToPress_textBox;
  textBox:setWidth(textBox.oldWidth);
  local keyToPress = spellsCaster.mainPanel.keyToPress;

  spellsCaster.mainPanel.keyLabel:setText("Tecla");
  textBox:show();
  keyToPress:show();
  self:show();

  local activeScroll, activeLabel = spellsCaster.mainPanel.activeScroll, spellsCaster.mainPanel.activeLabel;

  doScrollSetup(activeScroll, 0, 0, 180);
  activeLabel:setText("Active");
  activeLabel:setWidth(38);

  spellsCaster.window.mainPanel.reactionBuffCheck:hide();
  spellsCaster.window.mainPanel.autoReactivateCheck:hide();
  spellsCaster.window.mainPanel.targetPctScroll:hide();
  spellsCaster.window.mainPanel.lblTargetPct:hide();
  spellsCaster.window.mainPanel.emergencyScroll:hide();
  spellsCaster.window.mainPanel.lblEmergency:hide();
  spellsCaster.window.mainPanel.reactionScroll:hide();
  spellsCaster.window.mainPanel.lblReaction:hide();
  spellsCaster.window.mainPanel.reviveCheck:hide();
  spellsCaster.window.mainPanel.lifesCheck:hide();
  spellsCaster.window.mainPanel.multipleCheck:hide();
  spellsCaster.window.mainPanel.lifesValue:hide();

  if (type == TYPE_FUGA) then
    spellsCaster.window.mainPanel.emergencyScroll:show();
    spellsCaster.window.mainPanel.lblEmergency:show();
    spellsCaster.window.mainPanel.reviveCheck:show();
    spellsCaster.window.mainPanel.lifesCheck:show();
    spellsCaster.window.mainPanel.multipleCheck:show();
  elseif (type == TYPE_BUFF) then
    spellsCaster.window.mainPanel.reactionBuffCheck:show();
    spellsCaster.window.mainPanel.autoReactivateCheck:show();
    spellsCaster.window.mainPanel.reactionScroll:show();
    spellsCaster.window.mainPanel.lblReaction:show();
  elseif (type == TYPE_NORMAL) then
    spellsCaster.window.mainPanel.targetPctScroll:show();
    spellsCaster.window.mainPanel.lblTargetPct:show();
  end

  spellsCaster.window.mainPanel.WASD:hide();
  spellsCaster.window.mainPanel.SETAS:hide();
  if (type == TYPE_FUGA) then
    spellsCaster.isEditing = true;
    self:setTooltip("Automatico (com porcentagem)");
    self.onCheckChange = PERCENT_CHANGER;
    self.onCheckChange(self, self:isChecked());
  elseif (type ~= TYPE_STACK) then
    local extra = type ~= TYPE_BUFF and " (com target)" or "";
    self:setTooltip("Automatico" .. extra);
    self.onCheckChange = NORMAL_CHANGER;
    self.onCheckChange(self, self:isChecked());
  else
    doScrollSetup(activeScroll, 5, 2, 9, true);
    activeLabel:setText("Distance");
    textBox:hide();
    keyToPress:hide();
    spellsCaster.mainPanel.percentScroll:hide();
    spellsCaster.window.mainPanel.WASD:show();
    spellsCaster.window.mainPanel.SETAS:show();
    self:hide();
  end
  if (spellsCaster.refreshSpells) then
    spellsCaster.refreshSpells();
  end
end

doScrollSetup(spellsCaster.mainPanel.cooldownScroll, 1, 1, 600);
doScrollSetup(spellsCaster.mainPanel.activeScroll, 0, 0, 180);
doScrollSetup(spellsCaster.mainPanel.percentScroll, 1, 1, 100);

local self = spellsCaster.mainPanel.typeList;
self:setCurrentOption(config.selected.type);
self.onOptionChange(self, config.selected.type);

spellsCaster.mainPanel.configList:setWidth(150);

if (spellsCaster.selected.config == characterName) then
  spellsCaster.mainPanel.importButton:hide();
end

for option, _ in pairs(storage.especiaisConfig[worldName]) do
  spellsCaster.mainPanel.configList:addOption(option);
end

spellsCaster.mainPanel.configList.onOptionChange = function(widget, text)
  local option = text;
  if (option ~= characterName) then
    spellsCaster.mainPanel.importButton:show();
  else
    spellsCaster.mainPanel.importButton:hide();
  end
  spellsCaster.selected.config = option;
end

spellsCaster.mainPanel.configList:setCurrentOption(spellsCaster.selected.config)

spellsCaster.mainPanel.importButton.onClick = function()
  local previousStorage = config;
  config.spells = storage.especiaisConfig[worldName][config.selected.config].spells;
  spellsCaster.mainPanel.configList:setOption(config.selected.config);
  spellsCaster.refreshSpells();
end

spellsCaster.mainPanel.keyToPress_textBox.onTextChange = function(widget)
  widget:clearText();
end

spellsCaster.mainPanel.castSpellName.onTextChange = function(widget, text)
  if (not spellsCaster.mainPanel.sameAsAbove:isChecked()) then return; end
  widget:clearText();
end

spellsCaster.mainPanel.sameAsAbove.onCheckChange = function(widget, checked)
  if (checked) then
    spellsCaster.mainPanel.castSpellName:setEnabled(false);
  else
    spellsCaster.mainPanel.castSpellName:setEnabled(true);
    spellsCaster.mainPanel.castSpellName:setText(spellsCaster.mainPanel.spellName:getText());
  end
end

spellsCaster.mainPanel.sameAsAbove:setChecked(true);

onKeyDown(function(keys)
  if (not spellsCaster.isEditing) then return; end
  if (spellsCaster.window:isHidden()) then return; end
  if (not spellsCaster.mainPanel.keyToPress_textBox:isFocused()) then return; end
  spellsCaster.mainPanel.keyToPress:setText(keys);
end)

spellsCaster.mainPanel.closeButton.onClick = function()
  spellsCaster.window:hide();
  spellsCaster.doGameFocus();
end

spellsCaster.window.onEscape = spellsCaster.mainPanel.closeButton.onClick;

spellsCaster.doGameFocus = function()
  gameRootPanel:focus();
end

spellsCaster.entry = [[
Label
  background-color: alpha
  text-offset: 18 4
  focusable: true
  height: 16
  font: verdana-11px-rounded

  CheckBox
    id: enabled
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: 15
    height: 15
    margin-top: 2
    margin-left: 3

  $focus:
    background-color: #00000055

  Button
    id: remove
    !text: tr('x')
    anchors.right: parent.right
    margin-right: 15
    text-offset: 1 0
    width: 15
    height: 15
]];

spellsCaster.getAllFromSameType = function(type)
  local childrens = {};
  for _, entry in pairs(config.spells) do
    if (entry.type == type) then
      table.insert(childrens, entry);
    end
  end
  table.sort(childrens, function(a, b)
    return a.index < b.index;
  end)
  return childrens;
end

spellsCaster.checkIndex = function(entry)
  local spells = spellsCaster.getAllFromSameType(entry.type);
  while (entry.index ~= 1) do
    local wantedIndex = entry.index - 1;
    local newEntry = table.findbyfield(spells, 'index', wantedIndex);
    if (not newEntry) then
      entry.index = wantedIndex;
    else
      spellsCaster.checkIndex(newEntry);
      break
    end
  end
end

spellsCaster.changeChildByIndex = function(newIndex)
  local child = spellsCaster.mainPanel.especiaisList:getFocusedChild();
  if (not child) then return; end
  local oldIndex = child.index;
  newIndex = newIndex + oldIndex;
  local oldChild = child:getParent():getChildByIndex(newIndex);
  config.spells[oldChild.castSpellName].index = oldIndex;
  config.spells[child.castSpellName].index = newIndex;
  spellsCaster.refreshSpells();
end

spellsCaster.mainPanel.moveDown.onClick = function()
  spellsCaster.changeChildByIndex(1);
end

spellsCaster.mainPanel.moveUp.onClick = function()
  spellsCaster.changeChildByIndex(-1);
end

spellsCaster.refreshSpells = function()
  spellsCaster.destroyAllWidgets();
  spellsCaster.window.mainPanel.moveUp:hide();
  spellsCaster.window.mainPanel.moveDown:hide();

  if (not config.macroActive) then return; end

  spellsCaster.spells = {};
  for _, type in ipairs(ESPECIAIS_OPTIONS) do
    spellsCaster.spells[type] = {};
  end

  for castSpellName, entry in pairs(config.spells) do
    spellsCaster.checkIndex(entry);
    if (entry.enabled and table.find(SHOW_SPELL_TIME, entry.type)) then
      spellsCaster.setupWidget(castSpellName);
    end
    local content = spellsCaster.spells[entry.type];
    table.insert(content, entry);
    table.sort(content, function(a, b)
      return a.index < b.index;
    end)
  end

  local selected = config.selected.type;
  local showSpells = spellsCaster.spells[selected];
  for _, entry in ipairs(showSpells) do
    local widget = setupUI(spellsCaster.entry, spellsCaster.mainPanel.especiaisList);

    widget.onFocusChange = function(widget, focused)
      if (#showSpells == 1 or not focused) then return; end
      if (entry.index == 1) then
        spellsCaster.mainPanel.moveUp:hide();
      else
        spellsCaster.mainPanel.moveUp:show();
      end
      if (entry.index == #showSpells) then
        spellsCaster.mainPanel.moveDown:hide();
      else
        spellsCaster.mainPanel.moveDown:show();
      end
    end
    widget.onDoubleClick = function()
      config.spells[entry.castSpellName] = nil;
      local self = spellsCaster.mainPanel.typeList;
      self:setCurrentOption(entry.type);
      if (entry.spellName == entry.castSpellName) then
        spellsCaster.mainPanel.sameAsAbove:setChecked(true);
      else
        spellsCaster.mainPanel.sameAsAbove:setChecked(false);
        spellsCaster.mainPanel.castSpellName:setText(entry.castSpellName);
      end
      spellsCaster.mainPanel.spellName:setText(entry.spellName);
      spellsCaster.mainPanel.cooldownScroll:setValue(entry.cooldownTotal);
      spellsCaster.mainPanel.activeScroll:setValue(entry.activeTotal or entry.distance);
      if (entry.type ~= TYPE_BUFF) then
        if (entry.key) then
          if (entry.key ~= "AUTO") then
            spellsCaster.mainPanel.keyToPress:setText(entry.key);
          end
        end
        if (entry.percent) then
          spellsCaster.mainPanel.percentScroll:setValue(entry.percent);
        end
        spellsCaster.mainPanel.automaticUse:setChecked(entry.percent or entry.key == 'AUTO');
      end
      spellsCaster.sucessDisplay('A magia foi removida.');
      spellsCaster.refreshSpells();
    end
    widget.remove.onClick = widget.onDoubleClick;
    widget.enabled:setChecked(entry.enabled);
    widget.enabled.onCheckChange = function(widget, enabled)
      entry.enabled = enabled;
      spellsCaster.refreshSpells();
    end
    widget.castSpellName = entry.castSpellName;
    widget.index = entry.index;
    local widget_text = entry.castSpellName:ucwords();
    widget_text = widget_text .. " | CD: " .. entry.cooldownTotal .. "s";
    local EXTRA;
    if (entry.percent) then
      EXTRA = entry.percent == 100 and "AUTO%" or entry.percent .. "%";
    end
    if (entry.key and #entry.key > 0) then
      EXTRA = EXTRA and EXTRA .. " | " .. entry.key or entry.key;
    end
    if EXTRA then
      widget_text = widget_text .. " | " .. EXTRA;
    end
    if entry.enableRevive  then widget_text = widget_text .. " [R]"; end
    if entry.enableLifes   then widget_text = widget_text .. " [L:" .. (entry.amountLifes or 0) .. "]"; end
    if entry.enableMultiple then widget_text = widget_text .. " [M]"; end
    widget:setText(widget_text);
  end
  if (config.showInfo) then
    spellsCaster.setupWidget("battlingStatus");
  end
  modules.game_bot.save();
end

local checkBox = setupUI([[
CheckBox
  id: checkBox
  font: cipsoftFont
  text: Show Info
]]);

checkBox.onCheckChange = function(widget, checked)
  config.showInfo = checked;
  spellsCaster.refreshSpells();
end

if (config.showInfo == nil) then
  config.showInfo = true;
end

checkBox:setChecked(config.showInfo);

spellsCaster.refreshSpells();

spellsCaster.errorDisplay = function(text)
  local excludeValue = now + 2000;
  spellsCaster.mainPanel.displayLabel.excludeValue = excludeValue;
  spellsCaster.mainPanel.displayLabel:setText(text);
  spellsCaster.mainPanel.displayLabel:setColor({r = 255, g = 0, b = 0, a = 255});
  schedule(2000, function()
    if (excludeValue ~= spellsCaster.mainPanel.displayLabel.excludeValue) then return; end
    spellsCaster.mainPanel.displayLabel:clearText('');
  end)
end

spellsCaster.sucessDisplay = function(text)
  local excludeValue = now + 2000;
  spellsCaster.mainPanel.displayLabel.excludeValue = excludeValue;
  spellsCaster.mainPanel.displayLabel:setText(text);
  spellsCaster.mainPanel.displayLabel:setColor({r = 0, g = 255, a = 255});
  schedule(2000, function()
    if (excludeValue ~= spellsCaster.mainPanel.displayLabel.excludeValue) then return; end
    spellsCaster.mainPanel.displayLabel:clearText();
  end)
end

spellsCaster.mainPanel.addButton.onClick = function()
  local spellName = spellsCaster.mainPanel.spellName:getText():lower():trim();
  local castSpellName = not spellsCaster.mainPanel.sameAsAbove:isChecked() and spellsCaster.mainPanel.castSpellName:getText():lower():trim() or spellName;
  local cooldownTime = spellsCaster.mainPanel.cooldownScroll:getValue();
  local activeTime = spellsCaster.mainPanel.activeScroll:getValue();
  local keyToPress, percent;
  if (config.selected.type == TYPE_STACK) then
    keyToPress = spellsCaster.mainPanel.WASD:isChecked() and "WASD" or "SETAS";
  elseif (config.selected.type ~= TYPE_FUGA) then
    keyToPress = spellsCaster.mainPanel.automaticUse:isChecked() and 'AUTO' or spellsCaster.mainPanel.keyToPress:getText();
  else
    percent = spellsCaster.mainPanel.automaticUse:isChecked() and spellsCaster.mainPanel.percentScroll:getValue();
    keyToPress = spellsCaster.mainPanel.keyToPress:getText();
  end

  if (#spellName == 0) then
    return spellsCaster.errorDisplay('Insira o nome da magia.');
  end
  if (#castSpellName == 0) then
    return spellsCaster.errorDisplay('Insira o texto que a magia solta.');
  end
  if (not keyToPress or #keyToPress == 0 and not percent) then
    return spellsCaster.errorDisplay('Defina uma tecla.');
  end
  if (config.spells[castSpellName] ~= nil) then
    return spellsCaster.errorDisplay('A magia ja existe.');
  end

  config.spells[castSpellName] = {
    castSpellName = castSpellName,
    spellName = spellName,
    cooldownTotal = cooldownTime,
    index = table.size(config.spells) + 1,
    type = config.selected.type,
    enabled = true
  };

  if (config.selected.type ~= TYPE_STACK) then
    config.spells[castSpellName].activeTotal = activeTime;
  else
    config.spells[castSpellName].distance = activeTime;
  end

  if (#keyToPress > 0) then
    config.spells[castSpellName].key = keyToPress;
  end
  if (percent) then
    config.spells[castSpellName].percent = percent;
  end

  if (config.selected.type == TYPE_BUFF) then
    config.spells[castSpellName].reactionBuff   = spellsCaster.mainPanel.reactionBuffCheck:isChecked();
    config.spells[castSpellName].autoReactivate = spellsCaster.mainPanel.autoReactivateCheck:isChecked();
  elseif (config.selected.type == TYPE_NORMAL) then
    local tpct = spellsCaster.mainPanel.targetPctScroll:getValue();
    if tpct < 100 then
      config.spells[castSpellName].targetPercent = tpct;
    end
  elseif (config.selected.type == TYPE_FUGA) then
    if spellsCaster.mainPanel.lifesCheck:isChecked() then
      config.spells[castSpellName].enableLifes  = true;
      config.spells[castSpellName].amountLifes  = spellsCaster.mainPanel.lifesValue:getValue();
      config.spells[castSpellName].lifes        = 0;
    end
    if spellsCaster.mainPanel.reviveCheck:isChecked() then
      config.spells[castSpellName].enableRevive   = true;
      config.spells[castSpellName].alreadyChecked = false;
    end
    if spellsCaster.mainPanel.multipleCheck:isChecked() then
      config.spells[castSpellName].enableMultiple = true;
      config.spells[castSpellName].count          = 3;
    end
    spellsCaster.mainPanel.reviveCheck:setChecked(false);
    spellsCaster.mainPanel.lifesCheck:setChecked(false);
    spellsCaster.mainPanel.multipleCheck:setChecked(false);
    spellsCaster.mainPanel.lifesValue:hide();
    spellsCaster.mainPanel.multipleCheck:show();
  end

  saveEspeciaisConfig();
  spellsCaster.mainPanel.keyToPress:clearText();
  spellsCaster.mainPanel.spellName:clearText();
  spellsCaster.mainPanel.castSpellName:clearText();
  spellsCaster.mainPanel.sameAsAbove:setChecked(true);
  spellsCaster.mainPanel.automaticUse:setChecked(false);
  spellsCaster.mainPanel.percentScroll:setValue(1);
  spellsCaster.mainPanel.cooldownScroll:setValue(1);
  spellsCaster.mainPanel.activeScroll:setValue(0);

  spellsCaster.sucessDisplay('A magia foi inserida com sucesso.');
  spellsCaster.refreshSpells();
end

keepTarget = {}

local message = modules.game_bot.message;
info = function(text) return message("info", tostring(text)) end
warn = function(text) return message("warn", tostring(text)) end
warning = warn
error = function(text) return message("error", tostring(text)) end

table.recursiveFindByKey = function(t, k, parent, readed)
  readed = readed or {};
  parent = parent or 'modules'
  for key, value in pairs(t) do
    if k == key then return value end
    if type(value) == 'table' then
      local index = parent .. '.' .. key
      if (not readed[index]) then
        readed[index] = true
        local find = table.recursiveFindByKey(value, k, key, readed)
        if find then return find end
      end
    end
  end
end

table.recursiveMatchKey = function(t, k, parent, readed)
  readed = readed or {};
  parent = parent or 'modules';
  k = k:lower()
  for key, value in pairs(t) do
    key = tostring(key):lower()
    if key:match(k) then return value end
    if type(value) == 'table' then
      local index = parent .. '.' .. key
      if (not readed[index]) then
        readed[index] = true
        local find = table.recursiveMatchKey(value, k, key, readed)
        if find then return find end
      end
    end
  end
end