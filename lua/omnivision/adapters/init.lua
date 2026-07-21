local M = {}

local adapters = {
	fake = require("omnivision.adapters.fake"),
}

function M.get(name)
	return adapters[name]
end

function M.register(name, adapter)
	adapters[name] = adapter
end

return M
