local M = {}

local function find_function_start(lines, cursor_line)
	local cursor_index = cursor_line + 1

	for i = cursor_index, 1, -1 do
		local line = lines[i]

		if line:match("^%s*fn%s+") or line:match("^%s*async%s+fn%s+") then
			return i
		end
	end

	return nil
end

local function extract_function_context(ctx)
	local fn_start = find_function_start(ctx.lines, ctx.cursor_line)

	if not fn_start then
		return nil
	end

	local context = {}

	for i = fn_start + 1, ctx.cursor_line do
		table.insert(context, ctx.lines[i])
	end

	return table.concat(context, "\n")
end

function M.can_handle(filetype)
	return filetype == "rust"
end

function M.extract_context(ctx)
	return extract_function_context(ctx)
end

return M
