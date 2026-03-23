recursiveFindByKey = function(t, k, parent, readed)
	readed = readed or {};
	parent = parent or 'modules';

	for key, value in pairs(t) do
		if k == key then
			return value;
		end
		if type(value) == 'table' then
			local index = parent .. '_' .. key
			if (not readed[index]) then
				readed[index] = true;
				local find = recursiveFindByKey(value, k, key, readed);
				if find then
					return find;
				end
			end
		end
	end
end

recursiveMatchbyKey = function(t, k, parent, readed)
	readed = readed or {};
	parent = parent or 'modules';

	for key, value in pairs(t) do
		if (tostring(key):lower():match(k:lower())) then
			return value;
		end
		if type(value) == 'table' then
			local index = parent .. '_' .. key
			if (not readed[index]) then
				readed[index] = true;
				local find = recursiveMatchbyKey(value, k, key, readed);
				if find then
					return find;
				end
			end
		end
	end
end

local attackEnemy = {}

attackEnemy.g_app          = table.recursiveFindByKey(modules, "g_app")
attackEnemy.game_interface  = table.recursiveFindByKey(modules, "game_interface")
attackEnemy.processMouseAction = table.recursiveMatchKey(modules, "processMouseAction")
attackEnemy.isMobile        = attackEnemy.g_app.isMobile()
attackEnemy.keyCancel       = not attackEnemy.isMobile and "Escape" or "F2"

local ATTACKING_COLORS = {"#FF8888", "#FF0000"}

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
    end)
end

storage.friendList     = storage.friendList or ""
storage.autoFriendList = storage.autoFriendList or ""

UI.Separator()
UI.Button("Friends", function()
    UI.MultilineEditorWindow(storage.friendList, {title = "Friends", description = "Coloque o nome dos amigos", width = 225}, function(text)
        storage.friendList = text
        attackEnemy.updateLists()
    end)
end)

UI.Button("Auto Friends", function()
    UI.MultilineEditorWindow(storage.autoFriendList, {title = "Auto Friends", description = "Players adicionados automaticamente", width = 225}, function(text)
        storage.autoFriendList = text
        attackEnemy.updateLists()
    end)
end)

UI.Button("Limpar Auto Friends", function()
    storage.autoFriendList = ""
    attackEnemy.updateLists()
end)

UI.Separator()

attackEnemy.updateLists = function()
    attackEnemy.friendList = {}

    local function parseList(str)
        local updating = {}
        for _, name in ipairs(str:split('\n')) do
            name = name:trim()
            if name ~= "" then
                attackEnemy.friendList[name:lower()] = true
                if not table.find(updating, name) then
                    table.insert(updating, name)
                end
            end
        end
        table.sort(updating, function(a, b) return a < b end)
        return table.concat(updating, "\n")
    end

    storage.friendList     = parseList(storage.friendList)
    storage.autoFriendList = parseList(storage.autoFriendList)
end

attackEnemy.updateLists()

attackEnemy.isFriend = function(name)
    if type(name) ~= "string" then
        name = name:getName()
    end
    return attackEnemy.friendList[name:trim():lower()] ~= nil
end

attackEnemy.addAutoFriend = function(name)
    name = name:trim()
    if not attackEnemy.isFriend(name) then
        storage.autoFriendList = storage.autoFriendList .. "\n" .. name
        attackEnemy.updateLists()
    end
end

attackEnemy.getCreatures = function()
    local creatures = {}
    local z = player:getPosition().z
    for _, tile in ipairs(g_map.getTiles(z)) do
        for _, creature in ipairs(tile:getCreatures()) do
            table.insert(creatures, creature)
        end
    end
    return creatures
end

attackEnemy.getCreatureById = function(id)
    for _, creature in ipairs(attackEnemy.getCreatures()) do
        if creature:getId() == id then
            return creature
        end
    end
end

attackEnemy.checkAttackImage = function()
    attackEnemy.game_interface.resetLeftActions()
    attackEnemy.game_interface.gameLeftActions:getChildById("attack").image:setChecked(true)
