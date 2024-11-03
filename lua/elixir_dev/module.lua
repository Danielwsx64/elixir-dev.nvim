local notify = require("elixir_dev.utils.notify")
local treesitter_utils = require("elixir_dev.utils.treesitter")

local get_node_text = vim.treesitter.get_node_text

local M = {}

function M._get_module_name(bufnr, node)
	local defmodule = treesitter_utils.get_parent_node({ "call" }, function(n)
		return get_node_text(n:field("target")[1], bufnr) == "defmodule"
	end, node)

	return defmodule and vim.treesitter.get_node_text(defmodule:named_child(1), bufnr) or nil
end

function M.yank_module_name()
	local bufnr = treesitter_utils.get_current_elixir_buf()

	if not bufnr then
		return false
	end

	local module_name = M._get_module_name(bufnr)

	if module_name then
		vim.fn.setreg("+", module_name)
		notify.info(module_name .. " Yanked!", M)
	else
		notify.warn("Current buffer has no defmodule", M)
	end
end

return M
