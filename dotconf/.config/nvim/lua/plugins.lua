-- ================================================================================

-- |------------|
-- |    init    |
-- |------------|

-- augroup for this config file
local augroup = vim.api.nvim_create_augroup('plugins.lua', { clear = true })
local function create_autocmd(event, opts)
  vim.api.nvim_create_autocmd(event, vim.tbl_extend('force', { group = augroup }, opts))
end

local mini = require('_modules.mini')
local add, now, later = mini.add, mini.now, mini.later

-- ================================================================================

-- |-----------|
-- |    now    |
-- |-----------|

-- Icon provider
now(function() require('mini.icons').setup() end)

-- Common configuration presets
now(function()
  require('mini.basics').setup({
    options = {
      extra_ui = true,
    },
    mappings = {
      option_toggle_prefix = 'm',
    },
  })
end)

-- Minimal and fast statusline module with opinionated default look
now(function()
  require('mini.statusline').setup()
  vim.opt.laststatus = 3
  vim.opt.cmdheight = 0
  -- cf. https://github.com/Shougo/shougo-s-github/blob/2f1c9acacd3a341a1fa40823761d9593266c65d4/vim/rc/vimrc#L47-L49
  create_autocmd({ 'RecordingEnter', 'CmdlineEnter' }, {
    pattern = '*',
    callback = function()
      vim.opt.cmdheight = 1
    end,
  })
  create_autocmd('RecordingLeave', {
    pattern = '*',
    callback = function()
      vim.opt.cmdheight = 0
    end,
  })
  create_autocmd('CmdlineLeave', {
    pattern = '*',
    callback = function()
      if vim.fn.reg_recording() == '' then
        vim.opt.cmdheight = 0
      end
    end,
  })
end)

-- Miscellaneous useful functions
now(function()
  require('mini.misc').setup()
  MiniMisc.setup_restore_cursor()
  vim.keymap.set('n', 'mz', function() MiniMisc.zoom(0, {}) end, { desc = 'Zoom current buffer' })
end)

-- Show notifications
now(function()
  require('mini.notify').setup()
  vim.api.nvim_create_user_command('NotifyHistory', function()
    MiniNotify.show_history()
  end, { desc = 'Show notify history' })
end)

-- Session management (read, write, delete)
now(function()
  require('mini.sessions').setup()
  local function is_blank(arg)
    return arg == nil or arg == ''
  end
  local function get_sessions(lead)
    -- ref: https://qiita.com/delphinus/items/2c993527df40c9ebaea7
    return vim
        .iter(vim.fs.dir(MiniSessions.config.directory))
        :map(function(v)
          local name = vim.fn.fnamemodify(v, ':t:r')
          return vim.startswith(name, lead) and name or nil
        end)
        :totable()
  end
  vim.api.nvim_create_user_command('SessionWrite', function(arg)
    local session_name = is_blank(arg.args) and vim.v.this_session or arg.args
    if is_blank(session_name) then
      vim.notify('No session name specified', vim.log.levels.WARN)
      return
    end
    vim.cmd('%argdelete')
    MiniSessions.write(session_name)
  end, { desc = 'Write session', nargs = '?', complete = get_sessions })

  vim.api.nvim_create_user_command('SessionDelete', function(arg)
    MiniSessions.select('delete', { force = arg.bang })
  end, { desc = 'Delete session', bang = true })

  vim.api.nvim_create_user_command('SessionLoad', function()
    MiniSessions.select('read', { verbose = true })
  end, { desc = 'Load session' })

  vim.api.nvim_create_user_command('SessionEscape', function()
    vim.v.this_session = ''
  end, { desc = 'Escape session' })

  vim.api.nvim_create_user_command('SessionReveal', function()
    if is_blank(vim.v.this_session) then
      vim.print('No session')
      return
    end
    vim.print(vim.fn.fnamemodify(vim.v.this_session, ':t:r'))
  end, { desc = 'Reveal session' })
end)

-- Fast and flexible start screen
now(function() require('mini.starter').setup() end)