end

attackEnemy.searchWithinVariables = function()
    for key, func in pairs(g_game) do
        if type(func) == "function" and key:lower():match("getatt") then
            local ok, result = pcall(func)
            if ok and result and (result:isPlayer() or result:isMonster()) then
                return result
            end
        end
    end
end

attackEnemy.getAttackingCreature = function()
    if not battlePanel then return attackEnemy.searchWithinVariables() end
    local currentZ = player:getPosition().z
    for _, child in ipairs(battlePanel:getChildren()) do
        local creature = child.creature
        if creature then
            local cPos = creature:getPosition()
            if cPos and cPos.z == currentZ and table.find(ATTACKING_COLORS, child.color) then
                return creature
            end
        end
    end
    return attackEnemy.searchWithinVariables()
end

attackEnemy.doAttack = function(creature)
    if not creature then return end
    if attackEnemy.getAttackingCreature() == creature then return end
    if not attackEnemy.getCreatureById(creature:getId()) then return end
    local creaturePos = creature:getPosition()
    if attackEnemy.isMobile then
        attackEnemy.checkAttackImage()
    end
    attackEnemy.processMouseAction(creaturePos, attackEnemy.isMobile and 1 or 2, creaturePos, creature, creature, creature, creature)
end

onCreaturePositionChange(function(creature, newPos, oldPos)
    if not newPos or not oldPos then return end
    local posStr = newPos.x .. ',' .. newPos.y .. ',' .. newPos.z
    if creature.lastPos ~= posStr then
        creature.lastPos  = posStr
        creature.whiteList = nil
    end
end)

attackEnemy.whiteListedCase = {
    'you may not attack a person in a protection zone.',
    'you may not attack this player.',
    'this action is not permitted in a safe zone.'
}

do
    local t = {}
    for _, case in ipairs(attackEnemy.whiteListedCase) do
        t[case] = true
    end
    attackEnemy.whiteListedCase = t
end

onTextMessage(function(mode, text)
    if attackEnemy.whiteListedCase[text:trim():lower()] then
        local target = attackEnemy.getAttackingCreature()
        if target then
            target.whiteList = true
            g_game.cancelAttack()
        end
    end
end)

function Creature:isAttackable()
    if self.whiteList then return false end
    if not self:isPlayer() then return false end
    local hp = self:getHealthPercent()
    if not hp or hp <= 0 then return false end
    if attackEnemy.isFriend(self:getName()) then return false end
    if self:getEmblem() == 1 or self:getShield() >= 3 or self == player then
        attackEnemy.addAutoFriend(self:getName())
        return false
    end
    return true
end

local PRIORITY = "hp"

attackEnemy.horizontalScrollBar = [[
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
    local widget = setupUI(attackEnemy.horizontalScrollBar, panel)
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

addScrollBar("attackDelay", "Delay", 10, 1000, 200)
addScrollBar = nil

local hpCheckBox = setupUI([[
CheckBox
  font: cipsoftFont
  text: Atacar menor HP
]])

hpCheckBox.onCheckChange = function(widget, checked)
    storage.attackByHp = checked
end

if storage.attackByHp == nil then
    storage.attackByHp = true
end

hpCheckBox:setChecked(storage.attackByHp)



macro(1, "Enemy", function()
    if isInPz() then return end
    local best     = nil

    for _, spec in ipairs(attackEnemy.getCreatures()) do
        if spec:isAttackable() and spec:canShoot() then
            local specHp = spec:getHealthPercent()
            local specId = spec:getId()

            if not best then
                best = {spec = spec, hp = specHp, id = specId}
            elseif specHp < best.hp or (specHp == best.hp and specId < best.id) then
                best = {spec = spec, hp = specHp, id = specId}
            end
        end
    end

    if best then
        local totalTime = storage.scrollBars.attackDelay
        schedule(totalTime, function()
            attackEnemy.doAttack(best.spec)
        end)
        return delay(totalTime + 250)
    end
end)
