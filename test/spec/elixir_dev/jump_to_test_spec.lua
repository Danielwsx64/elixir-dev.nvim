local jump_to_test = require("elixir_dev.jump_to_test")
local treesitter_utils = require("elixir_dev.utils.treesitter")

describe("_directions", function()
	it("relative path for implementation file", function()
		local result = jump_to_test._directions("lib/xcribe", "conn_parser.ex")

		local expected = {
			["exs"] = {
				expected_caller = "describe",
				go_to = {
					dir = "lib/xcribe/",
					file = "conn_parser.ex",
				},
			},
			["ex"] = {
				expected_caller = "def",
				go_to = {
					dir = "test/xcribe/",
					file = "conn_parser_test.exs",
				},
			},
		}

		assert.combinators.match(result, expected)
	end)

	it("relative path for test file", function()
		local result = jump_to_test._directions("test/xcribe", "conn_parser_test.exs")

		local expected = {
			["exs"] = {
				expected_caller = "describe",
				go_to = {
					dir = "lib/xcribe/",
					file = "conn_parser.ex",
				},
			},
			["ex"] = {
				expected_caller = "def",
				go_to = {
					dir = "test/xcribe/",
					file = "conn_parser_test.exs",
				},
			},
		}

		assert.combinators.match(result, expected)
	end)

	it("direct lib path", function()
		local result = jump_to_test._directions("lib", "xcribe.ex")

		local expected = {
			["exs"] = {
				expected_caller = "describe",
				go_to = {
					dir = "lib/",
					file = "xcribe.ex",
				},
			},
			["ex"] = {
				expected_caller = "def",
				go_to = {
					dir = "test/",
					file = "xcribe_test.exs",
				},
			},
		}

		assert.combinators.match(result, expected)
	end)

	it("relative path for test file", function()
		local result = jump_to_test._directions("test/xcribe", "conn_parser_test.exs")

		local expected = {
			["exs"] = {
				expected_caller = "describe",
				go_to = {
					dir = "lib/xcribe/",
					file = "conn_parser.ex",
				},
			},
			["ex"] = {
				expected_caller = "def",
				go_to = {
					dir = "test/xcribe/",
					file = "conn_parser_test.exs",
				},
			},
		}

		assert.combinators.match(result, expected)
	end)

	it("compound file name", function()
		local result = jump_to_test._directions("lib/project_one", "module_controller_test.exs")

		local expected = {
			["exs"] = {
				expected_caller = "describe",
				go_to = {
					dir = "lib/project_one/",
					file = "module_controller.ex",
				},
			},
			["ex"] = {
				expected_caller = "def",
				go_to = {
					dir = "test/project_one/",
					file = "module_controller_test.exs",
				},
			},
		}

		assert.combinators.match(result, expected)
	end)
end)

