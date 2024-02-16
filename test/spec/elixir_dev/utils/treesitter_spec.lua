local treesitter_utils = require("elixir_dev.utils.treesitter")

describe("get_master_node", function()
	it("return master node for a function argument node", function()
		local text = { "def implement() do", "cool_function(argument)", "end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local function_node = root:named_child(0):named_child(2):named_child(0)
		local argument_node = function_node:named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(function_node, master_node)

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when has a parent binary_operator in a previous line includes it", function()
		local text = { "def implement() do", "result =", "cool_function(argument)", "end" }
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local binary_op_node = root:named_child(0):named_child(2):named_child(0)
		local argument_node = binary_op_node:named_child(1):named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(binary_op_node, master_node)

		vim.api.nvim_buf_delete(buf, { force = true })
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
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local binary_op_node = root:named_child(0):named_child(2):named_child(0)
		local middle_fn_node = binary_op_node:named_child(1):named_child(0):named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(middle_fn_node)

		assert.combinators.match(binary_op_node, master_node)

		vim.api.nvim_buf_delete(buf, { force = true })
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

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

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

		vim.api.nvim_buf_delete(buf, { force = true })
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
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local value_node =
			root:named_child(0):named_child(0):named_child(0):named_child(0):named_child(0):named_child(1)

		local master_node = treesitter_utils.get_master_node(value_node)

		assert.combinators.match(root, master_node)

		vim.api.nvim_buf_delete(buf, { force = true })
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

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local value_node = root:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(0)
			:named_child(1)
			:named_child(1)

		local master_node = treesitter_utils.get_master_node(value_node)

		assert.combinators.match(root, master_node)

		vim.api.nvim_buf_delete(buf, { force = true })
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
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

		local inner_funcition_node =
			root:named_child(0):named_child(0):named_child(0):named_child(0):named_child(0):named_child(1)

		local argument_node = inner_funcition_node:named_child(1):named_child(0)

		local master_node = treesitter_utils.get_master_node(argument_node)

		assert.combinators.match(inner_funcition_node, master_node)

		vim.api.nvim_buf_delete(buf, { force = true })
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
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

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

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("when start node is a pipe inside a map (with atom keys) stops on the call function", function()
		local text = {
			"%{",
			"  key: value |> map_fn()",
			"}",
			"|> one()",
			"|> two()",
		}

		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(buf, 0, 0, 0, 0, text)

		local parser = vim.treesitter.get_parser(buf, "elixir")
		local tree = parser:parse()[1]
		local root = tree:root()

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

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)

describe("is_elixir_lang", function()
	it("return true when the given buf has an elixir parser enabled", function()
		local buf = vim.api.nvim_create_buf(false, true)
		vim.treesitter.start(buf, "elixir")

		assert.is_true(treesitter_utils.is_elixir_lang(buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)

	it("return false when the given buf has not an elixir parser enabled", function()
		local buf = vim.api.nvim_create_buf(false, true)

		assert.is_not_true(treesitter_utils.is_elixir_lang(buf))

		vim.api.nvim_buf_delete(buf, { force = true })
	end)
end)