-- Navigate and manipulate file system
now(function()
  require('mini.files').setup()
  vim.keymap.set('n', '<space>e', MiniFiles.open, { desc = 'Open file explorer' })
end)


-- ================================================================================

-- |-------------|
-- |    later    |
-- |-------------|

-- extend and create a/i textobjects
later(function()
  local gen_ai_spec = require('mini.extra').gen_ai_spec
  require('mini.ai').setup({
    custom_textobjects = {
      B = gen_ai_spec.buffer(),
      D = gen_ai_spec.diagnostic(),
      I = gen_ai_spec.indent(),
      L = gen_ai_spec.line(),
      N = gen_ai_spec.number(),
      J = { { '()%d%d%d%d%-%d%d%-%d%d()', '()%d%d%d%d%/%d%d%/%d%d()' } }
    },
  })
end)

-- Align text interactively
later(function() require('mini.align').setup() end)

-- Autocompletion and signature help plugin
later(function()
  require('mini.fuzzy').setup()
  require('mini.completion').setup({
    lsp_completion = {
      process_items = MiniFuzzy.process_lsp_items,
    },
  })

  -- improve fallback completion
  vim.opt.complete = { '.', 'w', 'k', 'b', 'u' }
  vim.opt.completeopt:append('fuzzy')
  -- vim.opt.dictionary:append('/usr/share/dict/words')

  -- define keycodes
  local keys = {
    cn = vim.keycode('<c-n>'),
    cp = vim.keycode('<c-p>'),
    ct = vim.keycode('<c-t>'),
    cd = vim.keycode('<c-d>'),
    cr = vim.keycode('<cr>'),
    cy = vim.keycode('<c-y>'),
  }

  -- select by <tab>/<s-tab>
  vim.keymap.set('i', '<tab>', function()
    -- popup is visible -> next item
    -- popup is NOT visible -> add indent
    return vim.fn.pumvisible() == 1 and keys.cn or keys.ct
  end, { expr = true, desc = 'Select next item if popup is visible' })
  vim.keymap.set('i', '<s-tab>', function()
    -- popup is visible -> previous item
    -- popup is NOT visible -> remove indent
    return vim.fn.pumvisible() == 1 and keys.cp or keys.cd
  end, { expr = true, desc = 'Select previous item if popup is visible' })

  -- complete by <cr>
  vim.keymap.set('i', '<cr>', function()
    if vim.fn.pumvisible() == 0 then
      -- popup is NOT visible -> insert newline
      return require('mini.pairs').cr() -- 注意2
    end
    local item_selected = vim.fn.complete_info()['selected'] ~= -1
    if item_selected then
      -- popup is visible and item is selected -> complete item
      return keys.cy
    end
    -- popup is visible but item is NOT selected -> hide popup and insert newline
    return keys.cy .. keys.cr
  end, { expr = true, desc = 'Complete current item if item is selected' })

  require('mini.snippets').setup({
    mappings = {
      jump_prev = '<c-k>',
    },
  })
end)

-- Move any selection in any direction
later(function() require('mini.move').setup() end)

-- Text edit operators
later(function()
  require('mini.operators').setup({
    replace = { prefix = 'R' },
    exchange = { prefix = 'g/' },
  })

  vim.keymap.set('n', 'RR', 'R', { desc = 'Replace mode' })
end)

-- Highlight patterns in text
later(function()
  local hipatterns = require('mini.hipatterns')
  local hi_words = require('mini.extra').gen_highlighter.words
  hipatterns.setup({
    highlighters = {
      -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
      fixme = hi_words({ 'FIXME', 'Fixme', 'fixme' }, 'MiniHipatternsFixme'),
      hack = hi_words({ 'HACK', 'Hack', 'hack' }, 'MiniHipatternsHack'),
      todo = hi_words({ 'TODO', 'Todo', 'todo' }, 'MiniHipatternsTodo'),
      note = hi_words({ 'NOTE', 'Note', 'note' }, 'MiniHipatternsNote'),
      -- Highlight hex color strings (`#rrggbb`) using that color
      hex_color = hipatterns.gen_highlighter.hex_color(),
    },
  })
end)

-- Automatic highlighting of word under cursor
later(function() require('mini.cursorword').setup() end)

