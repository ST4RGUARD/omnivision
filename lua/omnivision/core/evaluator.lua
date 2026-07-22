local adapters = require("omnivision.adapters")
local config = require("omnivision.config")

local M = {}

local function build_context(ctx)
	local buf = vim.api.nvim_get_current_buf()

	ctx.bufnr = buf

	ctx.filename = vim.api.nvim_buf_get_name(buf)

	ctx.filetype = vim.bo[buf].filetype

	ctx.cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1

	ctx.start_line = ctx.start_line or 0

	ctx.end_line = ctx.end_line or vim.api.nvim_buf_line_count(buf) - 1

	ctx.lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	-- Build code payload based on evaluation mode
	if ctx.mode == "line" then
		ctx.code = ctx.lines[ctx.cursor_line + 1] or ""
	elseif ctx.mode == "selection" then
		local selected = {}

		for i = ctx.start_line + 1, ctx.end_line + 1 do
			table.insert(selected, ctx.lines[i])
		end

		ctx.code = table.concat(selected, "\n")
	elseif ctx.mode == "buffer" then
		ctx.code = table.concat(ctx.lines, "\n")
	end

	return ctx
end

function M.evaluate(ctx, callback)
	ctx = build_context(ctx)

	local adapter = adapters.get(config.options.adapter)

	if not adapter then
		vim.notify("No OmniVision adapter: " .. tostring(config.options.adapter))

		return
	end

	adapter.evaluate(ctx, callback)
end

return M
