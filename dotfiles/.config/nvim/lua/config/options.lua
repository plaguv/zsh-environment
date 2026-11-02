vim.g.mapleader = " "
vim.g.maplocalleader = " "

local options = {
	clipboard = "unnamedplus",
	completeopt = "menu,menuone,noinsert",
	confirm = true,
	cursorline = true,

	-- Keep the sign column visible so diagnostics do not shift text around.
	number = true,
	relativenumber = false,
	signcolumn = "yes",
	termguicolors = true,
	updatetime = 250,

	-- Editing defaults that work well across languages.
	expandtab = true,
	ignorecase = true,
	incsearch = true,
	list = true,
	listchars = {
		leadmultispace = "│   ",
		nbsp = "␣",
		tab = "»·",
		trail = "·",
	},
	shiftwidth = 4,
	smartcase = true,
	softtabstop = 4,
	tabstop = 4,
	undofile = true,
	wrap = false,
}

for name, value in pairs(options) do
	vim.opt[name] = value
end

-- Keep built-in filetype syntax highlighting available while Tree-sitter
-- parsers install or for filetypes without a configured parser.
vim.cmd("syntax enable")

vim.diagnostic.config({
	severity_sort = true,
	update_in_insert = false,
	underline = true,
	virtual_text = { prefix = "●", spacing = 2, source = "if_many" },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "✘",
			[vim.diagnostic.severity.WARN] = "▲",
			[vim.diagnostic.severity.INFO] = "ℹ",
			[vim.diagnostic.severity.HINT] = "➤",
		},
	},
	float = { border = "rounded", source = "if_many" },
})
