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

function M.setup()
	vim.api.nvim_create_user_command("OmniVision", hello, {})

	vim.api.nvim_create_user_command("OmniVisionReload", reload, {})
end

M.setup()

return M
