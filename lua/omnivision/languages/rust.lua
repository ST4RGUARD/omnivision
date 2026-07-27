local M = {}

function M.can_handle(filetype)
	return filetype == "rust"
end

function M.extract_contexts(ctx)
	local contexts = {}

	local functions = {}

	local i = 1

	while i <= #ctx.lines do
		local line = ctx.lines[i]

		if line:match("^%s*fn%s+") or line:match("^%s*async%s+fn%s+") then
			local block = {}

			local depth = 0
			local started = false

			while i <= #ctx.lines do
				local current = ctx.lines[i]

				table.insert(block, current)

				for char in current:gmatch("[{}]") do
					if char == "{" then
						depth = depth + 1
						started = true
					elseif char == "}" then
						depth = depth - 1
					end
				end

				if started and depth == 0 then
					break
				end

				i = i + 1
			end

			table.insert(functions, table.concat(block, "\n"))
		end

		i = i + 1
	end

	if #functions == 0 then
		return contexts
	end

	-- Context 1: all functions in the file
	table.insert(contexts, table.concat(functions, "\n\n"))

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

function M.classify(ctx, contexts)
	print("CLASSIFY CODE:")
	print(ctx.code)

	local code = ctx.code:gsub("^%s+", ""):gsub("%s+$", "")

	-- The selection itself is a complete Rust program
	if code:match("fn%s+main%s*%(") then
		return "program"
	end

	-- Selected a function
	if code:match("^fn%s+") or code:match("^async%s+fn%s+") then
		return "function"
	end

	-- Selected a statement
	if code:match("^let%s+") then
		return "statement"
	end

	-- Everything else is an expression.
	-- Contexts are used by the runner to resolve names.
	return "expression"
end

return M
