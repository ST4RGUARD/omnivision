local M = {}

local state = require("omnivision.core.state")
local extmarks = require("omnivision.core.extmarks")
local evaluator = require("omnivision.core.evaluator")

local function reload()
	for module, _ in pairs(package.loaded) do
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

local function test_virtual_text()
	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1

	extmarks.show(buf, line, "=> OmniVision works!")
end

local function clear()
	extmarks.clear_all()
	vim.notify("OmniVision cleared")
end

local function test_virtual_text()
	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1

	local id = extmarks.show(buf, line, "=> OmniVision works!")

	state.add({
		bufnr = buf,
		line = line,
		extmark = id,
	})
end

local function undo_last()
	local result = state.last()

	if not result then
		vim.notify("No OmniVision results")
		return
	end

	extmarks.remove(result.bufnr, result.extmark)

	state.remove_last()
end

local function eval_line()
	local result = evaluator.line()

	if not result then
		return
	end

	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1

	local id = extmarks.show(buf, line, result.output)

	state.add({
		bufnr = buf,
		line = line,
		extmark = id,
	})
end

function M.setup()
	vim.api.nvim_create_user_command("OmniVision", hello, {})

	vim.api.nvim_create_user_command("OmniVisionReload", reload, {})

	vim.api.nvim_create_user_command("OmniVisionTest", test_virtual_text, {})

	vim.api.nvim_create_user_command("OmniVisionUndo", undo_last, {})

	vim.api.nvim_create_user_command("OmniVisionClear", clear, {})

	vim.api.nvim_create_user_command("OmniVisionEvalLine", eval_line, {})
end

M.setup()

return M
