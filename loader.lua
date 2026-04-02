local GITHUB_USER   = "xyReaper2"
local GITHUB_REPO   = "Custom-OTCV8"
local GITHUB_BRANCH = "main"
local GITHUB_API    = "https://api.github.com/repos/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/contents/?ref=" .. GITHUB_BRANCH
local GITHUB_RAW    = "https://raw.githubusercontent.com/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/" .. GITHUB_BRANCH .. "/"

local SAVE_DIR    = "/bot/Kurumi/"
local STATUS_FILE = SAVE_DIR .. "_loader_status.json"
local COOLDOWN_S  = 30
local LOADER_NAME = "loader.lua"

if not g_resources.directoryExists(SAVE_DIR) then
    g_resources.makeDir(SAVE_DIR)
end

local loaderWindow = setupUI([[
UIWidget
  size: 380 230
  border-width: 1
  border-color: #446688
  focusable: true
  phantom: false
  draggable: true
  background-color: #000000CC
  @onEscape: self:hide()

  Label
    id: titleLabel
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    margin-top: 8
    text: SCRIPT LOADER
    color: #FFFFFF
    font: verdana-11px-rounded

  UIWidget
    anchors.top: titleLabel.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    margin-top: 5
    margin-left: 6
    margin-right: 6
    height: 1
    background-color: #446688

  Panel
    id: mainPanel
    anchors.top: prev.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: dividerBottom.top
    background-color: #00000000
    margin: 4

    Label
      id: statusTitleLabel
      text: Aguardando...
      anchors.top: parent.top
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
      font: verdana-11px-rounded
      color: #FFFFFF
      text-auto-resize: true

    Label
      id: fileLabel
      text: -
      anchors.top: statusTitleLabel.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 6
      font: verdana-11px-rounded
      color: #AAAAAA
      text-auto-resize: true

    Panel
      id: barBg
      anchors.top: fileLabel.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      margin-top: 10
      height: 16
      background-color: #1a1a1a
      border-width: 1
      border-color: #446688

      Panel
        id: barFill
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: 0
        background-color: #446688

    Label
      id: percentLabel
      text: 0%
      anchors.centerIn: barBg
      font: verdana-11px-rounded
      color: #FFFFFF
      text-auto-resize: true

    Label
      id: countLabel
      text: 0 / 0
      anchors.top: barBg.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 6
      font: verdana-11px-rounded
      color: #AAAAAA
      text-auto-resize: true

    Label
      id: statusLabel
      text: -
      anchors.top: countLabel.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 4
      font: verdana-11px-rounded
      color: #FFFFFF
      text-auto-resize: true

    Label
      id: lastUpdateLabel
      text: Nunca atualizado
      anchors.top: statusLabel.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      margin-top: 6
      font: verdana-11px-rounded
      color: #666666
      text-auto-resize: true

  UIWidget
    id: dividerBottom
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: closeBtn.top
    margin-bottom: 5
    margin-left: 5
    margin-right: 5
    height: 1
    background-color: #446688

  UIWidget
    id: reloadBtn
    text: Atualizar
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    margin-left: 10
    margin-bottom: 5
    width: 90
    height: 22
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text-align: center
    focusable: true

  UIWidget
    id: closeBtn
    text: Fechar
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    margin-right: 10
    margin-bottom: 5
    width: 80
    height: 22
    background-color: #00000000
    border-width: 1
    border-color: #446688
    color: #FFFFFF
    font: verdana-11px-rounded
    text-align: center
    focusable: true
]], g_ui.getRootWidget())

loaderWindow:hide()
loaderWindow:setPosition({
    x = math.floor((g_ui.getRootWidget():getWidth()  - 380) / 2),
    y = math.floor((g_ui.getRootWidget():getHeight() - 230) / 2)
})

storage.loaderWindowPos = storage.loaderWindowPos or nil

loaderWindow.onDragEnter = function(widget, mousePos)
    if not modules.corelib.g_keyboard.isCtrlPressed() then return false end
    widget:breakAnchors()
    widget.movingReference = {x = mousePos.x - widget:getX(), y = mousePos.y - widget:getY()}
    return true
