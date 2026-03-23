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

attackEnemy.isFriend = function(name)
    if type(name) ~= "string" then
        name = name:getName()
    end
    return attackEnemy.friendList[name:trim():lower()] ~= nil
end

attackEnemy.addAutoFriend = function(name)
    name = name:trim()
    if not attackEnemy.isFriend(name) then
        storage.autoFriendList = storage.autoFriendList .. "\n" .. name
        attackEnemy.updateLists()
    end
end

attackEnemy.updateLists()

UI.Separator()
UI.Button("Friends", function()
    UI.MultilineEditorWindow(storage.friendList, {title = "Friends", description = "Coloque o nome dos amigos", width = 225}, function(text)
        storage.friendList = text
        attackEnemy.updateLists()
    end)
end)

UI.Button("Auto Friends", function()
    UI.MultilineEditorWindow(storage.autoFriendList, {title = "Auto Friends", description = "Players adicionados automaticamente", width = 225}, function(text)
        storage.autoFriendList = text
        attackEnemy.updateLists()
    end)
end)

UI.Button("Limpar Auto Friends", function()
    storage.autoFriendList = ""
    attackEnemy.updateLists()
end)
