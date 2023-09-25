local deps = {}


function deps.buffer_to_string()
  local content = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  return table.concat(content, '\n')
end

function deps.get_imports(buffr)
  local pattern_reg = "#import%s?\"%g+\":"
  local import_reg = "%b\"\""

  local imports_table = {}

  for pattern in string.gmatch(buffr, pattern_reg) do
    for import in string.gmatch(pattern, import_reg) do
      import = string.gsub(import, "[\"]", "")
      table.insert(imports_table, deps.get_full_path(import))
    end
  end

  return imports_table
end

--- determine if package is global or a relative path
-- @param import_string the string inside the import statement in typst file
-- @return bool return true if global package
function deps.is_global_package(import_string)
  if string.find(import_string, '@local') then
    return true
  else
    return false
  end
end

function deps.get_full_path(import_string)
  local path = ""

  if deps.is_global_package(import_string) then
    if vim.fn.has('Windows_NT') then
      import_string = string.gsub(import_string, "@local/", "")

      local package_name = string.gsub(import_string, "%p%d.%d.%d", "")
      local version = string.gsub(import_string, "%a+:", "")
      path = vim.fn.expand('~') ..
          '\\appdata\\local' .. '\\typst\\packages\\local\\' .. package_name .. '\\' .. version .. '\\'

      path = deps.add_entry_point(path)
    else
      import_string = string.gsub(import_string, "@local/", "")

      local package_name = string.gsub(import_string, "%p%d.%d.%d", "")
      local version = string.gsub(import_string, "%a+:", "")
      path = vim.fn.expand('~') ..
          '.loca/share' .. '/typst/packages/local/' .. "/" .. package_name .. '/' .. version
      path = deps.add_entry_point(path)
    end
  else
    if vim.fn.has('Windows_NT') then
      path = vim.fn.expand("%:p:h") .. '\\' .. import_string
    else
      path = vim.fn.expand("%:p:h") .. '/' .. import_string
    end
  end
  return path
end

function deps.add_entry_point(path)
  local toml = deps.read_file(path .. 'typst.toml')

  for match in string.gmatch(toml, 'entrypoint%s*=%s%C+') do
    match = string.gsub(match, "entrypoint%s*=%s", "")
    match = string.gsub(match, '"', '')

    if vim.fn.has('Windows_NT') then
      match = string.gsub(match, "/", "\\")
    end

    path = path .. match
    break
  end



  return path
end

function deps.read_file(path)
  local file = io.open(path, "r") -- r read mode and b binary mode
  if not file then return nil end
  local content = file:read "*a"  -- *a or *all reads the whole file
  file:close()
  return content
end

return deps
