local runner = require("omnivision.runners.rust")

local M = {}

function M.evaluate_line(ctx)
	local line = vim.api.nvim_buf_get_lines(ctx.bufnr, ctx.line, ctx.line + 1, false)[1]

	return runner.evaluate(line)
end

function M.evaluate_selection(ctx)
	local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, ctx.start_line, ctx.end_line + 1, false)

	local code = table.concat(lines, "\n")

	return runner.evaluate(code)
end

function M.evaluate_buffer(ctx)
	local lines = vim.api.nvim_buf_get_lines(ctx.bufnr, 0, -1, false)

	local code = table.concat(lines, "\n")

	return runner.evaluate(code)
end

return M
