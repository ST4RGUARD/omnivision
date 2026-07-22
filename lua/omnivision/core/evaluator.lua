local adapters = require("omnivision.adapters")
local config = require("omnivision.config")

local M = {}

function M.evaluate(ctx)
	local adapter = adapters.get(config.options.adapter)

	if not adapter then
		return nil
	end

	return adapter.evaluate(ctx)
end

return M
