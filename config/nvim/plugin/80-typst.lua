vim.pack.add({ "https://github.com/chomosuke/typst-preview.nvim" })
local typstP = require("typst-preview")
typstP.setup({
	dependencies_bin = {
		tinymist = "tinymist",
		websocat = "websocat",
	},
})
