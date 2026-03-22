local vim = vim
local ts_utils = require('nvim-treesitter.ts_utils')

local function locate_document_node(node)
  for subnode, _ in node:iter_children() do
    if subnode:type() == 'document' then
      return subnode
    end
  end
  return nil
end

local function locate_node(node, path, n)
  if #path < n then
    return node
  end

  if node:type() == 'block_mapping' then
    for subnode, _ in node:iter_children() do
      local key_node = subnode:child(0):child(0)
      local key = vim.treesitter.get_node_text(key_node, 0)
      if key == path[n] then
	return locate_node(subnode:child(2), path, n+1)
      end
    end
    print('no such key ', path[n])
    return nil
  elseif node:child_count() == 1 then
    return locate_node(node:child(0), path, n)
  else
    print('unknown node type ', node, node:sexpr())
    return nil
  end
end


local function extract_ref()
  local node = ts_utils.get_node_at_cursor(0):parent():parent()
  if node:type() ~= 'block_mapping_pair' then
    return nil
  end

  local key_node = node:child(0):child(0)
  local value_node = node:child(2):child(0)
  if vim.treesitter.get_node_text(key_node, 0) ~= '$ref' then
    print('not a $ref')
    return nil
  end

  local value = vim.treesitter.get_node_text(value_node, 0)
  value = value:gsub('"', '')
  value = value:gsub('\'', '')
  local parts = vim.split(value, '#')
  if #parts ~= 2 then
    print('not 2')
    return nil
  end

  return parts
end

local M = {}
function M.goto_definition()
  local ref_tbl = extract_ref()
  if not ref_tbl then
    return nil
  end

  local fname = ref_tbl[1]
  local ref = ref_tbl[2]
  local path = vim.split(ref, '/')

  if fname ~= '' then
    local local_fname = vim.api.nvim_buf_get_name(0)
    local local_dirname = vim.fs.dirname(local_fname)
    vim.cmd{cmd = 'edit', args = {vim.fs.joinpath(local_dirname, fname)}}
  end

  local tree = vim.treesitter.get_parser():parse()[1]
  local target_node = locate_node(locate_document_node(tree:root()), path, 2)
  if target_node then
    ts_utils.goto_node(target_node:parent(), false, false)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd({'BufEnter', 'BufWinEnter'}, {
    pattern = {'*.yaml'},
    callback = function(ev)
      vim.api.nvim_set_keymap('n', 'gd', '', {noremap = true, callback = M.goto_definition})
      vim.api.nvim_set_keymap('n', '<c+]>', '', {noremap = false, callback = M.goto_definition})
    end
  })
end

return M
