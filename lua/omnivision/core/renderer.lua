local extmarks = require("omnivision.core.extmarks")
local state = require("omnivision.core.state")

local M = {}

function M.render(bufnr, line, output, kind)
	local highlight = "Comment"

	if kind == "error" then
		highlight = "ErrorMsg"
	elseif kind == "value" then
		highlight = "String"
	elseif kind == "type" then
		highlight = "Type"
	end

	local id = extmarks.show(bufnr, line, output, highlight)

	state.add({
		bufnr = bufnr,
		line = line,
		kind = kind or "info",
		extmark = id,
	})

	return id
end

function M.render_result(bufnr, result)
	if not result or not result.success then
		return
	end

	for _, observation in ipairs(result.observations or {}) do
		M.render(bufnr, observation.line, observation.text, observation.kind)
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
