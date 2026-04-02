setDefaultTab('Elohim')

local dir = "/bot/Kurumi/Elohim/"
local files = g_resources.listDirectoryFiles(dir, false, false) or {}
table.sort(files)

for _, fileName in ipairs(files) do
    if fileName:match("%.lua$") then
        pcall(function()
            local content = g_resources.readFileContents(dir .. fileName)
            local fn, err = loadstring(content)
            if fn then fn() end
        end)
    end
end