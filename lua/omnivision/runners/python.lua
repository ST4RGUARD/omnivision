local M = {}

local job = nil
local queue = require("omnivision.core.queue")

local function runner_path()
	local source = debug.getinfo(1, "S").source

	source = source:sub(2)

	local plugin_root = source:match("(.+)/lua/omnivision/runners")

	return plugin_root .. "/lua/omnivision/runners/python"
end

function M.start()
	if job then
		return
	end

	local runner = runner_path()

	vim.notify("Starting Python runner: " .. runner)

	job = vim.fn.jobstart({
		"uv",
		"run",
		"python",
		"main.py",
	}, {
		cwd = runner,

		stdout_buffered = false,

		on_stdout = function(_, data)
			if not data then
				return
			end

			for _, line in ipairs(data) do
				if line ~= "" then
					local ok, response = pcall(vim.json.decode, line)

					if not ok then
						vim.notify("Invalid Python runner response: " .. line, vim.log.levels.ERROR)
						goto continue
					end

					queue.resolve(response.id, response)

					::continue::
				end
			end
		end,

		on_stderr = function(_, data)
			if not data then
				return
			end

			for _, line in ipairs(data) do
				if line ~= "" then
					vim.notify("python runner: " .. line, vim.log.levels.INFO)
				end
			end
		end,

		on_exit = function()
			job = nil
			queue.clear()
		end,
	})

	if job <= 0 then
		job = nil
		error("Failed to start Python runner")
	end

	vim.notify("OmniVision Python runner started")
end

function M.stop()
	if job then
		vim.fn.jobstop(job)
		job = nil
	end

	queue.clear()
end

function M.is_running()
	return job ~= nil
end

function M.toggle()
	if M.is_running() then
		M.stop()
		vim.notify("OmniVision Python runner stopped")
	else
		M.start()
	end
end

function M.status()
	return {
		running = job ~= nil,
		job = job,
	}
end

function M.send(payload, cb)
	if not job then
		M.start()
	end

	local id = queue.create(payload.bufnr, cb)

	payload.id = id

	local json = vim.json.encode(payload)

	vim.notify("OmniVision Python request " .. payload.id, vim.log.levels.DEBUG)

	vim.fn.chansend(job, json .. "\n")
end

return M
