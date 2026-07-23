local runner = require("omnivision.runners.rust")

local M = {}

function M.evaluate(ctx, callback)
	runner.send({
		bufnr = ctx.bufnr,
		language = ctx.filetype or "rust",
		mode = ctx.mode,

		code = ctx.code or "",

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
