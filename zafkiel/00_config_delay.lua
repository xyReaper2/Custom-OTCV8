storage.scrollBars = storage.scrollBars or {}

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

UI.Label("CONFIG")

local widget = setupUI(horizontalScrollBar, panel)
widget.scroll:setRange(50, 5000)
widget.scroll:setStep(50)
widget.scroll:setValue(storage.scrollBars.macroDelay or 50)
widget.scroll.onValueChange = function(scroll, value)
    storage.scrollBars.macroDelay = value
    scroll:setText("Macro delay: " .. value)
end
widget.scroll.onValueChange(widget.scroll, widget.scroll:getValue())
