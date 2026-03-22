storage.potionConfig = storage.potionConfig or {}

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

UI.Separator()
addScrollBar("potionHealth", "HP %",          1, 100, 99)
addScrollBar("potionMana",   "Mana %",         1, 100, 99)
addScrollBar("potionDelay",  "Delay (s)",      0,  60,  1)
addScrollBar = nil
UI.Separator()

storage.itemValues = storage.itemValues or {}

local itemWidget = [[
Panel
  height: 34
  margin-top: 7
  margin-left: 25
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
end

addItem("potionLife", "Potion Life", 11863)
addItem("potionMana", "Potion Mana", 11863)

macro(100, "Potion", function()
    local hp       = hppercent()
    local mp       = manapercent()
    local hpPct    = storage.scrollBars.potionHealth or 99
    local mpPct    = storage.scrollBars.potionMana   or 99
    local delayMs  = (storage.scrollBars.potionDelay or 1) * 1000
    local lifeId   = storage.itemValues.potionLife or 11863
    local manaId   = storage.itemValues.potionMana or 11863

    if hp < hpPct then
        useWith(lifeId, player)
        delay(delayMs)
    elseif mp < mpPct then
        useWith(manaId, player)
        delay(delayMs)
    end
end)