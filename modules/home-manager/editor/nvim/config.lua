vim.cmd("colorscheme gruvbox")

vim.g.mapleader = " "
vim.g.maplocalleader = ","
vim.o.splitright = true
vim.o.number = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

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

local dap = require("dap")
dap.adapters.godot = {
	type = "server",
	host = "127.0.0.1",
	port = 6006,
}

dap.configurations.gdscript = {
	{
		type = "godot",
		request = "launch",
		name = "Launch scene",
		project = "${workspaceFolder}",
		launch_scene = true,
	},
}

-- LSP
vim.lsp.config.zls = {
  cmd = { 'zls' },
  root_markers = { 'build.zig', '.git' },
  filetypes = { 'zig' },
}

vim.lsp.config.ocamllsp = {
  cmd = { "ocamllsp" },
  filetypes = { "ocaml", "ocaml.menhir", "ocaml.interface", "ocaml.ocamllex", "reason", "dune" },
  root_markers = { "*.opam", "esy.json", "package.json", ".git", "dune-project", "dune-workspace" }
}

vim.lsp.config.pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyrightconfig.json", "pyproject.toml", "setup.py" },
}

vim.lsp.config.nil_ls = {
  cmd = { 'nil' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
}

vim.lsp.config.gopls = {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
}

vim.lsp.config.clangd = {
  cmd = {
    "clangd"
  },
  filetypes = {
    "c",
    "cpp",
    "objc",
    "objcpp",
    "cuda",
    "proto"
  },
}

vim.lsp.config.bash  = {
	cmd = { "bash-language-server", "start" },
	filetypes = { "sh", "bash", "zsh" },
}

vim.lsp.config.gdscript = {
	cmd = vim.lsp.rpc.connect("127.0.0.1", 6008),
	root_markers = { "project.godot" },
	filetypes = { "gdscript" },
}

vim.lsp.enable({ "bash", "zls", "ocamllsp", "pyright", "nil_ls", "clangd", "gopls", "gdscript" })
