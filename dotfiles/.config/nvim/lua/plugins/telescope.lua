return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local telescope = require("telescope")
		local builtin = require("telescope.builtin")
		local fd = vim.fn.executable("fd") == 1 and "fd" or "fdfind"

		telescope.setup({
			defaults = {
				mappings = {
					i = { ["<C-u>"] = false, ["<C-d>"] = false },
				},
			},
			pickers = {
				find_files = {
					find_command = {
						fd,
						"--type",
						"f",
						"--hidden",
						"--follow",
						"--exclude",
						".git",
					},
				},
			},
		})

		local map = vim.keymap.set
		map("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
		map("n", "<leader>fg", builtin.live_grep, { desc = "Search in files" })
		map("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
		map("n", "<leader>fh", builtin.help_tags, { desc = "Search help" })
		map("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
	end,
}
