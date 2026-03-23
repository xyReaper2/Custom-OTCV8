Stairs = {}

Stairs.excludeIds = Stairs.excludeIds or {
    12099,
    17393
}

Stairs.stairsIds = Stairs.stairsIds or {
    1666, 6207, 1948, 435, 7771, 5542, 8657, 6264,
    1646, 1648, 1678, 5291, 1680, 6905, 6262, 1664,
    13296, 1067, 13861, 11931, 1949, 6896, 6205, 13926,
    1947, 12097, 615, 1678, 8367
}

Stairs.isKeyPressed = modules.corelib.g_keyboard.isKeyPressed
Stairs.isMobile     = modules._G.g_app.isMobile()

Stairs.updateIds = function()
    Stairs.excludeMap = {}
    Stairs.stairsMap  = {}

    for _, value in ipairs(storage.stairsIds) do
        Stairs.stairsMap[value.id] = true
    end

    for _, value in ipairs(storage.excludeIds) do
        Stairs.excludeMap[value.id] = true
    end
end

if not stairsIdContainer then
    UI.Label("Escadas & Portas")

    stairsIdContainer = UI.Container(function(widget, items)
        storage.stairsIds = items
        Stairs.updateIds()
    end, true)

    storage.stairsIds = storage.stairsIds or Stairs.stairsIds
    stairsIdContainer:setItems(storage.stairsIds)
    stairsIdContainer:setHeight(35)
    UI.Separator()
end

if not excludeIdsContainer then
    UI.Label("Ids excluídos")

    excludeIdsContainer = UI.Container(function(widget, items)
        storage.excludeIds = items
        Stairs.updateIds()
    end, true)

    storage.excludeIds = storage.excludeIds or Stairs.excludeIds
    excludeIdsContainer:setItems(storage.excludeIds)
    excludeIdsContainer:setHeight(35)
    UI.Separator()
end

Stairs.updateIds()