-- Visualize and work with indent scope
later(function() require('mini.indentscope').setup() end)

-- Work with trailing whitespace
later(function()
  require('mini.trailspace').setup()
  vim.api.nvim_create_user_command(
    'Trim',
    function()
      MiniTrailspace.trim()
      MiniTrailspace.trim_last_lines()
    end,
    { desc = 'Trim trailing space and last blank lines' }
  )
end)

-- Minimal and fast autopairs
later(function() require('mini.pairs').setup() end)

-- Fast and feature-rich surround actions
later(function() require('mini.surround').setup() end)

-- Show next key clues
later(function()
  local function mode_nx(keys)
    return { mode = 'n', keys = keys }, { mode = 'x', keys = keys }
  end
  local clue = require('mini.clue')
  clue.setup({
    triggers = {
      -- Leader triggers
      mode_nx('<leader>'),

      -- Built-in completion
      { mode = 'i', keys = '<c-x>' },

      -- `g` key
      mode_nx('g'),

      -- Marks
      mode_nx("'"),
      mode_nx('`'),

      -- Registers
      mode_nx('"'),
      { mode = 'i', keys = '<c-r>' },
      { mode = 'c', keys = '<c-r>' },

      -- Window commands
      { mode = 'n', keys = '<c-w>' },

      -- bracketed commands
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },

      -- `z` key
      mode_nx('z'),

      -- surround
      mode_nx('s'),

      -- text object
      { mode = 'x', keys = 'i' },
      { mode = 'x', keys = 'a' },
      { mode = 'o', keys = 'i' },
      { mode = 'o', keys = 'a' },

      -- option toggle (mini.basics)
      { mode = 'n', keys = 'm' },
    },

    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers({ show_contents = true }),
      clue.gen_clues.windows({ submode_resize = true, submode_move = true }),
      clue.gen_clues.z(),
      { mode = 'n', keys = 'mm', desc = '+mini.map' },
    },
  })
end)

-- Minimal and fast tabline showing listed buffers
later(function() require('mini.tabline').setup() end)

-- Buffer removing, preserving window layout
later(function()
  require('mini.bufremove').setup()
  vim.keymap.set('n', '<space>d', MiniBufremove.delete, { desc = 'Remove buffer' })
end)

-- Pick anything
later(function()
  require('mini.pick').setup()

  vim.ui.select = MiniPick.ui_select

  vim.keymap.set('n', '<space>f', function()
    MiniPick.builtin.files({ tool = 'git' })
  end, { desc = 'mini.pick.files' })

  vim.keymap.set('n', '<space>b', function()
    local wipeout_cur = function()
      vim.api.nvim_buf_delete(MiniPick.get_picker_matches().current.bufnr, {})
    end
    local buffer_mappings = { wipeout = { char = '<c-d>', func = wipeout_cur } }
    MiniPick.builtin.buffers({ include_current = false }, { mappings = buffer_mappings })
  end, { desc = 'mini.pick.buffers' })

  require('mini.visits').setup()
  vim.keymap.set('n', '<space>h', function()
    require('mini.extra').pickers.visit_paths()
  end, { desc = 'mini.extra.visit_paths' })

  vim.keymap.set('c', 'h', function()
    if vim.fn.getcmdtype() .. vim.fn.getcmdline() == ':h' then
      return '<c-u>Pick help<cr>'
    end
    return 'h'
  end, { expr = true, desc = 'mini.pick.help' })
end)

-- Work with diff hunks
later(function() require('mini.diff').setup() end)

-- Git integration
later(function()
  require('mini.git').setup()
  vim.keymap.set({ 'n', 'x' }, '<space>gs', MiniGit.show_at_cursor, { desc = 'Show at cursor' })
end)

-- Jump to next/previous single character
later(function()
  require('mini.jump').setup({
    delay = {
      idle_stop = 0,
    },
  })
end)

-- Jump within visible lines via iterative label filtering
later(function() require('mini.jump2d').setup() end)

