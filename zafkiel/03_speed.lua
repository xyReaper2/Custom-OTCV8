storage.speedConfig = storage.speedConfig or {}

UI.Label("Speed")
local speedSpellEdit = UI.TextEdit()
speedSpellEdit:setText(storage.speedConfig.speedSpell or "")
speedSpellEdit.onTextChange = function(widget, text)
    storage.speedConfig.speedSpell = text:trim()
end

local speedLyzeCheckBox = setupUI([[
CheckBox
  font: cipsoftFont
  text: Speed ao Lyzar
]])

speedLyzeCheckBox.onCheckChange = function(widget, checked)
    storage.speedConfig.speedLyze = checked
end

if storage.speedConfig.speedLyze == nil then
    storage.speedConfig.speedLyze = true
end

speedLyzeCheckBox:setChecked(storage.speedConfig.speedLyze)

macro(storage.scrollBars.macroDelay or 50, function()
    local spell = storage.speedConfig.speedSpell or ""
    local lyze  = storage.speedConfig.speedLyze

    if spell == "" then return end

    if not hasHaste() or (isParalyzed() and lyze) then
        say(spell)
    end
end)
