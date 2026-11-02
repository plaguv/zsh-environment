return {
	"mason-org/mason-lspconfig.nvim",
	dependencies = {
		"mason-org/mason.nvim",
		"neovim/nvim-lspconfig",
	},
	opts = {
		ensure_installed = { "pyrefly", "gopls", "rust_analyzer", "jdtls" },
		automatic_enable = true,
	},
}
