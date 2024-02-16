local highlighter = require("vim.treesitter.highlighter")

local Self = {}

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

Self.is_elixir_lang = function(buf)
	local buff_active = highlighter.active[buf]

	return buff_active and buff_active.tree._lang == "elixir" or false
end

Self.get_master_node = function(initial_node)
	local ts_utils = require("nvim-treesitter.ts_utils")

	local node = initial_node or ts_utils.get_node_at_cursor()

	local parent = node:parent()
	local start_row = node:start()

	while parent ~= nil and start_row == parent:start() and parent:type() ~= "body" do
		node = parent
		parent = node:parent()

		if hard_stop_for_inner_pipes(node, buf) then
			parent = nil
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

return Self
