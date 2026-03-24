UI.Button("Hotkeys", function(newText)
  UI.MultilineEditorWindow(storage.ingame_hotkeys or "", {title="Hotkeys editor", description="Adicione suas scripts aqui!"}, function(text)
    storage.ingame_hotkeys = text
    reload()
  end)
end)



for _, scripts in pairs({storage.ingame_hotkeys}) do
  if type(scripts) == "string" and scripts:len() > 3 then
    local status, result = pcall(function()
      assert(load(scripts, "ingame_editor"))()
    end)
    if not status then 
      error("Hotkeys:\n" .. result)
    end
  end
end
