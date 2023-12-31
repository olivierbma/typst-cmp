local M = {}

local deps = require('typst-cmp.dependencies')
local cmp = require('cmp')
local ls = require('luasnip')
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require('luasnip.util.events')
local ai = require('luasnip.nodes.absolute_indexer')
local extras = require('luasnip.extras')
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require('luasnip.extras.fmt').fmt
local fmta = require('luasnip.extras.fmt').fmta
local conds = require('luasnip.extras.expand_conditions')
local postfix = require('luasnip.extras.postfix').postfix
local types = require('luasnip.util.types')
local parse = require('luasnip.util.parser').parse_snippet
local ms = ls.multi_snippet
local k = require('luasnip.nodes.key_indexer').new_key



--- setup the plugin
function M.setup()
  local dependencies = deps.get_imports()



  for index, value in ipairs(dependencies) do
    local snipps = M.get_functions(value)
    for key, arg in pairs(snipps) do
      local snip = M.get_snip_from_arg(arg)
      ls.add_snippets('typst', snip)
    end
  end


  ls.config.setup {}

  cmp.setup {
    snippet = {
      expand = function(args)
        ls.lsp_expand(args.body)
      end,
    },
    mapping = cmp.mapping.preset.insert {
      ['<C-d>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete {},
      ['<CR>'] = cmp.mapping.confirm {
        behavior = cmp.ConfirmBehavior.Replace,
        select = true,
      },
      ['<Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif ls.expand_or_jumpable() then
          ls.expand_or_jump()
        else
          fallback()
        end
      end, { 'i', 's' }),
      ['<S-Tab>'] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif ls.jumpable(-1) then
          ls.jump(-1)
        else
          fallback()
        end
      end, { 'i', 's' }),
    },
    sources = {
      { name = 'nvim_lsp' },
      { name = 'luasnip' },
    },
  }
end

--- Create snippets from table with function name and arguments
---@param arg table with .name and .args fields
---@return table table with luasnip snippets
function M.get_snip_from_arg(arg)
  local name = arg.name
  name = string.gsub(name, '\r', '') -- fix for Unix to remove carriage returns if applicable
  local args = arg.args
  local jump_nb = 1

  local snip = {}

  local expand_snip = {}

  table.insert(expand_snip, t("#"))
  table.insert(expand_snip, t(name))

  if args[#args] == 'body' then
    for index, argument in pairs(args) do
      if argument == 'body' then
        if #args > 1 then
          table.insert(expand_snip, t(")"))
          table.insert(expand_snip, t("["))

          table.insert(expand_snip, i(jump_nb, "body"))
          jump_nb = jump_nb + 1
          table.insert(expand_snip, t("]"))
        else
          table.insert(expand_snip, t("["))

          table.insert(expand_snip, i(jump_nb, "body"))
          jump_nb = jump_nb + 1
          table.insert(expand_snip, t("]"))
        end
      else
        table.insert(expand_snip, t('('))
        if string.find(argument, ':') then
          local field_name = string.match(argument, '^[^:]*')
          local base_value = string.match(argument, '[^:]*$')

          table.insert(expand_snip, t(field_name .. ': '))
          table.insert(expand_snip, i(jump_nb, base_value))
          jump_nb = jump_nb + 1
        else
          table.insert(expand_snip, i(jump_nb, argument))
          if #args ~= index then
            table.insert(expand_snip, t(', '))
          end
        end
      end
    end
  else
    table.insert(expand_snip, t('('))
    for index, argument in pairs(args) do
      if string.find(argument, ':') then
        local field_name = string.match(argument, '^[^:]*')
        local base_value = string.match(argument, '[^:]*$')

        table.insert(expand_snip, t(field_name .. ': '))
        table.insert(expand_snip, i(jump_nb, base_value))
        jump_nb = jump_nb + 1

        if #args ~= index then
          table.insert(expand_snip, t(', '))
        end
      else
        table.insert(expand_snip, i(jump_nb, argument))
        if #args ~= index then
          table.insert(expand_snip, t(', '))
        end
      end
    end

    table.insert(expand_snip, t(')'))
  end

  table.insert(snip, s(name, expand_snip))

  return snip
end

--- Create a table with all the functions and argument from a file
---@param path path to the file that will be parsed
---@return table a table with .name field for function name and .args field which is a table with all arguments
function M.get_functions(path)
  local file = deps.read_file(path)
  local functions = {}

  if file == nil then
    return {}
  end

  for match in string.gmatch(file, '%s*#let%s*[%C]+') do
    match = string.gsub(match, "%s*=%s*%C*$", '')
    local function_name = string.match(string.gsub(match, '#let%s?', ''), '^[^(]+')



    local arguments = string.match(match, '%b()')
    if arguments == nil then
      goto continue
    end
    arguments = string.sub(arguments, 2, string.len(arguments) - 1)


    local arguments_table = {}
    for arg in string.gmatch(arguments, '[^,]+') do
      table.insert(arguments_table, arg)
    end


    local func = {}

    func.name = string.gsub(function_name, "\n", "")
    func.args = {}

    for _, value in pairs(arguments_table) do
      value = string.gsub(value, '^%s*', '')
      table.insert(func.args, value)
    end

    table.insert(functions, func)

    ::continue::
  end

  return functions
end

--- Print the values in a table
---@param table table to print
function M.print_table(table)
  for _, value in pairs(table) do
    print(value)
  end
end

return M
