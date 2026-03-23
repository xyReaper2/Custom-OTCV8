storage.speedConfig = storage.speedConfig or {}

UI.Label("Spell de Speed:")
local speedSpellEdit = UI.TextEdit()
speedSpellEdit:setText(storage.speedConfig.speedSpell or "concentrate chakra feet")
speedSpellEdit.onTextChange = function(widget, text)
    storage.speedConfig.speedSpell = text
end

macro(100, "Speed", function()
    local spell = storage.speedConfig.speedSpell or "concentrate chakra feet"
    local lyze  = storage.speedConfig.speedLyze

    if not hasHaste() or (isParalyzed() and lyze) then
        say(spell)
    end
end)

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
