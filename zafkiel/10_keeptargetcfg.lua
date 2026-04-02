UI.Label("KeepTarget CFG")

storage.scrollBars = storage.scrollBars or {}

local horizontalScrollBar = [[
Panel
  height: 28
  margin-top: 1

  Label
    id: text
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    text-align: center
    font: verdana-11px-rounded

  HorizontalScrollBar
    id: scroll
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: prev.bottom
    margin-top: 1
    minimum: 0
    maximum: 10
    step: 1
]]

local function addScrollBar(id, title, min, max, defaultValue)
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

addScrollBar("searchTimeout", "Timeout (s)",         1,    60,  10)
addScrollBar("reattackDelay", "Reattack Delay (ms)", 50, 2000, 200)
addScrollBar("senseDelay",    "Sense Delay (ms)",   500, 5000, 1500)

UI.Separator()