describe("_get_caller_info", function()
	it("return fn indentifier and arity when called by def", function()
		local text = { "def implement() do", "cool_function(argument)", "end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0):named_child(2):named_child(0):named_child(0)

		local result = jump_to_test._get_caller_info("def", inner_node, bufnr)
		local expected = {
			type = "function",
			arity = 0,
			name = "implement",
		}

		assert.combinators.match(result, expected)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return fn indentifier and arity one when called by def", function()
		local text = { "def implement(argument) do", "cool_function(argument)", "end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0):named_child(2):named_child(0):named_child(0)

		local result = jump_to_test._get_caller_info("def", inner_node, bufnr)

		local expected = {
			type = "function",
			arity = 1,
			name = "implement",
		}

		assert.combinators.match(result, expected)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return fn indentifier and arity one when called by def with guard clause", function()
		local text = { "def implement(argument) when is_binary(argument) do", "cool_function(argument)", "end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0):named_child(2):named_child(0):named_child(0)

		local result = jump_to_test._get_caller_info("def", inner_node, bufnr)

		local expected = {
			type = "function",
			arity = 1,
			name = "implement",
		}

		assert.combinators.match(result, expected)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when function def has no parentheses", function()
		local text = { "def implement do", "cool_function(argument)", "end" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0):named_child(2):named_child(0):named_child(0)

		local result = jump_to_test._get_caller_info("def", inner_node, bufnr)
		local expected = {
			type = "function",
			arity = 0,
			name = "implement",
		}

		assert.combinators.match(result, expected)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return nil when cannot found a def", function()
		local text = { "cool_function(argument)" }
		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0):named_child(0)

		local result = jump_to_test._get_caller_info("def", inner_node, bufnr)

		assert.is_nil(result)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return fn indentifier and arity when called by describe", function()
		local text = {
			'  describe "function_name/0" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(1)
			:named_child(0)
			:named_child(1)

		local result = jump_to_test._get_caller_info("describe", inner_node, bufnr)

		local expected = {
			type = "describe",
			arity = 0,
			name = "function_name",
		}

		assert.combinators.match(result, expected)
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return fn indentifier and arity one when called by describe", function()
		local text = {
			'  describe "function_name/1" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(1)
			:named_child(0)
			:named_child(1)

		local result = jump_to_test._get_caller_info("describe", inner_node, bufnr)

		local expected = {
			type = "describe",
			arity = 1,
			name = "function_name",
		}

		assert.combinators.match(result, expected)
		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return nil when describe does not have fn arity", function()
		local text = {
			'  describe "function_name" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node = root:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(2)
			:named_child(0)
			:named_child(1)
			:named_child(0)
			:named_child(1)

		local result = jump_to_test._get_caller_info("describe", inner_node, bufnr)

		assert.is_nil(result)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return nil when cannot found a describe", function()
		local text = {
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local inner_node =
			root:named_child(0):named_child(2):named_child(0):named_child(1):named_child(0):named_child(1)

		local result = jump_to_test._get_caller_info("describe", inner_node, bufnr)

		assert.is_nil(result)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)

describe("_get_describe_node_by", function()
	it("get the describe node that matchs with from info", function()
		local text = {
			"defmodule Example do",
			'  describe "function_name/1" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
			"",
			'  describe "function_name/2 adiciontal desc" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local expected_node = root:named_child(0):named_child(2):named_child(1):named_child(1):named_child(0)
		local from = {
			type = "describe",
			arity = 2,
			name = "function_name",
		}

		local node = jump_to_test._get_describe_node_by(from, bufnr)

		assert.combinators.match(expected_node, node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when describe does not have the arity return the node with fn name in description", function()
		local text = {
			"defmodule Example do",
			'  describe "arbitrary desc" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
			"",
			'  describe "function_name without the arity" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local expected_node = root:named_child(0):named_child(2):named_child(1):named_child(1):named_child(0)
		local from = {
			type = "describe",
			arity = 2,
			name = "function_name",
		}

		local node = jump_to_test._get_describe_node_by(from, bufnr)

		assert.combinators.match(expected_node, node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("return nil when cant find function describe", function()
		local text = {
			"defmodule Example do",
			'  describe "some cool descrition" do',
			'    test "scenery" do',
			"      assert Example.function_name()",
			"    end",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local from = {
			type = "describe",
			arity = 2,
			name = "function_name",
		}

		local node = jump_to_test._get_describe_node_by(from, bufnr)

		assert.is_nil(node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)

describe("_get_def_node_by", function()
	it("get the def node that matchs with from info", function()
		local text = {
			"defmodule Example do",
			"  def function_name() do",
			"  end",
			"",
			"  def function_name(arg1, arg2) do",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local expected_node = root:named_child(0):named_child(2):named_child(1):named_child(1):named_child(0)

		local from = {
			type = "def",
			arity = 2,
			name = "function_name",
		}

		local node = jump_to_test._get_def_node_by(from, bufnr)

		assert.combinators.match(expected_node, node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("get the def node that matchs with from info and has guard clause", function()
		local text = {
			"defmodule Example do",
			"  def function_name() do",
			"  end",
			"",
			"  def function_name(arg1, arg2) when is_binary(arg1) do",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local expected_node =
			root:named_child(0):named_child(2):named_child(1):named_child(1):named_child(0):named_child(0)

		local from = {
			type = "def",
			arity = 2,
			name = "function_name",
		}

		local node = jump_to_test._get_def_node_by(from, bufnr)

		assert.combinators.match(expected_node, node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when fn definition has no parameters without parentheses", function()
		local text = {
			"defmodule Example do",
			"  def function_name(arg) do",
			"  end",
			"",
			"  def function_name do",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local expected_node = root:named_child(0):named_child(2):named_child(1):named_child(1):named_child(0)

		local from = {
			type = "def",
			arity = 0,
			name = "function_name",
		}

		local node = jump_to_test._get_def_node_by(from, bufnr)

		assert.combinators.match(expected_node, node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)

	it("when fn definition has no parameters with parentheses", function()
		local text = {
			"defmodule Example do",
			"  def function_name(arg) do",
			"  end",
			"",
			"  def function_name() do",
			"  end",
			"end",
		}

		local bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_text(bufnr, 0, 0, 0, 0, text)

		local root = treesitter_utils.get_root(bufnr)
		local expected_node = root:named_child(0):named_child(2):named_child(1):named_child(1):named_child(0)

		local from = {
			type = "def",
			arity = 0,
			name = "function_name",
		}

		local node = jump_to_test._get_def_node_by(from, bufnr)

		assert.combinators.match(expected_node, node)

		vim.api.nvim_buf_delete(bufnr, { force = true })
	end)
end)
