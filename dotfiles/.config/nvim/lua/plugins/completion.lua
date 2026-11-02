return {
	"saghen/blink.cmp",
	version = "*",
	dependencies = {
		"saghen/blink.lib",
		"rafamadriz/friendly-snippets",
	},
	build = "cargo build --release",
	opts = {
		keymap = {
			preset = "default",
			["<C-Space>"] = { "show" },
			["<C-@>"] = { "show" },
			["<Tab>"] = { "select_next", "fallback" },
			["<S-Tab>"] = { "select_prev", "fallback" },
			["<CR>"] = { "accept", "fallback" },
		},
		completion = {
			list = {
				selection = { preselect = true, auto_insert = false },
			},
			menu = { border = "rounded" },
			documentation = { auto_show = false },
			ghost_text = { enabled = false },
		},
		sources = {
			default = { "lsp", "path", "snippets", "buffer" },
			-- In Java, use semantic LSP results first and its buffer fallback.
			-- Keep method-template snippets out of type/member completion results.
			per_filetype = {
				java = { "lsp" },
			},
		},
		snippets = { preset = "default" },
	},
}
