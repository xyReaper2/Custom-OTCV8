UI.Button("Exportar Jumps", function()
    local export = {}
    for stringPos, value in pairs(config) do
        if type(stringPos) == "string" and stringPos:find(',') then
            export[stringPos] = value
        end
    end
    UI.MultilineEditorWindow(json.encode(export), {title = "Exportar Jumps", description = "Copie o JSON abaixo:", width = 350}, function() end)
end)

UI.Button("Importar Jumps", function()
    UI.MultilineEditorWindow("", {title = "Importar Jumps", description = "Cole o JSON dos jumps aqui:", width = 350}, function(text)
        local ok, data = pcall(json.decode, text:trim())
        if not ok or type(data) ~= "table" then
            jumpBySave.message("error", "JSON invÃ¡lido.")
            return
        end
        local count = 0
        for stringPos, value in pairs(data) do
            if type(stringPos) == "string" and type(value) == "table" and value.direction and value.jumpTo then
                if not config[stringPos] then
                    config[stringPos] = {direction = value.direction, jumpTo = value.jumpTo}
                    count = count + 1
                end
            end
        end
        jumpBySave.message("info", count .. " jump(s) importado(s).")
    end)
end)
