local M = {}
local plugin_name = "elixir_dev"

local function build_title(mod)
	if mod._name then
		return string.format("%s [ %s ]", plugin_name, mod._name)
	end

	return plugin_name
end

function M.info(message, mod)
	vim.notify(message, vim.log.levels.INFO, {
		title = build_title(mod),
		icon = mod._icon,
	})
end

function M.warn(message, mod)
	vim.notify(message, vim.log.levels.WARN, {
		title = build_title(mod),
		icon = mod._icon,
	})
end

function M.err(message, mod)
	vim.notify(message, vim.log.levels.ERROR, {
		title = build_title(mod),
		icon = mod._icon,
	})
end

function M.debug(message, mod)
	vim.notify(message, vim.log.levels.DEBUG, {
		title = build_title(mod),
		icon = mod._icon,
	})
end

return M
