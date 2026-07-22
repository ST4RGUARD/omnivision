local config = require("omnivision.config")
local commands = require("omnivision.commands")

local M = {}

function M.setup(opts)
	config.setup(opts)
	commands.setup()
end

function M.hello()
	vim.notify("OmniVision loaded")
end

return M
