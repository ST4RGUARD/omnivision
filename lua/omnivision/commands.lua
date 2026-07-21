local M = {}

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

local extmarks = require("omnivision.core.extmarks")

local function test_virtual_text()
	local buf = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1

	extmarks.show(buf, line, "=> OmniVision works!")
end

local function clear()
	extmarks.clear_all()
	vim.notify("OmniVision cleared")
end

function M.setup()
	vim.api.nvim_create_user_command("OmniVision", hello, {})

	vim.api.nvim_create_user_command("OmniVisionReload", reload, {})

	vim.api.nvim_create_user_command("OmniVisionTest", test_virtual_text, {})

	vim.api.nvim_create_user_command("OmniVisionClear", clear, {})
end

M.setup()

return M