end

loaderWindow.onDragMove = function(widget, mousePos, moved)
    local parentRect = widget:getParent():getRect()
    local x = math.min(math.max(parentRect.x, mousePos.x - widget.movingReference.x), parentRect.x + parentRect.width - widget:getWidth())
    local y = math.min(math.max(parentRect.y, mousePos.y - widget.movingReference.y), parentRect.y + parentRect.height - widget:getHeight())
    widget:move(x, y)
    return true
end

loaderWindow.onDragLeave = function(widget, pos)
    storage.loaderWindowPos = {x = widget:getX(), y = widget:getY()}
    return true
end

local mp               = loaderWindow.mainPanel
local barBg            = mp.barBg
local barFill          = barBg.barFill
local statusTitleLabel = mp.statusTitleLabel
local fileLabel        = mp.fileLabel
local percentLabel     = mp.percentLabel
local countLabel       = mp.countLabel
local statusLabel      = mp.statusLabel
local lastUpdateLabel  = mp.lastUpdateLabel

local isUpdating   = false
local lastReloadAt = 0

if _KURUMI_UPDATING then
    isUpdating   = false
    lastReloadAt = 0
end
_KURUMI_UPDATING = false

local function hashContent(str)
    local h = 5381
    for i = 1, #str do
        h = ((h * 33) + string.byte(str, i)) % 2147483647
    end
    return tostring(h)
end

local function setProgress(current, total)
    local pct  = total > 0 and math.floor((current / total) * 100) or 0
    local barW = math.floor((barBg:getWidth() * pct) / 100)
    barFill:setWidth(barW)
    percentLabel:setText(pct .. "%")
    countLabel:setText(current .. " / " .. total)
    if pct >= 100 then
        barFill:setBackgroundColor("#00AA00")
    elseif pct > 0 then
        barFill:setBackgroundColor("#446688")
    else
        barFill:setBackgroundColor("#1a1a1a")
    end
end

local function setFile(name)   fileLabel:setText(name) end
local function setTitle(t, c)  statusTitleLabel:setText(t) statusTitleLabel:setColor(c or "#FFFFFF") end
local function setStatus(t, c) statusLabel:setText(t) statusLabel:setColor(c or "#FFFFFF") end

local function loadStatus()
    if g_resources.fileExists(STATUS_FILE) then
        local ok, result = pcall(function()
            return json.decode(g_resources.readFileContents(STATUS_FILE))
        end)
        if ok and result then return result end
    end
    return {hashes = {}, lastUpdate = nil}
end

local function saveStatus(data)
    local ok, result = pcall(function() return json.encode(data, 2) end)
    if ok then g_resources.writeFileContents(STATUS_FILE, result) end
end

local function formatTime(ts)
    if not ts then return "Nunca" end
    return os.date("%d/%m %H:%M", ts)
end

