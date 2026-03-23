storage.regenConfig = storage.regenConfig or {}

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

UI.Label("Regeneration")
local spellEdit = UI.TextEdit()
spellEdit:setText(storage.regenConfig.spell or "")
spellEdit.onTextChange = function(widget, text)
    storage.regenConfig.spell = text:trim()
end

addScrollBar("regenPercentage", "Regeneration %", 1, 100, 99)
addScrollBar = nil

macro(storage.scrollBars.macroDelay or 50, function()
    local spell      = storage.regenConfig.spell or ""
    local percentage = storage.scrollBars.regenPercentage or 99

    if spell == "" then return end

    if hppercent() <= percentage then
        say(spell)
    end
end)
