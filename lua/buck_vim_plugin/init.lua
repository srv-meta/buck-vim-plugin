local cmp = require 'cmp'

local source = {}

local constants = {
  max_lines = 20,
}

---@class buck_vim_plugin.Option
---@field public default_repo_path string
---@field public target_files string[]

---@type buck_vim_plugin.Option
local defaults = {
  default_repo_path = "",
  target_files = { "BUCK", 'TARGETS' },
}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
  return { '/', ':' }
end

source.complete = function(self, params, callback)
  local option = self:_validate_option(params)

  local dirname = self:_dirname(params, option)
  if not dirname then
    return callback()
  end

  self:_candidates(dirname, params, option, function(err, candidates)
    if err then
      return callback()
    end
    callback(candidates)
  end)
end

source.resolve = function(self, completion_item, callback)
  local data = completion_item.data
  if data and data.type ~= 'directory' then
    local ok, documentation = pcall(function()
      return self:_get_documentation(completion_item.label, data.path, constants.max_lines)
    end)
    if ok then
      completion_item.documentation = documentation
    end
  end
  callback(completion_item)
end

source._dirname = function(self, params, option)
  local left = vim.fn.BuckDetectLeftTargetPos(params.context.cursor_before_line, vim.api.nvim_win_get_cursor(0)[2])
  if left == -1 then
    return nil
  end

  -- vim.fn.BuckDetectLeftTargetPos returns 0-based index, while strings/arrays in lua a 1-based, therefore +1
  local target_part = string.sub(params.context.cursor_before_line, left + 1,
    vim.fn.stridx(params.context.cursor_before_line, ":"))
  local tpath = vim.fn.BuckMapPath(target_part, false)

  if tpath == "" then
    return nil
  end

  return vim.fn.resolve(tpath)
end

source._candidates = function(_, dirname, params, option, callback)
  local fs, err = vim.loop.fs_scandir(dirname)
  if err then
    return callback(err, nil)
  end

  local items = {}

  local function add_targets_from(fname)
    for line in io.lines(dirname .. "/" .. fname) do
      local l
      local res
      l, _, res = string.find(line, '^%s*name%s*=%s*"(.+)"')
      if l ~= nil then
        table.insert(items,
          {
            label = res,
            kind = cmp.lsp.CompletionItemKind.Value,
            labelDetails = { detail = "Buck target" },
            data = {
              type = "target",
              path = dirname .. "/" .. fname,
            },
          })
      end
    end
  end

  if string.sub(params.context.cursor_before_line, vim.api.nvim_win_get_cursor(0)[2]) == ":" then
    for _, fname in ipairs(option.target_files) do
      if vim.loop.fs_stat(dirname .. "/" .. fname) then
        add_targets_from(fname)
      end
    end
  else
    while true do
      local name, fs_type, e = vim.loop.fs_scandir_next(fs)
      if e then
        return callback(fs_type, nil)
      end
      if not name then
        break
      end
      if string.sub(name, 1, 1) ~= '.' and fs_type == 'directory' then
        table.insert(items, {
          label = name,
          filterText = name,
          insertText = name,
          kind = cmp.lsp.CompletionItemKind.Folder,
          data = {
            type = 'directory',
            path = dirname .. "/" .. name
          },
        })
      end
    end
  end

  callback(nil, items)
end

---@return buck_vim_plugin.Option
source._validate_option = function(_, params)
  local option = vim.tbl_deep_extend('keep', params.option, defaults)
  vim.validate({
    default_repo_path = { option.default_repo_path, 'string' },
    target_files = { option.target_files, { 'string', 'table' } },
  })
  return option
end

source._get_documentation = function(_, target_name, filename, max_lines)
  local lncnt = max_lines / 2
  local cmd = "grep -E -A" ..
      lncnt .. " -B" .. lncnt .. " --color=none 'name\\s*=\\s*\"" .. target_name .. "\"' " .. filename
  local handle = io.popen(cmd)
  local text = handle:read "*a"
  handle:close()
  return { kind = cmp.lsp.MarkupKind.Markdown, value = "```\n" .. text .. "\n```" }
end

return source
