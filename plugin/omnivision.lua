if vim.g.loaded_omnivision then
	return
end

vim.g.loaded_omnivision = true

vim.api.nvim_create_user_command("OmniVision", function()
	require("omnivision").hello()
end, {})

vim.api.nvim_create_user_command("OmniVisionReload", function()
	for module, _ in pairs(package.loaded) do
		if module:match("^omnivision") then
			package.loaded[module] = nil
		end
	end

	require("omnivision").setup()

	vim.notify("OmniVision reloaded")
end, {})