local function downloadFiles(luaFiles, githubFiles)
    local status  = loadStatus()
    status.hashes = status.hashes or {}

    local function cleanDir(dir, prefix)
        local localFiles = g_resources.listDirectoryFiles(dir, false, false) or {}
        for _, fileName in ipairs(localFiles) do
            local fullPath = prefix ~= "" and (prefix .. "/" .. fileName) or fileName
            local fullLocal = dir .. fileName
            if g_resources.directoryExists(fullLocal) then
                cleanDir(fullLocal .. "/", fullPath)
            elseif fileName:match("%.lua$") and fileName ~= LOADER_NAME and not githubFiles[fullPath] then
                g_resources.deleteFile(fullLocal)
                status.hashes[fullPath] = nil
            end
        end
    end
    cleanDir(SAVE_DIR, "")

    local total   = #luaFiles
    local current = 0
    local updated = 0
    local skipped = 0

    setTitle("Baixando scripts...", "#FFFFFF")
    setProgress(0, total)

    local function processNext()
        if current >= total then
            local ts = os.time()
            status.lastUpdate = ts
            saveStatus(status)

            local summary = updated .. " atualizado(s), " .. skipped .. " sem alteracao"
            setTitle("Concluido!", "#00AA00")
            setFile("-")
            setStatus(summary, "#00AA00")
            setProgress(total, total)
            lastUpdateLabel:setText("Ultima atualizacao: " .. formatTime(ts))
            lastUpdateLabel:setColor("#446688")

            isUpdating       = false
            _KURUMI_UPDATING = false
            loaderWindow.reloadBtn:setColor("#FFFFFF")

            if not loaderWindow._hasError then
                schedule(2000, function()
                    loaderWindow:hide()
                    setTitle("Aguardando...", "#FFFFFF")
                    setStatus("-", "#FFFFFF")
                    setProgress(0, 1)
                    countLabel:setText("0 / 0")
                    setFile("-")
                end)
            else
                loaderWindow._hasError = false
                setTitle("Concluido com erros!", "#FF4444")
                setStatus("Alguns arquivos falharam.", "#FF4444")
            end
            return
        end

        current = current + 1
        local fileName    = luaFiles[current]
        local filePath    = SAVE_DIR .. fileName
        local encodedName = fileName:gsub(" ", "%%20")
        local rawUrl      = GITHUB_RAW .. encodedName

        -- cria subpasta local se necessario
        local subDir = fileName:match("^(.+)/[^/]+$")
        if subDir then
            local localSubDir = SAVE_DIR .. subDir
            if not g_resources.directoryExists(localSubDir) then
                g_resources.makeDir(localSubDir)
            end
        end

        setFile(fileName)
        setProgress(current - 1, total)

        local function tryDownload(attempt)
            local timedOut = false
            schedule(8000, function()
                if timedOut then return end
                timedOut = true
                if attempt < 3 then
                    setStatus("Timeout (" .. attempt .. "/3)...", "#FFAA00")
                    schedule(attempt * 1500, function() tryDownload(attempt + 1) end)
                else
                    setStatus("[TIMEOUT] " .. fileName, "#FF4444")
                    loaderWindow._hasError = true
                    processNext()
                end
            end)

            HTTP.get(rawUrl, function(fileData, fileErr)
                if timedOut then return end
                timedOut = true

                if (fileErr or not fileData or fileData == "") and attempt < 3 then
                    setStatus("Tentando novamente (" .. attempt .. "/3)...", "#FFAA00")
                    schedule(attempt * 1500, function() tryDownload(attempt + 1) end)
                    return
                end

                if fileErr or not fileData or fileData == "" then
                    setStatus("[FALHA] " .. fileName, "#FF4444")
                    loaderWindow._hasError = true
                    processNext()
                    return
                end

                local newHash = hashContent(fileData)
                if status.hashes[fileName] == newHash and g_resources.fileExists(filePath) then
                    setStatus("Sem alteracoes.", "#AAAAAA")
                    skipped = skipped + 1
                    setProgress(current, total)
                    schedule(50, processNext)
                    return
                end

                g_resources.writeFileContents(filePath, fileData)
                status.hashes[fileName] = newHash
                updated = updated + 1
                setStatus("Atualizado!", "#FFAA00")
                setProgress(current, total)
                schedule(300, processNext)
            end)
        end
        tryDownload(1)
    end

    processNext()
end

