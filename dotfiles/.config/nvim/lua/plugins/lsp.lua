return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"saghen/blink.cmp",
	},
	config = function()
		local servers = {
			"bashls",
			"gopls",
			"jdtls",
			"jsonls",
			"lua_ls",
			"pyright",
			"rust_analyzer",
			"ts_ls",
			"yamlls",
		}

		local capabilities = require("blink.cmp").get_lsp_capabilities()
		local on_attach = function(client, bufnr)
			-- Blink owns the completion menu; keep Neovim's built-in LSP
			-- completion disabled to avoid a second popup in the same buffer.
			if vim.lsp.completion then
				vim.lsp.completion.enable(false, client.id, bufnr)
			end

			local map = function(lhs, rhs, desc)
				vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
			end

			map("gd", vim.lsp.buf.definition, "Go to definition")
			map("gD", vim.lsp.buf.declaration, "Go to declaration")
			map("gr", vim.lsp.buf.references, "Find references")
			map("gi", vim.lsp.buf.implementation, "Go to implementation")
			map("K", vim.lsp.buf.hover, "Hover documentation")
			map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
			map("<leader>ca", vim.lsp.buf.code_action, "Code action")
		end

		require("mason").setup({ PATH = "prepend" })
		require("mason-lspconfig").setup({
			ensure_installed = servers,
			-- Mason enables servers after they are already installed. This avoids
			-- starting (for example) jdtls while its first install is still running.
			automatic_enable = true,
		})

		-- Keep server setup explicit so each server uses the same completion and
		-- buffer keymap defaults. Mason installs the executables on first launch.
		local modern_lsp_api = vim.lsp.config ~= nil and vim.lsp.enable ~= nil
		local lspconfig = not modern_lsp_api and require("lspconfig") or nil
		for _, server in ipairs(servers) do
			local settings = {
				capabilities = capabilities,
				on_attach = on_attach,
			}
			if server == "lua_ls" then
				settings.settings = {
					Lua = {
						completion = { callSnippet = "Replace" },
						diagnostics = { globals = { "vim" } },
						workspace = { checkThirdParty = false },
					},
				}
			end
			if modern_lsp_api then
				-- mason-lspconfig enables configured servers after installation.
				vim.lsp.config(server, settings)
			else
				lspconfig[server].setup(settings)
			end
		end
	end,
}
