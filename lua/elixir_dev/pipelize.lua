local string_utils = require("elixir_dev.utils.string")
local treesitter_utils = require("elixir_dev.utils.treesitter")
local vim_buffer = require("elixir_dev.utils.vim_buffer")

local get_node_text = vim.treesitter.get_node_text

local elixir_keywords_regex = vim.regex(
	"^def\\|defdelegate\\|defexception\\|defguard\\|defguardp\\|defimpl\\|defmacro"
		.. "\\|defmacrop\\|defmodule\\|defn\\|defnp\\|defoverridable\\|defp\\|defprotocol\\|defstruct$"
)

local M = {}

local function rewrite_function_without_first_arg(node, buf, arguments, args_count, do_block)
	local last_child_index = args_count - 1
	local rewrote_fn = get_node_text(node:field("target")[1], buf)

	if last_child_index > 0 or not do_block then
		rewrote_fn = rewrote_fn .. "("
	end

	for child_index = 1, last_child_index do
		rewrote_fn = rewrote_fn .. get_node_text(arguments:named_child(child_index), buf)

		if child_index ~= last_child_index then
			rewrote_fn = rewrote_fn .. ", "
		end
	end

	if last_child_index > 0 or not do_block then
		rewrote_fn = rewrote_fn .. ")"
	end

	if do_block then
		rewrote_fn = rewrote_fn .. " " .. get_node_text(do_block, buf)
	end

	return rewrote_fn
end

function M._to_pipe(node, buf)
	if node:type() == "call" then
		local arguments = node:child(1)
		local do_block = node:child(2)
		local arguments_count = arguments and arguments:named_child_count() or 0

		if arguments_count == 0 then
			return get_node_text(node, buf)
		end

		return M._to_pipe(arguments:named_child(0), buf)
			.. "\n|> "
			.. rewrite_function_without_first_arg(node, buf, arguments, arguments_count, do_block)
	end

	if node:type() == "binary_operator" then
		local operator = get_node_text(node:field("operator")[1], buf)

		local right = node:field("right")[1]
		local left_string = get_node_text(node:field("left")[1], buf)

		return left_string .. " " .. operator .. " " .. M._to_pipe(right, buf)
	end

	return get_node_text(node, buf)
end

function M._undo_pipe(node, buf)
	if node:type() ~= "binary_operator" then
		return get_node_text(node, buf)
	end

	local operator = get_node_text(node:field("operator")[1], buf)
	local left = node:field("left")[1]
	local right = node:field("right")[1]

	if operator == "=" then
		local left_string = get_node_text(left, buf)
		return left_string .. " " .. operator .. " " .. M._undo_pipe(right, buf)
	end

	if right:type() == "call" then
		local arguments, do_block

		local child_one = right:child(1)
		local child_two = right:child(2)

		if child_one:type() == "arguments" then
			arguments = child_one
			do_block = child_two
		else
			arguments = nil
			do_block = child_one
		end

		local rewrote_fn = get_node_text(right:field("target")[1], buf)

		if do_block and not arguments then
			rewrote_fn = rewrote_fn .. " "
		else
			rewrote_fn = rewrote_fn .. "("
		end

		rewrote_fn = rewrote_fn .. M._undo_pipe(left, buf)

		if arguments then
			local arguments_count = arguments:named_child_count() - 1

			for child_index = 0, arguments_count do
				rewrote_fn = rewrote_fn .. ", " .. get_node_text(arguments:named_child(child_index), buf)
			end
		end

		if do_block and not arguments then
			rewrote_fn = rewrote_fn .. ""
		else
			rewrote_fn = rewrote_fn .. ")"
		end

		if do_block then
			rewrote_fn = rewrote_fn .. " " .. get_node_text(do_block, buf)
		end

		return rewrote_fn
	end
end

function M._is_pipe(node, buf)
	if node:type() ~= "binary_operator" then
		return false
	end

	local operator = get_node_text(node:field("operator")[1], buf)

	if operator == "|>" then
		return true
	end

	if operator == "=" then
		return M._is_pipe(node:field("right")[1], buf)
	end

	return false
end

function M._is_pipelizable(node, buf)
	if node:type() == "call" then
		if not elixir_keywords_regex:match_str(get_node_text(node:named_child(0), buf)) then
			return true
		end
	end

	if node:type() == "binary_operator" then
		return M._is_pipelizable(node:field("right")[1], buf)
	end

	return false
end

function M.call()
	local buf = treesitter_utils.get_current_elixir_buf()

	if not buf then
		return false
	end

	local master_node = treesitter_utils.get_master_node()
	local start_row, start_col, end_row, end_col = master_node:range()

	if M._is_pipe(master_node, buf) then
		local replacement = string_utils.indent_to(M._undo_pipe(master_node, buf), start_col)

		vim_buffer.replace_content(buf, start_row, start_col, end_row, end_col, replacement)
		return true
	end

	if M._is_pipelizable(master_node, buf) then
		local pipelized = M._to_pipe(master_node, buf)

		if pipelized ~= get_node_text(master_node, buf) then
			local replacement = string_utils.indent_to(pipelized, start_col)

			vim_buffer.replace_content(buf, start_row, start_col, end_row, end_col, replacement)
			return true
		end
	end

	return false
end

return M
