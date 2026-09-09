local M = {}

function M.can_handle(filetype)
	return filetype == "rust"
end

local function is_function_start(line)
	return line:match("^%s*fn%s+")
		or line:match("^%s*pub%s+fn%s+")
		or line:match("^%s*async%s+fn%s+")
		or line:match("^%s*pub%s+async%s+fn%s+")
end

local function find_function(lines, cursor_line)
	local start_line = nil
	local depth = 0
	local started = false

	for i = 1, #lines do
		local line = lines[i]

		if not start_line and is_function_start(line) then
			start_line = i
			depth = 0
			started = false
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
					return start_line, end_line
				end

				start_line = nil
				depth = 0
				started = false
			end
		end
	end

	return nil, nil
end

local function extract_imports(lines)
	local imports = {}

	for _, line in ipairs(lines) do
		if line:match("^%s*use%s+") then
			table.insert(imports, line)
		end
	end

	return imports
end

local function extract_functions(lines)
	local functions = {}

	local start_line = nil
	local depth = 0
	local started = false
	local name = nil

	for i = 1, #lines do
		local line = lines[i]

		if not start_line and is_function_start(line) then
			start_line = i
			depth = 0
			started = false

			local rest = line:gsub("^%s*", "")

			rest = rest:gsub("^pub%s+", "")
			rest = rest:gsub("^async%s+", "")

			name = rest:match("^fn%s+([%w_]+)")
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
				if name then
					functions[name] = {
						start_line = start_line,
						end_line = i,
						lines = {},
					}

					for j = start_line, i do
						table.insert(functions[name].lines, lines[j])
					end
				end

				start_line = nil
				depth = 0
				started = false
				name = nil
			end
		end
	end

	return functions
end

local function extract_function_calls(lines)
	local calls = {}

	for _, line in ipairs(lines) do
		local code = line:gsub("//.*$", "")

		for name in code:gmatch("([%a_][%w_]*)%s*%(") do
			if
				name ~= "if"
				and name ~= "for"
				and name ~= "while"
				and name ~= "match"
				and name ~= "loop"
				and name ~= "println"
				and name ~= "print"
				and name ~= "format"
				and name ~= "Some"
				and name ~= "None"
			then
				calls[name] = true
			end
		end
	end

	return calls
end

local function collect_function_dependencies(functions, lines, visited)
	local dependencies = {}

	visited = visited or {}

	local calls = extract_function_calls(lines)

	for name in pairs(calls) do
		local function_info = functions[name]

		if function_info and not visited[name] then
			visited[name] = true

			local nested = collect_function_dependencies(functions, function_info.lines, visited)

			for _, dependency in ipairs(nested) do
				table.insert(dependencies, dependency)
			end

			table.insert(dependencies, {
				name = name,
				start_line = function_info.start_line,
				lines = function_info.lines,
			})
		end
	end

	return dependencies
end

local function extract_scoped_context(ctx, start_line, functions)
	local context = {}

	local stop_line = ctx.cursor_line

	if ctx.mode == "selection" then
		stop_line = ctx.start_line
	end

	local scoped_lines = {}

	for i = start_line + 1, stop_line do
		local line = ctx.lines[i]

		if line then
			local trimmed = line:gsub("^%s+", "")

			if
				trimmed:match("^let%s+")
				or trimmed:match("^const%s+")
				or trimmed:match("^static%s+")
				or trimmed:match("^use%s+")
				or trimmed:match("^%w+%s*=")
			then
				table.insert(context, line)
				table.insert(scoped_lines, line)
			end
		end
	end

	local dependencies = collect_function_dependencies(functions, scoped_lines)

	table.sort(dependencies, function(a, b)
		return a.start_line < b.start_line
	end)

	local dependency_lines = {}

	for _, dependency in ipairs(dependencies) do
		for _, line in ipairs(dependency.lines) do
			table.insert(dependency_lines, line)
		end
	end

	local combined = {}

	for _, line in ipairs(dependency_lines) do
		table.insert(combined, line)
	end

	for _, line in ipairs(context) do
		table.insert(combined, line)
	end

	return combined
end

function M.extract_contexts(ctx)
	local contexts = {}

	local imports = extract_imports(ctx.lines)
	local functions = extract_functions(ctx.lines)

	local start_line, end_line = find_function(ctx.lines, ctx.cursor_line)

	if start_line and end_line then
		local scoped = extract_scoped_context(ctx, start_line, functions)

		local combined = {}

		for _, line in ipairs(imports) do
			table.insert(combined, line)
		end

		for _, line in ipairs(scoped) do
			table.insert(combined, line)
		end

		if #combined > 0 then
			table.insert(contexts, table.concat(combined, "\n"))
		end
	elseif #imports > 0 then
		table.insert(contexts, table.concat(imports, "\n"))
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

	if
		code:match("^fn%s+")
		or code:match("^pub%s+fn%s+")
		or code:match("^async%s+fn%s+")
		or code:match("^pub%s+async%s+fn%s+")
	then
		return "function"
	end

	if code:match("^let%s+") or code:match("^const%s+") or code:match("^static%s+") then
		return "statement"
	end

	if code:match("^println!") or code:match("^dbg!") or code:match("^%w+%s*%(") or code:match("^%w+%.%w+%(") then
		return "statement"
	end

	if code:match("^%w+%s*=") or code:match("^%w+%s*[+%-*/]=") then
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
