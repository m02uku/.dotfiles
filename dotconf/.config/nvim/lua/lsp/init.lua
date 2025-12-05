-- ================================================================================

-- |------------|
-- |    init    |
-- |------------|

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('plugins.lua', { clear = true })
local function create_autocmd(argsent, opts)
  vim.api.nvim_create_autocmd(argsent, vim.tbl_extend('force', { group = augroup }, opts))
end

local mini = require('_modules.mini')
local now = mini.now

-- ================================================================================

now(function()
  -- |---------------------------|
  -- |    Per-language Config    |
  -- |---------------------------|

  -- Common settings for all languages
  vim.lsp.config('*', {
    root_markers = { '.git' },
    capabilities = require('mini.completion').get_lsp_capabilities(),
  })

  -- Lua language server
  vim.lsp.config.lua_ls = {
    cmd = { 'lua-language-server' },
    root_markers = {
      '.luarc.json',
      '.luarc.jsonc',
      '.luacheckrc',
      '.stylua.toml',
      'stylua.toml',
      'selene.toml',
      'selene.yml',
      '.git',
    },
    filetypes = { 'lua' },
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          pathStrict = true,
          path = { "?.lua", "?/init.lua" },
        },
        diagnostics = {
          globals = { 'vim' },
        },
        workspace = {
          library = vim.list_extend(vim.api.nvim_get_runtime_file("lua", true), {
            "${3rd}/luv/library",
            "${3rd}/busted/library",
            "${3rd}/luassert/library",
          }),
          checkThirdParty = "Disable",
        },
      },
    }
  }
  vim.lsp.enable({ 'lua_ls' })

  -- Python language server
  -- Pyright (型チェック & 補完)
  vim.lsp.config.pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = {
      "pyproject.toml",
      "setup.py",
      "setup.cfg",
      "requirements.txt",
      ".git",
    },
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic",
          autoSearchPaths = true,
          useLibraryCodeForTypes = true,
          diagnosticMode = "openFilesOnly",
        },
      },
    },

    -------------------------------------------------------------------
    -- ▼▼▼（オプション）venv 自動検出 使いたいときはコメント外す ▼▼▼
    -- before_init = function(params)
    --   local venv = os.getenv("VIRTUAL_ENV")
    --   if venv then
    --     params.processId = vim.NIL
    --     params.initializationOptions = {
    --       pythonPath = venv .. "/bin/python",
    --     }
    --   end
    -- end,
    -------------------------------------------------------------------
  }

  -- Ruff LSP（高速 Linter + 一部コードアクション）
  vim.lsp.config.ruff = {
    cmd = { "ruff-lsp" },
    filetypes = { "python" },
    root_markers = {
      "pyproject.toml",
      "ruff.toml",
      ".ruff.toml",
      ".git",
    },
  }

  -- ================================================================================

  -- |--------------------|
  -- |    Other Config    |
  -- |--------------------|

  vim.api.nvim_create_user_command(
    'LspHealth',
    'checkhealth vim.lsp',
    { desc = 'LSP health check' }
  )

  vim.api.nvim_create_user_command(
    'LspClients',
    'lua print(vim.inspect(vim.lsp.get_clients()))',
    { desc = 'LSP health check' }
  )

  create_autocmd('LspAttach', {
    callback = function(args)
      local client = assert(vim.lsp.get_client_by_id(args.data.client_id))

      if client:supports_method('textDocument/definition') then
        vim.keymap.set('n', 'grd', function()
          vim.lsp.buf.definition()
        end, { buffer = args.buf, desc = 'vim.lsp.buf.definition()' })
      end

      -- Auto format on save
      -- 2 settings below from: https://blog.devoc.ninja/2025/nvim-v0-11-0-language-server-feature/
      if not client:supports_method('textDocument/willSaveWaitUntil') and client:supports_method('textDocument/formatting') then
        vim.api.nvim_create_autocmd('BufWritePre', {
          buffer = args.buf,
          callback = function()
            vim.lsp.buf.format({ bufnr = args.buf, id = client.id, timeout_ms = 1000, async = false })
            vim.notify('Formatted with ' .. client.name, vim.log.levels.INFO, { title = 'LSP' })
          end
        })
      end

      if client:supports_method('textDocument/completion') then
        vim.lsp.completion.enable(true, client.id, args.buf, { autotrigger = true })
      end
    end,
  })

  vim.diagnostic.config({
    virtual_text = true
  })
end)
