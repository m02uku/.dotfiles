-- ================================================================================
-- |--------------------------|
-- |    Editing / Mappings    |
-- |--------------------------|

-- Delete without affecting registers
vim.keymap.set({ 'n', 'x' }, 'x', '"_d', { desc = 'Blackhole delete (char)' })
vim.keymap.set('n', 'X', '"_D', { desc = 'Blackhole delete (line)' })
vim.keymap.set('o', 'x', 'd', { desc = 'Operator: delete with x' })

-- Repeat the last command
vim.keymap.set('n', '<space>;', '@:', { desc = 'Re-run last command' })

-- Source current script
vim.keymap.set({ 'n', 'x' }, 'so', ':source<cr>', { silent = true, desc = 'Source current script' })

-- Disable command-line window (q:)
vim.keymap.set('n', 'q:', '<nop>', { desc = 'Disable cmdwin' })

vim.keymap.set('n', '<space>/', ':Grep ', { desc = 'Grep' })
vim.keymap.set('n', '<space>?', ':Grep <c-r><c-w>', { desc = 'Grep current word' })

-- ================================================================================
-- |-----------------------------|
-- |    File / Window Control    |
-- |-----------------------------|

-- Save file
vim.keymap.set('n', '<space>w', '<cmd>write<cr>', { desc = 'Write file' })

-- Quit tab if possible; otherwise quit window
vim.keymap.set('n', '<space>q', function()
  if not pcall(vim.cmd.tabclose) then
    vim.cmd.quit()
  end
end, { desc = 'Quit tab or window' })
