storage.regenConfig = storage.regenConfig or {}

if type(canCast) ~= "function" then
    canCast = function(spell, time)
        if not spell then return end
        time = time or now
        if not spell or spell <= time then
            return true
        end
        return false
    end
end

local horizontalScrollBar = [[
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
    local widget = setupUI(horizontalScrollBar, panel)
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

UI.Label("Spell de Regeneração:")
local spellEdit = UI.TextEdit()
spellEdit:setText(storage.regenConfig.spell or "")
spellEdit.onTextChange = function(widget, text)
    storage.regenConfig.spell = text
end

addScrollBar("regenPercentage", "HP %",        1,  100,  99)
addScrollBar("regenCooldown",   "Cooldown (s)", 1,   60,   1)
addScrollBar = nil

macro(100, "Regeneration", function()
    local spell      = storage.regenConfig.spell or ""
    local percentage = storage.scrollBars.regenPercentage or 99
    local cooldown   = (storage.scrollBars.regenCooldown or 1) * 1000

    if spell == "" then return end

    if hppercent() <= percentage then
        if canCast(storage.regenConfig.cooldownSpell) then
            say(spell)
        end
    end
end)

onTalk(function(name, level, mode, text, channelId, pos)
    if name ~= player:getName() then return end
    local spell = storage.regenConfig.spell or ""
    if spell == "" then return end
    if text:lower() == spell:lower() then
        local cooldown = (storage.scrollBars.regenCooldown or 1) * 1000
        storage.regenConfig.cooldownSpell = now + cooldown
    end
end)
