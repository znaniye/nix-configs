vim.opt.termguicolors = true

vim.cmd("colorscheme nord")

local function nord_float_highlights()
    local float_bg = "#3B4252" -- nord1
    local float_fg = "#D8DEE9" -- nord4
    local border_fg = "#4C566A" -- nord3

    vim.api.nvim_set_hl(0, "NormalFloat", { bg = float_bg, fg = float_fg })
    vim.api.nvim_set_hl(0, "FloatBorder", { bg = float_bg, fg = border_fg })
end

local nord_float_highlights_group = vim.api.nvim_create_augroup("NordFloatHighlights", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
    group = nord_float_highlights_group,
    callback = nord_float_highlights,
})

nord_float_highlights()

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
