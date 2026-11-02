return {
	"AlexvZyl/nordic.nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("nordic").setup({
			on_highlight = function(highlights, palette)
				highlights["@attribute"] = { fg = palette.orange.base, bold = true }
			end,
		})
		vim.cmd.colorscheme("nordic")
	end,
}
