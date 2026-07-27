local runner = require("omnivision.runners.rust")

local M = {}

function M.evaluate(ctx, callback)
	local contexts = {}

	if ctx.language and ctx.language.extract_contexts then
		contexts = ctx.language.extract_contexts(ctx)

		print("RUST CONTEXTS:")
		for i, c in ipairs(contexts) do
			print("CONTEXT " .. i)
			print(c)
		end
	end

	if #contexts == 0 then
		contexts = { "" }
	end

	runner.send({
		bufnr = ctx.bufnr,

		language = ctx.filetype or "rust",
		mode = ctx.mode,

		code = ctx.code or "",

		kind = ctx.language and ctx.language.classify(ctx, contexts) or "expression",

		contexts = contexts,

		start_line = ctx.start_line,
		end_line = ctx.end_line,
		cursor_line = ctx.cursor_line,

		filename = ctx.filename,
	}, function(response)
		callback({
			success = response.success,
			observations = response.observations,
			error = response.error,
		})
	end)
end

return M
