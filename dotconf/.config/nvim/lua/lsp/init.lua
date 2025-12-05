-- ================================================================================

-- |------------|
-- |    init    |
-- |------------|

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('lsp/init.lua', { clear = true })
local function create_autocmd(event, opts)
  vim.api.nvim_create_autocmd(event, vim.tbl_extend('force', { group = augroup }, opts))
end

-- ================================================================================

vim.diagnostic.config({
  virtual_text = true
})

create_autocmd('LspAttach', {
  callback = function(args)
    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

    if client:supports_method('textDocument/definition') then
      vim.keymap.set('n', 'grd', function()
        vim.lsp.buf.definition()
      end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })
    end

    if client:supports_method('textDocument/formatting') then
      vim.keymap.set('n', '<space>i', function()
        vim.lsp.buf.format({ bufnr = args.buf, id = client.id })
      end, { buffer = args.buf, desc = 'Format buffer' })
    end
  end,
})

vim.lsp.config('*', {
  root_markers = { '.git' },
  capabilities = require('mini.completion').get_lsp_capabilities(),
})

-- このファイルの存在するディレクトリ
local dirname = vim.fn.stdpath('config') .. '/lua/lsp'

-- 設定したlspを保存する配列
local lsp_names = {}

for file in vim.fs.dir(dirname) do
  -- file はファイル名のみ
  if file ~= 'init.lua' and file:sub(-4) == '.lua' then
    local name = file:sub(1, -5)
    local ok, opts = pcall(require, 'lsp.' .. name)
    if ok then
      vim.lsp.config(name, opts)
      table.insert(lsp_names, name)
    else
      vim.notify('Error loading LSP: ' .. name .. '\n' .. opts, vim.log.levels.WARN)
    end
  end
end

-- 読み込めたlspを有効化
vim.lsp.enable(lsp_names)

vim.api.nvim_create_user_command(
  'LspHealth',
  'checkhealth vim.lsp',
  { desc = 'LSP health check' })
