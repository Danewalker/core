local explode = seawolf.text.explode

do
  local arguments, q

  function arg(index)
    index = index + 1

    local arguments, q = arguments, q

    if arguments == nil or q ~= _GET.q then
      arguments = explode([[/]], _GET.q)
      q = _GET.q
    end

    if arguments[index] ~= nil then
      return arguments[index]
    end
  end
end

local slash = settings.slash

do
  local path_tree, path

  function sanitize_path()
    if path_tree == nil and path == nil then
      path_tree, path = {}
      for i = 1,8 do
        a = arg(i - 1)
        if a == nil or a == [[]] then
          break
        else
          path = (path or [[]]) .. (path and slash or [[]]) .. (a or [[]])
          table.insert(path_tree, path)
        end
      end
      if not #path_tree then
        error [[Menu system error!]]
      end
      _GET.q = path
    end
    return path_tree, path
  end
end