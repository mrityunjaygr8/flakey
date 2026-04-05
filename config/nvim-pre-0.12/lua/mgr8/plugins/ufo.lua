return {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	event = "VimEnter",
	keys = {
		{
			"zR",
			function()
				require("ufo").openAllFolds()
			end,
			desc = "Open All Folds",
		},
		{
			"zN",
			function()
				require("ufo").closeAllFolds()
			end,
			desc = "Close All Folds",
		},
		{
			"zK",
			function()
				local winid = require("ufo").peekFoldedLinesUnderCursor()
				if not winid then
					vim.lsp.buf.hover()
				end
			end,
			desc = "Peek Fold",
		},
	},
	opts = {
		provider_selector = function(bufnr, filetype, buftype)
			return { "lsp", "indent" }
		end,
	},
}
