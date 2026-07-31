local M = {}

local runners = {
	python = require("omnivision.runners.python"),
	rust = require("omnivision.runners.rust"),
}

local function current()
	local filetype = vim.bo.filetype

	local runner = runners[filetype]

	assert(runner, "No OmniVision runner for filetype: " .. filetype)

	return runner
end

function M.toggle()
	return current().toggle()
end

function M.start()
	return current().start()
end

function M.stop()
	return current().stop()
end

function M.send(request, callback)
	return current().send(request, callback)
end

return M
