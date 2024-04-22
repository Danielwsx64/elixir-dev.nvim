local treesitter_utils = require("elixir_dev.utils.treesitter")
local ts_utils = require("nvim-treesitter.ts_utils")

local get_node_text = vim.treesitter.get_node_text

local M = {}

local function jump_to(dest, options)
	local full_path = dest.go_to.dir .. dest.go_to.file

	local file_exists = vim.fn.filereadable(full_path) == 1

	if not file_exists then
		local opt = vim.fn.confirm(string.format("Do you want to create %s?", full_path), "&Yes\n&No", 2)

		if opt == 1 then
			vim.fn.mkdir(dest.go_to.dir, "p")
		else
			return false
		end
	end

	local jumped_from = file_exists and M._get_caller_info(dest.expected_caller) or nil

	vim.api.nvim_cmd({ cmd = options.jump_to_test.open_method, args = { full_path } }, {})

	return true, jumped_from
end

local function extrat_info_from_def_call(node, bufnr)
	local fn_node = node:named_child(1):named_child(0)

	if fn_node:type() == "identifier" then
		return {
			type = "function",
			name = get_node_text(fn_node, bufnr),
			arity = 0,
		}
	end

	if fn_node:type() == "binary_operator" then
		fn_node = fn_node:named_child(0)
	end

	return {
		type = "function",
		name = get_node_text(fn_node:named_child(0), bufnr),
		arity = fn_node:named_child(1):named_child_count(),
	}
end

local function extrat_info_from_describe_call(node, bufnr)
	local desc_node = node:named_child(1):named_child(0):named_child(0)
	local desc_txt = get_node_text(desc_node, bufnr)

	local full_function_name = string.match(desc_txt, "[%a_]+/%d+")

	if full_function_name then
		return {
			type = "describe",
			name = string.match(full_function_name, "^[%a_]+"),
			arity = tonumber(string.match(full_function_name, "%d+$")) or 0,
		}
	end

	return nil
end

function M._get_describe_node_by(jumped_from, bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local root = treesitter_utils.get_root(bufnr)

	local query = vim.treesitter.query.parse(
		"elixir",
		[[
    (call
      target: (identifier) @describe_call (#eq? @describe_call "describe")
      (arguments (string) @describe_name)
    )]]
	)

	local full_name = string.format("%s/%s", jumped_from.name, jumped_from.arity)
	local candidate = nil

	for _, node in query:iter_captures(root, bufnr) do
		if node:type() == "string" then
			local describe = get_node_text(node, bufnr)

			if string.match(describe, full_name) then
				return node
			end

			if string.match(describe, jumped_from.name) then
				candidate = node
			end
		end
	end

	return candidate
end

function M._get_def_node_by(jumped_from, bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local root = treesitter_utils.get_root(bufnr)

	local query = vim.treesitter.query.parse(
		"elixir",
		[[
    (call target: (identifier) @call_id (#eq? @call_id "def"))]]
	)

	for _, node in query:iter_captures(root, bufnr) do
		local fn_node = node:next_sibling():named_child(0)

		if fn_node and fn_node:type() == "identifier" and jumped_from.arity == 0 then
			if get_node_text(fn_node, bufnr) == jumped_from.name then
				return fn_node
			end
		end

		if fn_node and fn_node:type() == "binary_operator" then
			fn_node = fn_node:named_child(0)
		end

		if fn_node and fn_node:named_child(0) then
			local name = get_node_text(fn_node:named_child(0), bufnr)
			local arity = fn_node:named_child(1) and fn_node:named_child(1):named_child_count() or 0

			if jumped_from.name == name and jumped_from.arity == arity then
				return fn_node
			end
		end
	end

	return nil
end

function M._directions(head, tail)
	local file_base = string.gsub(string.gsub(tail, ".ex$", ""), "_test.exs$", "")
	local implement_dir = vim.startswith(head, "/") and "/" or ""
	local test_dir = implement_dir

	for word in string.gmatch(head, "[%w_]+") do
		if word == "test" or word == "lib" then
			implement_dir = implement_dir .. "lib/"
			test_dir = test_dir .. "test/"
		else
			implement_dir = implement_dir .. word .. "/"
			test_dir = test_dir .. word .. "/"
		end
	end

	return {
		["exs"] = {
			expected_caller = "describe",
			go_to = {
				dir = implement_dir,
				file = string.format("%s.ex", file_base),
			},
		},
		["ex"] = {
			expected_caller = "def",
			go_to = {
				dir = test_dir,
				file = string.format("%s_test.exs", file_base),
			},
		},
	}
end

function M._get_caller_info(expected_caller, initial_node, bufnr)
	bufnr = bufnr or treesitter_utils.get_current_elixir_buf()

	if not bufnr then
		return nil
	end

	local node = treesitter_utils.get_parent_node({ "call" }, function(n)
		return get_node_text(n:named_child(0), bufnr) == expected_caller
	end, initial_node)

	if node and expected_caller == "def" then
		return extrat_info_from_def_call(node, bufnr)
	end

	if node and expected_caller == "describe" then
		return extrat_info_from_describe_call(node, bufnr)
	end

	return nil
end

function M.call(options)
	local directions = M._directions(vim.fn.expand("%:h"), vim.fn.expand("%:t"))
	local dest = directions[vim.fn.expand("%:e")]

	local jumped, jumped_from = jump_to(dest, options)

	if jumped_from and jumped_from.type == "function" then
		ts_utils.goto_node(M._get_describe_node_by(jumped_from))
	end

	if jumped_from and jumped_from.type == "describe" then
		ts_utils.goto_node(M._get_def_node_by(jumped_from))
	end

	return jumped
end

return M
