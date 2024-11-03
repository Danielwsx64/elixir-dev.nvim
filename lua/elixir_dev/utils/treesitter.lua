local highlighter = require("vim.treesitter.highlighter")
local notify = require("elixir_dev.utils.notify")

local M = {}

local types_to_jump_to_parent = { ["map_content"] = true, ["pair"] = true }
local types_to_update_start_limit = { ["binary_operator"] = true, ["map"] = true, ["keywords"] = true }

local function typ_of(node)
	return node and node:type()
end

local function is_inside_map(node)
	local parent = node:parent()

	return typ_of(parent) == "pair"
		or (typ_of(parent) == "binary_operator" and typ_of(parent:parent()) == "map_content")
end

local function is_pipe_operator(node)
	return node:type() == "binary_operator" and typ_of(node:named_child(1)) == "call"
end

local function hard_stop_for_inner_pipes(node)
	if is_inside_map(node) then
		return typ_of(node) == "call" or is_pipe_operator(node)
	end

	return false
end

function M.is_ts_elixir_parser_enabled(bufnr)
	local buff_active = highlighter.active[bufnr]

	return buff_active and buff_active.tree._lang == "elixir" or false
end

function M.get_master_node(initial_node)
	local ts_utils = require("nvim-treesitter.ts_utils")

	local node = initial_node or ts_utils.get_node_at_cursor()

	local parent = node:parent()
	local start_row = node:start()

	while parent ~= nil and start_row == parent:start() and parent:type() ~= "body" do
		node = parent
		parent = node:parent()

		if hard_stop_for_inner_pipes(node) then
			return node
		end

		if parent and types_to_jump_to_parent[parent:type()] then
			node = parent
			parent = node:parent()
		end

		if parent and types_to_update_start_limit[parent:type()] then
			start_row = parent:start()
		end
	end

	return node
end

function M.get_parent_node(types, validation, initial_node)
	local ts_utils = require("nvim-treesitter.ts_utils")

	if not validation or type(validation) ~= "function" then
		validation = function(_)
			return true
		end
	end

	local node = initial_node or ts_utils.get_node_at_cursor()

	while node do
		if vim.tbl_contains(types, node:type()) and validation(node) then
			return node
		end

		node = node:parent()
	end

	return node
end

function M.get_all_child(validation, initial_node)
	local node = initial_node or ts_utils.get_node_at_cursor()

	if not validation or type(validation) ~= "function" then
		validation = function(_)
			return true
		end
	end

	local results = {}

	for child in node:iter_children() do
		if validation(child) then
			table.insert(results, child)
		end
	end

	return results
end

function M.get_current_elixir_buf()
	local bufnr = vim.api.nvim_get_current_buf()

	if not M.is_ts_elixir_parser_enabled(bufnr) then
		notify.warn("Current buffer has no Elixir TreeSitter Parser enabled", M)

		return nil
	end

	return bufnr
end

function M.get_root(bufnr)
	local parser = vim.treesitter.get_parser(bufnr, "elixir")
	local tree = parser:parse()[1]
	return tree:root()
end

return M
