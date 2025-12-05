-- ================================================================================
-- |---------------------|
-- |    UI / Behavior    |
-- |---------------------|

-- Keep at least 3 lines visible above and below the cursor
vim.opt.scrolloff = 3

-- Allow cursor movement to wrap across lines with certain keys
vim.opt.whichwrap = 'b,s,h,l,<,>,[,],~'


-- ================================================================================
-- |-----------------------|
-- |    Input / Editing    |
-- |-----------------------|

-- Convert tabs to spaces
vim.opt.expandtab = true

-- Round shifts to the nearest multiple of 'shiftwidth'
vim.opt.shiftround = true

-- Number of spaces used for each level of indentation
vim.opt.shiftwidth = 2

-- Number of spaces a <Tab> counts for while editing
vim.opt.softtabstop = 2

-- Share registers with the system clipboard
vim.opt.clipboard:append('unnamedplus,unnamed')

-- use rg for external-grep
vim.opt.grepprg = table.concat({
  'rg',
  '--vimgrep',
  '--trim',
  '--hidden',
  [[--glob='!.git']],
  [[--glob='!*.lock']],
  [[--glob='!*-lock.json']],
  [[--glob='!*generated*']],
}, ' ')
vim.opt.grepformat = '%f:%l:%c:%m'

