local runner = require("omnivision.runners.rust")

local M = {}

function M.evaluate(ctx, callback)
	local code = ""

	if ctx.mode == "line" then
		code = ctx.lines[ctx.cursor_line + 1]
	elseif ctx.mode == "selection" then
		local selected = {}

		for i = ctx.start_line + 1, ctx.end_line + 1 do
			table.insert(selected, ctx.lines[i])
		end

		code = table.concat(selected, "\n")
	elseif ctx.mode == "buffer" then
		code = table.concat(ctx.lines, "\n")
	end

	runner.send({
		language = "rust",
		mode = ctx.mode,
		code = code,

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
