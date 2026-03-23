storage.kunaiConfig = storage.kunaiConfig or {}

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

local checkBox = setupUI([[
CheckBox
  font: cipsoftFont
  text: Kunai Dash & Jump
]], panel)

local idLabel   = setupUI([[Label
  font: cipsoftFont
  text: Id da Kunai
  text-auto-resize: true
  margin-top: 3
]], panel)

local idEdit = UI.TextEdit()
idEdit:setText(tostring(storage.kunaiConfig.kunaiId or 7382))
idEdit.onTextChange = function(widget, text)
    local id = tonumber(text)
    if id then
        storage.kunaiConfig.kunaiId = id
        if bugMap then
            bugMap.kunaiId = id
            storage.bugMap = storage.bugMap or {}
            storage.bugMap.kunaiId = id
        end
        if jumpBySave then
            jumpBySave.kunaiId = id
            storage.jumps = storage.jumps or {}
            storage.jumps.kunaiId = id
        end
    end
end

local distWidget = setupUI(horizontalScrollBar, panel)
distWidget.scroll:setRange(1, 20)
distWidget.scroll:setStep(1)
distWidget.scroll:setValue(storage.kunaiConfig.kunaiDistance or 10)
distWidget.scroll.onValueChange = function(scroll, value)
    storage.kunaiConfig.kunaiDistance = value
    scroll:setText("Distance: " .. value)
    if jumpBySave then
        jumpBySave.kunaiRange = value
    end
end
distWidget.scroll.onValueChange(distWidget.scroll, distWidget.scroll:getValue())

local function updateVisibility(checked)
    idLabel:setVisible(checked)
    idEdit:setVisible(checked)
    distWidget:setVisible(checked)
end

if storage.kunaiConfig.enabled == nil then
    storage.kunaiConfig.enabled = false
end

checkBox:setChecked(storage.kunaiConfig.enabled)
updateVisibility(storage.kunaiConfig.enabled)

checkBox.onCheckChange = function(widget, checked)
    storage.kunaiConfig.enabled = checked
    updateVisibility(checked)
    if bugMap then
        storage.bugMap = storage.bugMap or {}
        storage.bugMap.useKunai = checked
        if bugMap.kunaiCheckBox then
            bugMap.kunaiCheckBox:setChecked(checked)
        end
    end
    if jumpBySave then
        storage.jumps = storage.jumps or {}
        storage.jumps.useKunai = checked
    end
end
