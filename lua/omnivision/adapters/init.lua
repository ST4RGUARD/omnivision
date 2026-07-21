local M = {}

local adapters = {
	rust = require("omnivision.adapters.rust"),
}

function M.get(name)
	return adapters[name]
end

function M.register(name, adapter)
	adapters[name] = adapter
end

return M
