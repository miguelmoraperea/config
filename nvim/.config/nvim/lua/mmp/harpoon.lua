require('harpoon').setup({
    global_settings = {
        save_on_toggle = true,
        enter_on_sendcmd = true,
    },
    menu = {
        height = 20,
        width = 80,
    },
})

vim.api.nvim_set_keymap('n', '<Leader><Backspace>', '<Cmd>lua require("harpoon.ui").toggle_quick_menu()<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader><Backspace>c', '<Cmd>lua require("harpoon.cmd-ui").toggle_quick_menu()<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>mk', '<Cmd>lua require("harpoon.mark").add_file()<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>0', '<Cmd>lua require("harpoon.ui").nav_file(0)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>1', '<Cmd>lua require("harpoon.ui").nav_file(1)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>2', '<Cmd>lua require("harpoon.ui").nav_file(2)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>3', '<Cmd>lua require("harpoon.ui").nav_file(3)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>4', '<Cmd>lua require("harpoon.ui").nav_file(4)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>5', '<Cmd>lua require("harpoon.ui").nav_file(5)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>6', '<Cmd>lua require("harpoon.ui").nav_file(6)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>7', '<Cmd>lua require("harpoon.ui").nav_file(7)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>8', '<Cmd>lua require("harpoon.ui").nav_file(8)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>9', '<Cmd>lua require("harpoon.ui").nav_file(9)<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<Leader>10', '<Cmd>lua require("harpoon.ui").nav_file(10)<CR>', { noremap = true })
