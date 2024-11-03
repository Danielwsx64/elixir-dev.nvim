local treesitter_utils = require("elixir_dev.utils.treesitter")

describe("get_master_node", function()
	it("return master node for a function argument node", function()
		local text = { "def implement() do", "cool_function(argument)", "end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local function_node = root:named_child(0):named_child(2):named_child(0)
		local argument_node = function_node:named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(function_node, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when has a parent binary_operator in a previous line includes it", function()
		local text = { "def implement() do", "result =", "cool_function(argument)", "end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local binary_op_node = root:named_child(0):named_child(2):named_child(0)
		local argument_node = binary_op_node:named_child(1):named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(binary_op_node, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return the entire pipe node when has a middle node", function()
		local text = {
			"def implement() do",
			"result =",
			"argument",
			"|> cool_function()",
			"|> another_function()",
			"end",
		}
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local binary_op_node = root:named_child(0):named_child(2):named_child(0)
		local middle_fn_node = binary_op_node:named_child(1):named_child(0):named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(middle_fn_node)

		assert.combinators.match(binary_op_node, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when parent is stab_clause ignore it as master", function()
		local text = {
			"def func() do",
			"  case valor do",
			"    {:ok, value} -> cool_function(value)",
			"    {:error, _reason} = err -> err",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local function_node = root:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(1)
			:named_child(0)

		local argument_node = function_node:named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(function_node, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when inside a multiline map returns map parent master node", function()
		local text = {
			"%{",
			'  "key" => value,',
			'  "other_key" => "other_value"',
			"}",
			"|> new()",
			"|> insert()",
		}
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local value_node =
			root:named_child(0):named_child(0):named_child(0):named_child(0):named_child(0):named_child(1)

		local master_node = treesitter_utils.get_master_node(value_node)

		assert.combinators.match(root, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when inside a multiline map (atom keys) returns map parent master node", function()
		local text = {
			"%{",
			"  key: value,",
			"  other_key: value",
			"}",
			"|> simple_function()",
			"|> another()",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local value_node = root:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(1)
			:named_child(1)

		local master_node = treesitter_utils.get_master_node(value_node)

		assert.combinators.match(root, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when start node is a call function inside a map stops on the call function", function()
		local text = {
			"%{",
			'  "key" => function(value),',
			'  "other_key" => "other_value"',
			"}",
			"|> new()",
			"|> insert()",
		}
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_funcition_node =
			root:named_child(0):named_child(0):named_child(0):named_child(0):named_child(0):named_child(1)

		local argument_node = inner_funcition_node:named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(inner_funcition_node, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when start node is a call function inside a map (with atom keys) stops on the call function", function()
		local text = {
			"%{",
			"  key: function(value),",
			'  other_key: "other_value"',
			"}",
			"|> new()",
			"|> insert()",
		}
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_funcition_node = root:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(1)

		local argument_node = inner_funcition_node:named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(inner_funcition_node, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when start node is a pipe inside a map (with atom keys) stops on the call function", function()
		local text = {
			"%{",
			"  key: value |> map_fn()",
			"}",
			"|> one()",
			"|> two()",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_pipe_funcition_node = root:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(1)

		local argument_node = inner_pipe_funcition_node:named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(inner_pipe_funcition_node, master_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)

describe("get_parent_node", function()
	it("return parent call node", function()
		local text = { "def implement() do", "cool_function(argument)", "end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local function_node = root:named_child(0):named_child(2):named_child(0)
		local argument_node = function_node:named_child(1):named_child(0)

		local parent_node = treesitter_utils.get_parent_node({ "call" }, nil, argument_node)

		assert.combinators.match(function_node, parent_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return parent anonymous function node", function()
		local text = { "fn key, value -> IO.inspect({key, value}, limit: :infinity) end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local function_node = root:named_child(0)
		local argument_node = function_node
			:named_child(0)
			:named_child(1)
			:named_child(0)
			:named_child(1)
			:named_child(1)
			:named_child(0)
			:named_child(1)

		local parent_node = treesitter_utils.get_parent_node({ "anonymous_function" }, nil, argument_node)

		assert.combinators.match(function_node, parent_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return parent unary operator node with multi types allowed", function()
		local text = { "&IO.inspect(&1, limiti: :infinity)" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local unary_op_node = root:named_child(0)
		local argument_node = unary_op_node:named_child(0):named_child(1):named_child(1):named_child(0):named_child(1)

		local parent_node =
			treesitter_utils.get_parent_node({ "anonymous_function", "unary_operator" }, nil, argument_node)

		assert.combinators.match(unary_op_node, parent_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when has a validation fn", function()
		local text = { "%{first: %{second: %{third: 2}}}" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local map_node = root:named_child(0)
		local inner_node = map_node
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(1)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(1)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(1)

		local validation = function(node)
			if node:id() == map_node:id() then
				return true
			end
			return false
		end

		local parent_node = treesitter_utils.get_parent_node({ "map" }, validation, inner_node)

		assert.combinators.match(map_node, parent_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when current node is the looking type", function()
		local text = { "fn key, value -> IO.inspect({key, value}, limit: :infinity) end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local function_node = root:named_child(0)

		local parent_node = treesitter_utils.get_parent_node({ "anonymous_function" }, nil, function_node)

		assert.combinators.match(function_node, parent_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return nil when not found", function()
		local text = { "&IO.inspect(&1, limiti: :infinity)" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local argument_node =
			root:named_child(0):named_child(0):named_child(1):named_child(1):named_child(0):named_child(1)

		local parent_node = treesitter_utils.get_parent_node({ "anonymous_function" }, nil, argument_node)

		assert.is_nil(parent_node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)

describe("is_ts_elixir_parser_enabled", function()
	it("return true when the given buf has an elixir parser enabled", function()
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.treesitter.start(bufnr, "elixir")

		assert.is_true(treesitter_utils.is_ts_elixir_parser_enabled(bufnr))

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return false when the given buf has not an elixir parser enabled", function()
		local bufnr = vim.api.nvim_create_buf(false, true)

		assert.is_not_true(treesitter_utils.is_ts_elixir_parser_enabled(bufnr))

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)

describe("get_all_child", function()
	it("return all child by function", function()
		local text = {
			"defmodule Example.Module do",
			"  def function_name(arg) do",
			"    :ok",
			"  end",
			"",
			"  def function_name do",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(bufnr, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local node = root:child(0):child(2)

		local expected_one = node:child(1)
		local expected_two = node:child(2)

		local results = treesitter_utils.get_all_child(function(n)
			local target_node = n:field("target")[1]

			return target_node and vim.treesitter.get_node_text(target_node, bufnr) == "def"
		end, node)

		assert.combinators.match(results[1], expected_one)
		assert.combinators.match(results[2], expected_two)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return empty list when not found", function()
		local text = {
			"defmodule Example.Module do",
			"  def function_name(arg) do",
			"    :ok",
			"  end",
			"",
			"  def function_name do",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(bufnr, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local node = root:child(0):child(2)

		local results = treesitter_utils.get_all_child(function()
			return false
		end, node)

		assert.combinators.match(results, {})

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)