-- Animate common Neovim actions
later(function()
  local animate = require('mini.animate')
  animate.setup({
    cursor = {
      -- Animate for 100 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 100, unit = 'total' }),
    },
    scroll = {
      -- Animate for 150 milliseconds with linear easing
      timing = animate.gen_timing.linear({ duration = 150, unit = 'total' }),
    }
  })
end)

-- Go forward/backward with square brackets
later(function() require('mini.bracketed').setup() end)

-- Split and join arguments
later(function()
  require('mini.splitjoin').setup({
    mappings = {
      toggle = 'gS',
      split = 'ss',
      join = 'sj',
    },
  })
end)

-- Window with buffer text overview, scrollbar, and highlights
later(function()
  local map = require('mini.map')
  map.setup({
    integrations = {
      map.gen_integration.builtin_search(),
      map.gen_integration.diff(),
      map.gen_integration.diagnostic(),
    },
    symbols = {
      scroll_line = '▶',
    }
  })
  vim.keymap.set('n', 'mmf', MiniMap.toggle_focus, { desc = 'MiniMap.toggle_focus' })
  vim.keymap.set('n', 'mms', MiniMap.toggle_side, { desc = 'MiniMap.toggle_side' })
  vim.keymap.set('n', 'mmt', MiniMap.toggle, { desc = 'MiniMap.toggle' })
end)

-- Comment lines
later(function() require('mini.comment').setup() end)

-- ================================================================================

-- |-----------|
-- |    add    | : External modules (Plugins)
-- |-----------|

-- avoid error
vim.treesitter.start = (function(wrapped)
  return function(bufnr, lang)
    lang = lang or vim.fn.getbufvar(bufnr or '', '&filetype')

    pcall(wrapped, bufnr, lang)
  end
end)(vim.treesitter.start)

add({
  source = 'https://github.com/nvim-treesitter/nvim-treesitter',
  hooks = {
    post_checkout = function()
      vim.cmd.TSUpdate()
    end
  },
})
---@diagnostic disable-next-line: missing-fields
require('nvim-treesitter.configs').setup({
  -- auto-install parsers
  ensure_installed = { 'lua', 'vim', 'tsx' },
  highlight = { enable = true },
})

add({
  source = 'https://github.com/JoosepAlviste/nvim-ts-context-commentstring',
})
require('ts_context_commentstring').setup({})

add({ source = 'https://github.com/stevearc/quicker.nvim' })
local quicker = require('quicker')
vim.keymap.set('n', 'mq', function()
  quicker.toggle()
  quicker.refresh()
end, { desc = 'Toggle quickfix' })
quicker.setup({
  keys = {
    {
      ">",
      function()
        require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
      end,
      desc = "Expand quickfix context",
    },
    {
      "<",
      function()
        require("quicker").collapse()
      end,
      desc = "Collapse quickfix context",
    },
  },
})

add({ source = 'https://github.com/zbirenbaum/copilot.lua' })

---@diagnostic disable-next-line: undefined-field
require('copilot').setup({
  suggestion = {
    auto_trigger = true,
    hide_during_completion = false,
    keymap = {
      accept = '<c-e>',
    },
  },
  filetypes = {
    markdown = true,
    gitcommit = true,
    ['*'] = function()
      -- disable for files with specific names
      local fname = vim.fs.basename(vim.api.nvim_buf_get_name(0))
      local disable_patterns = { 'env', 'conf', 'local', 'private' }
      return vim.iter(disable_patterns):all(function(pattern)
        return not string.match(fname, pattern)
      end)
    end,
  },
})

-- set CopilotSuggestion as underlined comment
local hl = vim.api.nvim_get_hl(0, { name = 'Comment' })
vim.api.nvim_set_hl(0, 'CopilotSuggestion', vim.tbl_extend('force', hl, { underline = true }))

add({
  source = 'https://github.com/CopilotC-Nvim/CopilotChat.nvim',
  depends = {
    'https://github.com/nvim-lua/plenary.nvim',
    'https://github.com/zbirenbaum/copilot.lua'
  },
})

require('CopilotChat').setup()
vim.keymap.set({ 'n', 'x' }, '<space>c', ':CopilotChat ', { desc = 'Open Copilot Chat' })

