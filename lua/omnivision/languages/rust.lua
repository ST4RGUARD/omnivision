local M = {}

function M.can_handle(filetype)
	return filetype == "rust"
end

local function find_function(lines, cursor_line)
	local start_line = nil
	local depth = 0
	local started = false

	for i = 1, #lines do
		local line = lines[i]

		if not start_line then
			if line:match("^%s*fn%s+") or line:match("^%s*async%s+fn%s+") then
				start_line = i
				depth = 0
				started = false
			end
		end

		if start_line then
			for c in line:gmatch("[{}]") do
				if c == "{" then
					depth = depth + 1
					started = true
				elseif c == "}" then
					depth = depth - 1
				end
			end

			if started and depth == 0 then
				local end_line = i

				if cursor_line + 1 >= start_line and cursor_line + 1 <= end_line then
					local block = {}

					for j = start_line, end_line do
						table.insert(block, lines[j])
					end

					return table.concat(block, "\n")
				end

				start_line = nil
			end
		end
	end

	return nil
end

function M.extract_contexts(ctx)
	local contexts = {}

	local imports = {}

	for _, line in ipairs(ctx.lines) do
		if line:match("^%s*use%s+") then
			table.insert(imports, line)
		end
	end

	if #imports > 0 then
		table.insert(contexts, table.concat(imports, "\n"))
	end

	local function_block = find_function(ctx.lines, ctx.cursor_line)

	if function_block then
		table.insert(contexts, function_block)
	end

	print("RUST CONTEXTS:")

	for i, context in ipairs(contexts) do
		print("CONTEXT " .. i)
		print(context)
	end

	return contexts
end

function M.extract_context(ctx)
	local contexts = M.extract_contexts(ctx)
	return contexts[1]
end

function M.classify(ctx)
	print("CLASSIFY CODE:")
	print(ctx.code)

	local code = ctx.code:gsub("^%s+", ""):gsub("%s+$", "")

	if code:match("fn%s+main%s*%(") then
		return "program"
	end

	if code:match("^fn%s+") or code:match("^async%s+fn%s+") then
		return "function"
	end

	if code:match("^let%s+") then
		return "statement"
	end

	return "expression"
end

function M.build_request(ctx)
	local contexts = M.extract_contexts(ctx)

	return {
		bufnr = ctx.bufnr,

		language = ctx.filetype or "rust",
		mode = ctx.mode,

		code = ctx.code or "",

		kind = M.classify(ctx),

		contexts = contexts,

		start_line = ctx.start_line,
		end_line = ctx.end_line,
		cursor_line = ctx.cursor_line,

		filename = ctx.filename,
	}
end

return M
