vim.cmd("colorscheme nord")

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.o.splitright = true
vim.o.number = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<C-l>", ":bnext<CR>", { noremap = true })
vim.keymap.set("n", "<C-h>", ":bprevious<CR>", { noremap = true })
vim.keymap.set("n", "<leader>bd", ":bd!<CR>", { noremap = true })
vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)

vim.diagnostic.config({
    virtual_text = true,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
})
