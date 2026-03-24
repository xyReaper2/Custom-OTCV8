storage.battleFilter = storage.battleFilter or {
    hideParty = false,
    hideGuild = false,
    hideFriends = false
}

local battleModule = modules.game_battle
if battleModule then
    battleModule.doCreatureFitFilters = function(creature)
        if creature:isLocalPlayer() then return false end
        if creature:getHealthPercent() <= 0 then return false end

        local pos = creature:getPosition()
        if not pos then return false end

        local localPlayer = g_game.getLocalPlayer()
        if pos.z ~= localPlayer:getPosition().z then return false end
        if not creature:canBeSeen() then return false end

        local filterPanel = g_ui.getRootWidget():recursiveGetChildById('filterPanel')
        if filterPanel and filterPanel.buttons then
            if filterPanel.buttons.hidePlayers:isChecked() and creature:isPlayer() then return false end
            if filterPanel.buttons.hideNPCs:isChecked() and creature:isNpc() then return false end
            if filterPanel.buttons.hideMonsters:isChecked() and creature:isMonster() then return false end
            if filterPanel.buttons.hideSkulls:isChecked() and creature:isPlayer() and creature:getSkull() == 0 then return false end
        end

        if storage.battleFilter.hideParty then
            local ok, val = pcall(function() return creature:getShield() end)
            if ok and val and val >= 3 then return false end
        end

        if storage.battleFilter.hideGuild then
            local ok, val = pcall(function() return creature:getEmblem() end)
            if ok and val and val == 1 then return false end
        end

        if storage.battleFilter.hideFriends and attackEnemy and attackEnemy.isFriend then
            if attackEnemy.isFriend(creature:getName()) then return false end
        end

        return true
    end
end

UI.Separator()

local partyCheck = setupUI([[
CheckBox
  font: cipsoftFont
  text: Esconder Party
]])
partyCheck:setChecked(storage.battleFilter.hideParty)
partyCheck.onCheckChange = function(widget, checked)
    storage.battleFilter.hideParty = checked
end

local guildCheck = setupUI([[
CheckBox
  font: cipsoftFont
  text: Esconder Guild
]])
guildCheck:setChecked(storage.battleFilter.hideGuild)
guildCheck.onCheckChange = function(widget, checked)
    storage.battleFilter.hideGuild = checked
end

local friendsCheck = setupUI([[
CheckBox
  font: cipsoftFont
  text: Esconder Friend List
]])
friendsCheck:setChecked(storage.battleFilter.hideFriends)
friendsCheck.onCheckChange = function(widget, checked)
    storage.battleFilter.hideFriends = checked
end

UI.Separator()
