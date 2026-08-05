local M = {}

local function find_block_start(lines, cursor_line)
	local index = cursor_line + 1

	for i = index, 1, -1 do
		local line = lines[i]

		if line:match("^%s*def%s+") or line:match("^%s*class%s+") then
			return i
		end
	end

	return nil
end

local function extract_block(lines, start)
	local block = {}

	local base_indent = nil

	for i = start, #lines do
		local line = lines[i]

		if i == start then
			table.insert(block, line)
			base_indent = #line:match("^%s*")
		else
			local indent = #line:match("^%s*")

			if line:match("%S") and indent <= base_indent then
				break
			end

			table.insert(block, line)
		end
	end

	return block
end

local function is_top_level(line)
	return line:match("^%S") ~= nil
end

function M.can_handle(filetype)
	return filetype == "python"
end

function M.extract_contexts(ctx)
	local contexts = {}

	local lines = ctx.lines

	local block_start = find_block_start(lines, ctx.cursor_line)

	if block_start then
		local block = extract_block(lines, block_start)

		table.insert(contexts, table.concat(block, "\n"))
	end

	local top_level = {}

	local i = 1

	while i <= ctx.cursor_line + 1 do
		local line = lines[i]

		if line:match("^%s*import%s+") or line:match("^%s*from%s+") then
			table.insert(top_level, line)
		elseif line:match("^%s*def%s+") or line:match("^%s*class%s+") then
			local block = extract_block(lines, i)

			for _, block_line in ipairs(block) do
				table.insert(top_level, block_line)
			end

			i = i + #block - 1
		elseif is_top_level(line) and line:match("%S") and not line:match("^%s*return%s+") then
			table.insert(top_level, line)
		end

		i = i + 1
	end

	if #top_level > 0 then
		table.insert(contexts, table.concat(top_level, "\n"))
	end

	print("PYTHON CONTEXTS:")

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

function M.classify(ctx, contexts)
	print("CLASSIFY PYTHON:")
	print(ctx.code)

	if ctx.mode == "buffer" then
		return "program"
	end

	local code = ctx.code:gsub("^%s+", ""):gsub("%s+$", "")

	if code:match("^import%s+") or code:match("^from%s+") or code:match("class%s+") then
		if code:match("\n") then
			return "program"
		end
	end

	if code:match("^def%s+") then
		return "function"
	end

	if code:match("^class%s+") then
		return "program"
	end

	if code:match("^return%s+") then
		return "return"
	end

	if code:match("^import%s+") or code:match("^from%s+") then
		return "statement"
	end

	if code:match("=") then
		return "statement"
	end

	return "expression"
end

function M.build_request(ctx)
	local contexts = M.extract_contexts(ctx)

	return {
		bufnr = ctx.bufnr,

		language = ctx.filetype or "python",
		mode = ctx.mode,

		code = ctx.code or "",

		kind = M.classify(ctx, contexts),

		contexts = contexts,

		start_line = ctx.start_line,
		end_line = ctx.end_line,
		cursor_line = ctx.cursor_line,

		filename = ctx.filename,
	}
end

return M
