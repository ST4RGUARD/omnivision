local config = require("omnivision.config")

local M = {}

function M.setup(opts)
	config.setup(opts)
end

function M.hello()
	vim.notify("OmniVision loaded")
end

return M
