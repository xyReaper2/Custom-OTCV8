storage.bgConfig = storage.bgConfig or {
    global = "",
    individual = {}
}

local BG_DIR = "/bot/kurumi/images/"
local WINDOWS = {
    "especiais",
    "combo",
    "treinar",
    "travel",
    "timeEnemy",
}

if not g_resources.directoryExists(BG_DIR) then
    g_resources.makeDir("/bot/kurumi/")
    g_resources.makeDir(BG_DIR)
end

local function getImages()
    local files = g_resources.listDirectoryFiles(BG_DIR, false, false)
    local images = {}
    for _, f in ipairs(files or {}) do
        local lower = f:lower()
        if lower:match("%.png$") or lower:match("%.jpg$") or lower:match("%.jpeg$") or lower:match("%.bmp$") or lower:match("%.apng$") then
            table.insert(images, f)
        end
    end
    return images
end

local function getWindow(name)
    local root = g_ui.getRootWidget()
    return root:recursiveGetChildById(name .. "Window") or root:recursiveGetChildById(name .. "_window")
end

local function applyBg(widget, imagePath)
    if not widget then return end
    if imagePath and imagePath ~= "" then
        widget:setImageSource(BG_DIR .. imagePath)
    else
        widget:setImageSource("")
    end
end

local function applyAllBgs()
    for _, name in ipairs(WINDOWS) do
        local path = storage.bgConfig.individual[name]
        if not path or path == "" then
            path = storage.bgConfig.global
        end
        local target = getWindow(name)
        if target then
            applyBg(target, path)
        end
    end
end

local bgUI = setupUI([[
UIWidget
  size: 480 400
  border-width: 1
  border-color: #446688
  focusable: true
  phantom: false
  draggable: true
  background-color: #0d0d1aEE
  @onEscape: self:hide()

  Panel
    id: titlebar
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: 34
    background-color: #080810

    Label
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      text: BG MANAGER
      color: #cc44cc
      font: verdana-11px-rounded

    Label
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 10
      text: BACKGROUNDS
      color: #556677
      font: verdana-11px-rounded

  UIWidget
    anchors.top: titlebar.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    background-color: #446688

  Panel
    id: downloadPanel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 36
    background-color: #0a0a15
    margin-top: 0

    Label
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      text: URL:
      color: #556677
      font: verdana-11px-rounded
      text-auto-resize: true

    TextEdit
      id: urlEdit
      anchors.left: prev.right
      anchors.right: downloadBtn.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
      margin-right: 5
      height: 22
      background-color: #00000000
      image-color: #00000000
      border-width: 1
      border-color: #446688
      color: #FFFFFF
      font: verdana-11px-rounded

    UIWidget
      id: downloadBtn
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 8
      width: 80
      height: 22
      text: DOWNLOAD
      background-color: #00000000
      border-width: 1
      border-color: #446688
      color: #88aacc
      font: verdana-11px-rounded
      text-align: center
      focusable: true

  UIWidget
    anchors.top: downloadPanel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    background-color: #1a2a3a

  Panel
    id: globalPanel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 36
    background-color: #0a0a15

    Label
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      text: GLOBAL:
      color: #DDAA00
      font: verdana-11px-rounded
      text-auto-resize: true

    ComboBox
      id: globalCombo
      anchors.left: prev.right
      anchors.right: applyAllBtn.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 5
      margin-right: 5
      height: 20
      font: verdana-11px-rounded

    UIWidget
      id: applyAllBtn
      anchors.right: clearAllBtn.left
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 4
      width: 65
      height: 22
      text: APLICAR
      background-color: #00000000
      border-width: 1
      border-color: #DDAA00
      color: #DDAA00
      font: verdana-11px-rounded
      text-align: center
      focusable: true

    UIWidget
      id: clearAllBtn
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 8
      width: 55
      height: 22
      text: LIMPAR
      background-color: #00000000
      border-width: 1
      border-color: #664444
      color: #cc8888
      font: verdana-11px-rounded
      text-align: center
      focusable: true

  UIWidget
    anchors.top: globalPanel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 1
    background-color: #1a2a3a

  Label
    id: individualLabel
    anchors.top: prev.bottom
    anchors.left: parent.left
    margin-top: 6
    margin-left: 10
    text: INDIVIDUAL
    color: #556677
    font: verdana-11px-rounded

  TextList
    id: windowList
    anchors.top: individualLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: statusBar.top
    margin: 4 8 4 8
    background-color: #00000000
    image-color: #00000000
    border-width: 1
    border-color: #1a2a3a
    vertical-scrollbar: listScroll

  VerticalScrollBar
    id: listScroll
    anchors.top: windowList.top
    anchors.bottom: windowList.bottom
    anchors.right: windowList.right
    step: 14
    pixels-scroll: true

  Panel
    id: statusBar
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 32
    background-color: #080810

    Label
      id: statusLabel
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
      margin-left: 10
      color: #446688
      font: verdana-11px-rounded
      text-auto-resize: true

    UIWidget
      id: closeBtn
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      margin-right: 8
      width: 65
      height: 22
      text: FECHAR
      background-color: #00000000
      border-width: 1
      border-color: #664444
      color: #cc8888
      font: verdana-11px-rounded
      text-align: center
      focusable: true
]], g_ui.getRootWidget())

bgUI:hide()
bgUI:setPosition({
    x = math.floor((g_ui.getRootWidget():getWidth()  - 480) / 2),
    y = math.floor((g_ui.getRootWidget():getHeight() - 400) / 2)
})

storage.bgWindowPos = storage.bgWindowPos or nil

bgUI.onDragEnter = function(widget, mousePos)
    if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
    widget:breakAnchors()
    widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
    return true
end

