local deps = {}

local imports = {}

--- Build a string out of the active neovim buffer
---@return string string with all the content of the buffer
function deps.buffer_to_string()
  local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(content, '\n')
end

--- Get all the files that a .typ file depends open
---@return table table containing the path of all dependencies files
function deps.get_imports()
  deps.recursive_imports(vim.fn.expand('%:p'))

  local hash = {}
  local res = {}
  for _, v in ipairs(imports) do
    if (not hash[v]) then
      res[#res + 1] = v -- you could print here instead of saving to result table if you wanted
      hash[v] = true
    end
  end

  imports = res

  return imports
end

--- Get all imports in a single file
---@param file_path path of the file to parse
---@return table table containing all imports
function deps.get_imports_from_file(file_path)
  local pattern_reg = "#import%s?\"%g+\":"
  local import_reg = "%b\"\""

  local imports_table = {}

  local buffr = deps.read_file(file_path)
  if buffr == nil then
    return {}
  end
  for pattern in string.gmatch(buffr, pattern_reg) do
    for import in string.gmatch(pattern, import_reg) do
      import = string.gsub(import, "[\"]", "")
      table.insert(imports_table, deps.get_full_path(import))
    end
  end
  return imports_table
end

--- Get required imports and the imports of those imports
---@param import_str path to the base file
function deps.recursive_imports(import_str)
  local iter_imports = {}
  if import_str ~= nil then
    iter_imports = deps.get_imports_from_file(import_str)

    imports = deps.concat_tables(imports, iter_imports)
    for _, lvalue in pairs(iter_imports) do
      deps.recursive_imports(lvalue)
    end
  end
end

--- Concatenate the value of a table to another
---@param t1 first table
---@param t2 second table
---@return the first table with the content of the second table appended
function deps.concat_tables(t1, t2)
  if t1 ~= nil and t2 ~= nil then
    for i = 1, #t2 do
      t1[#t1 + 1] = t2[i]
    end
  end
  return t1
end

--- Determine if the package is global or relative to the file
---@param import_string the string with the import statement
---@return bool true if the package is global
function deps.is_global_package(import_string)
  if string.find(import_string, '@local') then
    return true
  else
    return false
  end

  return false
end

--- Get full path from global or relative import statement
---@param import_string the import statement
---@return string string the full path of the file
function deps.get_full_path(import_string)
  local path = ""

  if deps.is_global_package(import_string) then
    if jit.os == 'Windows' then
      import_string = string.gsub(import_string, "@local/", "")

      local package_name = string.gsub(import_string, "%p%d.%d.%d", "")
      local version = string.gsub(import_string, "%a+:", "")
      path = vim.fn.expand('~') ..
          '\\appdata\\local' .. '\\typst\\packages\\local\\' .. package_name .. '\\' .. version .. '\\'

      path = deps.add_entry_point(path)
    elseif jit.os == 'Linux' then
      print('macunix')
      import_string = string.gsub(import_string, "@local/", "")

      local package_name = string.gsub(import_string, "%p%d.%d.%d", "")
      local version = string.gsub(import_string, "%a+:", "")
      path = vim.fn.expand('~') ..
          '/.local/share' .. '/typst/packages/local' .. "/" .. package_name .. '/' .. version .. '/'
      path = deps.add_entry_point(path)
    end
  else
    if jit.os == 'Windows' then
      path = vim.fn.expand("%:p:h") .. '\\' .. import_string
    else
      path = vim.fn.expand("%:p:h") .. '/' .. import_string
    end
  end
  return path
end

--- Get entry point in typst.toml file in global packages
---@param path path to the package directory
---@return string string the path to the entry point of the global package
function deps.add_entry_point(path)
  local toml = deps.read_file(path .. 'typst.toml')

  print(path .. 'typst.toml')
  for match in string.gmatch(toml, 'entrypoint%s*=%s%C+') do
    match = string.gsub(match, "entrypoint%s*=%s", "")
    match = string.gsub(match, '"', '')

    if jit.os == 'Windows' then
      match = string.gsub(match, "/", "\\")
    end

    path = path .. match
    break
  end



  return path
end

--- Read a file and return it's content
---@param path path to the file to read
---@return string string of the whole content of the file
function deps.read_file(path)
  local file = io.open(path, "r") -- r read mode and b binary mode
  if not file then return nil end
  local content = file:read "*a"  -- *a or *all reads the whole file
  file:close()
  return content
end

return deps
