local treesitter_utils = require("elixir_dev.utils.treesitter")
local vim_buffer = require("elixir_dev.utils.vim_buffer")

local get_node_text = vim.treesitter.get_node_text

local Self = { _name = "Anonymous Function", _icon = "" }

local args_names = {
	"first",
	"second",
	"third",
	"fourth",
	"fifth",
	"sixth",
	"seventh",
	"eighth",
	"ninth",
	"tenth",
}

local function format_node_txt(txt)
	local chars_add_space = {
		[","] = {},
		["+"] = { both = true },
		["*"] = { both = true },
		["/"] = { both = true },
	}

	if chars_add_space[txt] then
		if chars_add_space[txt].both then
			return " " .. txt .. " "
		end

		return txt .. " "
	end
	return txt
end

local function list_arguments(node, buf)
	local args = {}
	local ordered_args = {}
	local i = 0

	if node then
		for n in node:iter_children() do
			if n:named() then
				i = i + 1
			end

			if n:type() == "identifier" then
				local txt = get_node_text(n, buf)
				args[txt] = "&" .. i
				ordered_args[i] = txt
			end
		end
	end

	return args, ordered_args
end

local function replace_short_arguments(node, buf, previous_args)
	local found_args = previous_args or {}

	if node:type() == "unary_operator" and node:named_child(0):type() == "integer" then
		local value = tonumber(get_node_text(node:named_child(0), buf)) or 0

		found_args[value] = value

		return found_args, args_names[value]
	end

	if node:child_count() == 0 then
		return found_args, format_node_txt(get_node_text(node, buf))
	end

	local txt = ""

	for n in node:iter_children() do
		local _, n_txt = replace_short_arguments(n, buf, found_args)

		txt = txt .. n_txt
	end

	return found_args, txt
end

local function replace_args(node, args, buf)
	local result = ""

	if node:child_count() == 0 then
		local node_txt = get_node_text(node, buf)

		if node:type() == "identifier" and args[node_txt] then
			return args[node_txt]
		end

		return format_node_txt(node_txt)
	end

	for n in node:iter_children() do
		result = result .. replace_args(n, args, buf)
	end

	return result
end

local function rebuild_args_list(args, body)
	local args_txt = ""

	for i, _ in pairs(args) do
		if i > 1 then
			args_txt = args_txt .. ", "
		end
		args_txt = args_txt .. args_names[i]
	end

	return args_txt
end

local function rebuild_anonymous_fn(args, body)
	return string.format("fn %s -> %s end", rebuild_args_list(args), body)
end

local function rebuild_call_arguments(node, buf)
	local args = {}

	local arity = tonumber(get_node_text(node:named_child(1), buf)) or 0

	for i = 1, arity, 1 do
		args[i] = i
	end

	return args, string.format("%s(%s)", get_node_text(node:named_child(0), buf), rebuild_args_list(args))
end

local function try_shorthand_arity(node, buf, args)
	if node:type() ~= "call" then
		return nil
	end

	local args_node = node:named_child(1)

	if args_node:named_child_count() ~= #args then
		return nil
	end

	for i, v in ipairs(args) do
		local arg_node = args_node:named_child(i - 1)

		if arg_node:type() ~= "identifier" then
			return nil
		end

		if get_node_text(arg_node, buf) ~= v then
			return nil
		end
	end

	return string.format("&%s/%s", get_node_text(node:named_child(0), buf), #args)
end

Self._to_fn_shorthand = function(node, buf)
	local arg_node = node:named_child(0):field("left")
	local body_node = node:named_child(0):field("right")

	local args, ordered_args = list_arguments(arg_node[1], buf)

	local shorthand_and_arity = try_shorthand_arity(body_node[1]:named_child(0), buf, ordered_args)

	if shorthand_and_arity then
		return shorthand_and_arity
	end

	return string.format("&(%s)", replace_args(body_node[1], args, buf))
end

Self._to_anonymous_fn = function(node, buf)
	local args, txt
	local possible_types = { ["call"] = true, ["identifier"] = true }
	local operand = node:named_child(0)

	if
		operand:type() == "binary_operator"
		and possible_types[operand:named_child(0):type()]
		and operand:named_child(1):type() == "integer"
	then
		args, txt = rebuild_call_arguments(operand, buf)
	else
		args, txt = replace_short_arguments(operand, buf)
	end

	return rebuild_anonymous_fn(args, txt)
end

Self.call = function()
	local buf = treesitter_utils.get_current_elixir_buf()

	if not buf then
		return false
	end

	local node = treesitter_utils.get_parent_node({ "anonymous_function", "unary_operator" })

	if not node then
		return false
	end

	local start_row, start_col, end_row, end_col = node:range()

	if node and node:type() == "anonymous_function" then
		local replacement = Self._to_fn_shorthand(node, buf)

		vim_buffer.replace_content(buf, start_row, start_col, end_row, end_col, { replacement })
		return true
	end

	if node and node:type() == "unary_operator" then
		local replacement = Self._to_anonymous_fn(node, buf)

		vim_buffer.replace_content(buf, start_row, start_col, end_row, end_col, { replacement })
		return true
	end
end

return Self