local function startUpdate()
    if isUpdating then return end

    local nowTime = os.time()
    if (nowTime - lastReloadAt) < COOLDOWN_S then
        local remaining = COOLDOWN_S - (nowTime - lastReloadAt)
        setStatus("Aguarde " .. remaining .. "s.", "#FFAA00")
        return
    end

    isUpdating         = true
    lastReloadAt       = nowTime
    _KURUMI_UPDATING   = true
    loaderWindow._hasError = false
    loaderWindow.reloadBtn:setColor("#666666")

    setTitle("Conectando...", "#FFFFFF")
    setFile("-")
    setStatus("Buscando lista no GitHub...", "#FFFFFF")
    setProgress(0, 1)

    local allFiles    = {}
    local githubFiles = {}
    local pendingDirs = 0
    local apiDone     = false

    local function onAllDirsScanned()
        if pendingDirs > 0 or not apiDone then return end
        table.sort(allFiles)
        if #allFiles == 0 then
            isUpdating = false
            loaderWindow.reloadBtn:setColor("#FFFFFF")
            setTitle("Nenhum script encontrado.", "#FF4444")
            setStatus("Repositorio sem arquivos .lua.", "#FF4444")
            return
        end
        downloadFiles(allFiles, githubFiles)
    end

    local scanDir
    scanDir = function(apiUrl, localPrefix)
        pendingDirs = pendingDirs + 1
        HTTP.get(apiUrl, function(data, err)
            pendingDirs = pendingDirs - 1
            if not err and data and data ~= "" then
                local ok, files = pcall(function() return json.decode(data) end)
                if ok and type(files) == "table" then
                    for _, file in ipairs(files) do
                        if type(file) == "table" and file.name then
                            local fullPath = localPrefix ~= "" and (localPrefix .. "/" .. file.name) or file.name
                            if file.type == "file" and file.name:match("%.lua$") and file.name ~= LOADER_NAME then
                                githubFiles[fullPath] = true
                                table.insert(allFiles, fullPath)
                            elseif file.type == "dir" then
                                local subUrl = "https://api.github.com/repos/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/contents/" .. fullPath .. "?ref=" .. GITHUB_BRANCH
                                scanDir(subUrl, fullPath)
                            end
                        end
                    end
                end
            end
            onAllDirsScanned()
        end)
    end

    local function tryAPI(attempt)
        HTTP.get(GITHUB_API, function(data, err)
            if err or not data or data == "" then
                if attempt < 4 then
                    setTitle("Tentando novamente... (" .. attempt .. "/4)", "#FFAA00")
                    setStatus("Aguardando " .. (attempt * 2) .. "s...", "#FFAA00")
                    schedule(attempt * 2000, function() tryAPI(attempt + 1) end)
                else
                    isUpdating = false
                    loaderWindow.reloadBtn:setColor("#FFFFFF")
                    setTitle("GitHub indisponivel!", "#FF4444")
                    setStatus("Clique em Atualizar para tentar novamente.", "#FF4444")
                end
                return
            end
            local ok, files = pcall(function() return json.decode(data) end)
            if not ok or type(files) ~= "table" then
                isUpdating = false
                loaderWindow.reloadBtn:setColor("#FFFFFF")
                setTitle("Erro!", "#FF4444")
                setStatus("Resposta invalida do GitHub.", "#FF4444")
                return
            end
            for _, file in ipairs(files) do
                if type(file) == "table" and file.name then
                    if file.type == "file" and file.name:match("%.lua$") and file.name ~= LOADER_NAME then
                        githubFiles[file.name] = true
                        table.insert(allFiles, file.name)
                    elseif file.type == "dir" then
                        local subUrl = "https://api.github.com/repos/" .. GITHUB_USER .. "/" .. GITHUB_REPO .. "/contents/" .. file.name .. "?ref=" .. GITHUB_BRANCH
                        scanDir(subUrl, file.name)
                    end
                end
            end
            apiDone = true
            onAllDirsScanned()
        end)
    end

    tryAPI(1)
end

local savedStatus = loadStatus()
if savedStatus.lastUpdate then
    lastUpdateLabel:setText("Ultima atualizacao: " .. formatTime(savedStatus.lastUpdate))
    lastUpdateLabel:setColor("#446688")
end

loaderWindow.reloadBtn.onClick = function()
    if storage.loaderWindowPos then
        loaderWindow:setPosition(storage.loaderWindowPos)
    end
    startUpdate()
end

loaderWindow.closeBtn.onClick = function()
    loaderWindow:hide()
end

local todayKey = os.date("%Y-%m-%d")

if storage.loaderLastDay ~= todayKey then
    storage.loaderLastDay = todayKey
    schedule(5000, function()
        if storage.loaderWindowPos then
            loaderWindow:setPosition(storage.loaderWindowPos)
        end
        loaderWindow:show()
        loaderWindow:raise()
        startUpdate()
    end)
end