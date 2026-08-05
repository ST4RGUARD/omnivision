local runner = require("omnivision.runners.python")

local M = {}

function M.evaluate(ctx, callback)
	local request = ctx.language.build_request(ctx)

	runner.send(request, function(response)
		callback({
			success = response.success,
			observations = response.observations,
			error = response.error,
		})
	end)
end

return M
