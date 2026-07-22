local extmarks = require("omnivision.core.extmarks")
local state = require("omnivision.core.state")

local M = {}

function M.render(bufnr, line, output)
	local id = extmarks.show(bufnr, line, output)

	state.add({
		bufnr = bufnr,
		line = line,
		extmark = id,
	})

	return id
end

function M.render_result(bufnr, result)
	if not result or not result.success then
		return
	end

	for _, observation in ipairs(result.observations or {}) do
		M.render(bufnr, observation.line, observation.output)
	end
end

function M.undo_last()
	local result = state.last()

	if not result then
		return false
	end

	extmarks.remove(result.bufnr, result.extmark)

	state.remove_last()

	return true
end

function M.clear_buffer(bufnr)
	extmarks.clear_buffer(bufnr)
	state.remove_buffer(bufnr)
end

function M.clear()
	extmarks.clear_all()
	state.clear()
end

return M