bgUI.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect()
    local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
    local y = math.min(math.max(parentRect.y, mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
    widget:move(x, y)
    return true
end

bgUI.onDragLeave = function(widget, pos)
    storage.bgWindowPos = {x = widget:getX(), y = widget:getY()}
    return true
end

local statusLabel = bgUI.statusBar.statusLabel

local function showStatus(text, color)
    statusLabel:setText(text)
    statusLabel:setColor(color or "#446688")
    schedule(3000, function()
        if statusLabel and not statusLabel:isDestroyed() then
            statusLabel:setText("")
        end
    end)
end

local rowUI = [[
Panel
  background-color: alpha
  height: 28
  focusable: true
  margin-bottom: 3

  Label
    id: rowName
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 8
    font: verdana-11px-rounded
    color: #cc44cc
    text-auto-resize: true
    width: 100

  ComboBox
    id: rowCombo
    anchors.left: rowName.right
    anchors.right: rowApplyBtn.left
    anchors.verticalCenter: parent.verticalCenter
    margin-left: 5
    margin-right: 4
    height: 20
    font: verdana-11px-rounded

  UIWidget
    id: rowApplyBtn
    anchors.right: rowClearBtn.left
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 3
    width: 55
    height: 20
    text: APLICAR
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #88aacc
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  UIWidget
    id: rowClearBtn
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    margin-right: 6
    width: 45
    height: 20
    text: X
    background-color: #00000000
    border-width: 1
    border-color: #664444
    color: #cc8888
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  $focus:
    background-color: #1a1a2a
    border-width: 1
    border-color: #446688
]]

local function refreshCombos()
    local images = getImages()

    bgUI.globalPanel.globalCombo:clear()
    bgUI.globalPanel.globalCombo:addOption("(nenhum)")
    for _, img in ipairs(images) do
        bgUI.globalPanel.globalCombo:addOption(img)
    end
    local cur = storage.bgConfig.global
    if cur and cur ~= "" then
        bgUI.globalPanel.globalCombo:setCurrentOption(cur)
    else
        bgUI.globalPanel.globalCombo:setCurrentOption("(nenhum)")
    end

    bgUI.windowList:destroyChildren()
    for _, name in ipairs(WINDOWS) do
        local row = setupUI(rowUI, bgUI.windowList)
        row.rowName:setText(name)

        row.rowCombo:addOption("(global)")
        for _, img in ipairs(images) do
            row.rowCombo:addOption(img)
        end

        local indiv = storage.bgConfig.individual[name]
        if indiv and indiv ~= "" then
            row.rowCombo:setCurrentOption(indiv)
        else
            row.rowCombo:setCurrentOption("(global)")
        end

        local winName = name
        row.rowApplyBtn.onClick = function()
            local sel = row.rowCombo:getCurrentOption().text
            if sel == "(global)" then
                storage.bgConfig.individual[winName] = ""
            else
                storage.bgConfig.individual[winName] = sel
            end
            local target = getWindow(winName)
            if target then
                local path = storage.bgConfig.individual[winName]
                if not path or path == "" then path = storage.bgConfig.global end
                applyBg(target, path)
                showStatus("Aplicado em " .. winName .. "!", "#4ACC4A")
            else
                showStatus("Janela '" .. winName .. "' nao encontrada.", "#DDAA00")
            end
        end

        row.rowClearBtn.onClick = function()
            storage.bgConfig.individual[winName] = ""
            row.rowCombo:setCurrentOption("(global)")
            local target = getWindow(winName)
            if target then
                local path = storage.bgConfig.global
                applyBg(target, path)
            end
            showStatus("Individual de " .. winName .. " limpo.", "#cc8888")
        end
    end
end

bgUI.globalPanel.applyAllBtn.onClick = function()
    local sel = bgUI.globalPanel.globalCombo:getCurrentOption().text
    storage.bgConfig.global = (sel == "(nenhum)") and "" or sel
    applyAllBgs()
    showStatus("Background global aplicado!", "#4ACC4A")
end

bgUI.globalPanel.clearAllBtn.onClick = function()
    storage.bgConfig.global = ""
    bgUI.globalPanel.globalCombo:setCurrentOption("(nenhum)")
    applyAllBgs()
    showStatus("Background global limpo.", "#cc8888")
end

bgUI.statusBar.closeBtn.onClick = function()
    bgUI:hide()
end

bgUI.onEscape = bgUI.statusBar.closeBtn.onClick

bgUI.downloadPanel.downloadBtn.onClick = function()
    local url = bgUI.downloadPanel.urlEdit:getText():trim()
    if url == "" then
        showStatus("Insira uma URL.", "#cc8888")
        return
    end
    local fileName = url:match("([^/]+)$")
    local lower = fileName and fileName:lower() or ""
    if not fileName or not (lower:match("%.png$") or lower:match("%.jpg$") or lower:match("%.jpeg$") or lower:match("%.bmp$") or lower:match("%.apng$")) then
        showStatus("URL deve terminar em .png/.jpg/.jpeg/.bmp/.apng", "#cc8888")
        return
    end
    showStatus("Baixando " .. fileName .. "...", "#DDAA00")
    HTTP.get(url, function(data, err)
        if err or not data then
            showStatus("Erro ao baixar: " .. tostring(err), "#cc8888")
            return
        end
        g_resources.writeFileContents(BG_DIR .. fileName, data)
        showStatus("Salvo: " .. fileName, "#4ACC4A")
        bgUI.downloadPanel.urlEdit:setText("")
        refreshCombos()
    end)
end

UI.Button("BG Manager", function()
    if storage.bgWindowPos then
        bgUI:setPosition(storage.bgWindowPos)
    end
    refreshCombos()
    bgUI:show()
    bgUI:raise()
end)

applyAllBgs()