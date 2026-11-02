vim.keymap.set("n", "gl", function()
	vim.diagnostic.open_float(nil, {
		scope = "line",
		border = "rounded",
		source = "if_many",
	})
end, { desc = "Show line diagnostics" })
