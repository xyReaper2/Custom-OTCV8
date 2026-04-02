storage.potionConfig = storage.potionConfig or {}
storage.scrollBars   = storage.scrollBars   or {}
storage.itemValues   = storage.itemValues   or {}

local horizontalScrollBar = [[
Panel
  height: 35
  margin-top: -5

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
    return widget
end

local itemWidget = [[
Panel
  height: 34
  margin-top: 7
  margin-left: -5
  margin-right: 25
  UIWidget
    id: text
    anchors.left: parent.left
    anchors.verticalCenter: next.verticalCenter
  BotItem
    id: item
    anchors.top: parent.top
    anchors.right: parent.right
]]

local addItem = function(id, title, defaultItem)
    local widget = setupUI(itemWidget, panel)
    widget.text:setText(title)
    widget.item:setItemId(storage.itemValues[id] or defaultItem)
    widget.item.onItemChange = function(w)
        storage.itemValues[id] = w:getItemId()
    end
    storage.itemValues[id] = storage.itemValues[id] or defaultItem
    return widget
end

local function createPotionSection(label, enabledKey, hpKey, hpLabel, itemKey, defaultItem)
    local checkBox = setupUI([[
CheckBox
  font: cipsoftFont
  text: ]] .. label .. [[
]], panel)

    local idWidget  = addItem(itemKey, "Potion Id:", defaultItem)
    local hpWidget  = addScrollBar(hpKey, hpLabel, 1, 100, 100)
    local dlyWidget = addScrollBar(itemKey .. "Delay", "Delay", 0, 5000, 300)

    local function updateVisibility(checked)
        idWidget:setVisible(checked)
        hpWidget:setVisible(checked)
        dlyWidget:setVisible(checked)
    end

    if storage.potionConfig[enabledKey] == nil then
        storage.potionConfig[enabledKey] = false
    end

    checkBox:setChecked(storage.potionConfig[enabledKey])
    updateVisibility(storage.potionConfig[enabledKey])

    checkBox.onCheckChange = function(widget, checked)
        storage.potionConfig[enabledKey] = checked
        updateVisibility(checked)
    end
end

createPotionSection("Health Potion", "healthEnabled", "potionHealth", "Life%",  "potionLife",  11863)
createPotionSection("Mana Potion",   "manaEnabled",   "potionMana",   "Mana%",  "potionMana2", 11863)

macro(100, function()
    local hp      = hppercent()
    local mp      = manapercent()
    local lifeId  = storage.itemValues.potionLife  or 11863
    local manaId  = storage.itemValues.potionMana2 or 11863

    if storage.potionConfig.healthEnabled then
        local hpPct  = storage.scrollBars.potionHealth or 100
        local hpDly  = storage.scrollBars.potionLifeDelay or 300
        if hp < hpPct then
            useWith(lifeId, player)
            delay(hpDly)
            return
        end
    end

    if storage.potionConfig.manaEnabled then
        local mpPct  = storage.scrollBars.potionMana or 100
        local mpDly  = storage.scrollBars.potionMana2Delay or 300
        if mp < mpPct then
            useWith(manaId, player)
            delay(mpDly)
        end
    end
end)
