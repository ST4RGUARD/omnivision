local M = {}

local namespace = vim.api.nvim_create_namespace("OmniVision")

function M.show(bufnr, line, text)
	return vim.api.nvim_buf_set_extmark(bufnr, namespace, line, -1, {
		virt_text = {
			{ text, "Comment" },
		},
		virt_text_pos = "eol",
	})
end

function M.clear(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

function M.clear_all()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		M.clear(buf)
	end
end

return M
