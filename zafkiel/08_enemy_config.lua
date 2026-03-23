storage.friendList     = storage.friendList or ""
storage.autoFriendList = storage.autoFriendList or ""

attackEnemy.updateLists = function()
    attackEnemy.friendList = attackEnemy.friendList or {}

    local function parseList(str)
        local updating = {}
        for _, name in ipairs(str:split('\n')) do
            name = name:trim()
            if name ~= "" then
                attackEnemy.friendList[name:lower()] = true
                if not table.find(updating, name) then
                    table.insert(updating, name)
                end
            end
        end
        table.sort(updating, function(a, b) return a < b end)
        return table.concat(updating, "\n")
    end

    storage.friendList     = parseList(storage.friendList)
    storage.autoFriendList = parseList(storage.autoFriendList)
end

attackEnemy.updateLists()

UI.Button("Friends", function()
    UI.MultilineEditorWindow(storage.friendList, {title = "Friends", description = "Nome dos amigos", width = 225}, function(text)
        storage.friendList = text
        attackEnemy.updateLists()
    end)
end)

UI.Button("Auto Friends", function()
    UI.MultilineEditorWindow(storage.autoFriendList, {title = "Auto Friends", description = "Players adicionados", width = 225}, function(text)
        storage.autoFriendList = text
        attackEnemy.updateLists()
    end)
end)

UI.Button("Limpar Auto Friends", function()
    storage.autoFriendList = ""
    attackEnemy.updateLists()
end)
