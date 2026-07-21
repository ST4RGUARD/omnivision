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

function M.remove(bufnr, id)
	vim.api.nvim_buf_del_extmark(bufnr, namespace, id)
end

function M.clear_all()
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		M.clear_buffer(buf)
	end
end

function M.clear_buffer(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
end

return M
