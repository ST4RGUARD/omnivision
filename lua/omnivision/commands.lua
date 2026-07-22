local M = {}

local evaluator = require("omnivision.core.evaluator")
local renderer = require("omnivision.core.renderer")

local function reload()
	for module in pairs(package.loaded) do
		if module:match("^omnivision") then
			package.loaded[module] = nil
		end
	end

	require("omnivision").setup()

	vim.notify("OmniVision reloaded")
end

local function hello()
	require("omnivision").hello()
end

local function clear()
	renderer.clear()

	vim.notify("OmniVision cleared")
end

local function clear_buffer()
	local buf = vim.api.nvim_get_current_buf()

	renderer.clear_buffer(buf)

	vim.notify("OmniVision buffer cleared")
end

local function undo_last()
	if not renderer.undo_last() then
		vim.notify("No OmniVision results")
	end
end

local function test_virtual_text()
	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1

	renderer.render(buf, line, "=> OmniVision works!")
end

local function eval_line()
	local buf = vim.api.nvim_get_current_buf()

	evaluator.evaluate({
		mode = "line",
	}, function(result)
		if not result or not result.success then
			vim.notify("OmniVision evaluation failed", vim.log.levels.ERROR)

			return
		end

		renderer.render_result(buf, result)
	end)
end

local function eval_selection(opts)
	local buf = vim.api.nvim_get_current_buf()

	evaluator.evaluate({
		mode = "selection",
		start_line = opts.line1 - 1,
		end_line = opts.line2 - 1,
	}, function(result)
		if not result or not result.success then
			vim.notify("OmniVision evaluation failed", vim.log.levels.ERROR)

			return
		end

		renderer.render_result(buf, result)
	end)
end

local function eval_buffer()
	local buf = vim.api.nvim_get_current_buf()

	evaluator.evaluate({
		mode = "buffer",
	}, function(result)
		if not result or not result.success then
			vim.notify("OmniVision evaluation failed", vim.log.levels.ERROR)

			return
		end

		renderer.render_result(buf, result)
	end)
end

function M.setup()
	vim.api.nvim_create_user_command("OmniVision", hello, {})

	vim.api.nvim_create_user_command("OmniVisionReload", reload, {})

	vim.api.nvim_create_user_command("OmniVisionTest", test_virtual_text, {})

	vim.api.nvim_create_user_command("OmniVisionUndo", undo_last, {})

	vim.api.nvim_create_user_command("OmniVisionClear", clear, {})

	vim.api.nvim_create_user_command("OmniVisionClearBuffer", clear_buffer, {})

	vim.api.nvim_create_user_command("OmniVisionEvalLine", eval_line, {})

	vim.api.nvim_create_user_command("OmniVisionEvalSelection", eval_selection, {
		range = true,
	})

	vim.api.nvim_create_user_command("OmniVisionEvalBuffer", eval_buffer, {})
end

return M
