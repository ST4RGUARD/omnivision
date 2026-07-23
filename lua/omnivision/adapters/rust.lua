local runner = require("omnivision.runners.rust")

local M = {}

function M.evaluate(ctx, callback)
	local extracted_context = ""

	if ctx.language then
		extracted_context = ctx.language.extract_context(ctx) or ""
	end

	runner.send({
		bufnr = ctx.bufnr,

		language = ctx.filetype or "rust",
		mode = ctx.mode,

		code = ctx.code or "",

		context = extracted_context,

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
