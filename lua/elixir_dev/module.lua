local notify = require("elixir_dev.utils.notify")
local treesitter_utils = require("elixir_dev.utils.treesitter")
local ts_utils = require("nvim-treesitter.ts_utils")

local get_node_text = vim.treesitter.get_node_text

local M = {}

local function is_def_node(bufnr, node)
	local target_node = node:field("target")[1]

	return target_node and get_node_text(target_node, bufnr) == "def"
end

function M._get_module_name(bufnr, node)
	local defmodule = treesitter_utils.get_parent_node({ "call" }, function(n)
		return get_node_text(n:field("target")[1], bufnr) == "defmodule"
	end, node)

	return defmodule and vim.treesitter.get_node_text(defmodule:named_child(1), bufnr) or nil
end

function M.format_node_function(node, bufnr)
	bufnr = bufnr or treesitter_utils.get_current_elixir_buf()

	if not is_def_node(bufnr, node) then
		return nil
	end

	local arguments_child_node = node:child(1):child(0)

	if arguments_child_node:child_count() == 0 then
		return get_node_text(arguments_child_node, bufnr) .. "/0"
	end

	local fn_name = get_node_text(arguments_child_node:child(0), bufnr)
	local arity = arguments_child_node:child(1):named_child_count()

	return fn_name .. "/" .. arity
end

function M.get_module_public_function_nodes(bufnr, node)
	bufnr = bufnr or treesitter_utils.get_current_elixir_buf()

	if not bufnr then
		return nil
	end

	node = node or ts_utils.get_node_at_cursor()

	local defmodule = treesitter_utils.get_parent_node({ "call" }, function(n)
		return get_node_text(n:field("target")[1], bufnr) == "defmodule"
	end, node)

	if not defmodule then
		return nil
	end

	local do_block_node = defmodule:child(2)

	return treesitter_utils.get_all_child(function(n)
		return is_def_node(bufnr, n)
	end, do_block_node)
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
