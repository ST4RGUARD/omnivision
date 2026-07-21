local M = {}

M.defaults = {
	enabled = true,

	virtual_text = true,

	adapter = "rust",

	runner = {
		timeout = 1000,
	},
}

M.options = {}

function M.setup(opts)
	M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
