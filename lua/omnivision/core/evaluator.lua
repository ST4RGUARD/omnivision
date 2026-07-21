local adapters = require("omnivision.adapters")
local config = require("omnivision.config")

local M = {}

local function get_adapter()
	return adapters.get(config.options.adapter)
end

function M.line()
	local adapter = get_adapter()

	if not adapter then
		return nil
	end

	local ctx = {
		bufnr = vim.api.nvim_get_current_buf(),
		line = vim.api.nvim_win_get_cursor(0)[1] - 1,
	}

	return adapter.evaluate_line(ctx)
end

function M.selection(opts)
	local adapter = get_adapter()

	if not adapter then
		return nil
	end

	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	local ctx = {
		bufnr = vim.api.nvim_get_current_buf(),
		start_line = opts.line1 - 1,
		end_line = opts.line2 - 1,
	}
	return adapter.evaluate_selection(ctx)
end

function M.buffer()
	local adapter = get_adapter()

	if not adapter then
		return nil
	end

	local ctx = {
		bufnr = vim.api.nvim_get_current_buf(),
	}

	return adapter.evaluate_buffer(ctx)
end

return M
