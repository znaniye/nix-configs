vim.cmd("colorscheme gruvbox")

vim.g.mapleader = ","
vim.o.number = true
vim.o.relativenumber = true

vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

vim.api.nvim_set_keymap("n", "<C-l>", ":bnext<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-h>", ":bprevious<CR>", { noremap = true })
vim.api.nvim_set_keymap("n", "<C-y>", ":ToggleTerm direction=float size=40<CR>", { noremap = true })

-- LSP
local lspconfig = require("lspconfig")

function add_lsp(server, options)
	local binary

	if options.on_attach == nil then
		options.on_attach = on_attach
	end

	if options["cmd"] ~= nil then
		binary = options["cmd"][1]
	else
		binary = server["document_config"]["default_config"]["cmd"][1]
	end

	if vim.fn.executable(binary) == 1 then
		server.setup(options)
	end
end

function on_attach(client, bufnr)
	local function buf_set_keymap(...)
		vim.api.nvim_buf_set_keymap(bufnr, ...)
	end
	local opts = { noremap = true, silent = true }

	-- Keybindings LSP
	buf_set_keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	buf_set_keymap("n", "<C-s>", '<cmd>lua vim.lsp.buf.format({ async = true }); vim.cmd("write")<CR>', opts)
	buf_set_keymap("i", "<C-s>", '<Esc><cmd>lua vim.lsp.buf.format({ async = true }); vim.cmd("write")<CR>i', opts)
end

add_lsp(lspconfig.ols, {})
add_lsp(lspconfig.clangd, { { noremap = false, silent = false } })
add_lsp(lspconfig.ts_ls, {})
add_lsp(lspconfig.gopls, {})

add_lsp(lspconfig.lua_ls, {
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = {
					"${3rd}/love2d/library",
				},
			},
		},
	},
})

add_lsp(lspconfig.erlangls, {})
add_lsp(lspconfig.pylsp, {})
add_lsp(lspconfig.nil_ls, {})
