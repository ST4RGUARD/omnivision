local rust = require("omnivision.languages.rust")

local M = {}

local languages = {
	rust,
}

function M.get(filetype)
	for _, language in ipairs(languages) do
		if language.can_handle(filetype) then
			return language
		end
	end

	return nil
end

return M
