local pipelize = require("elixir_dev.pipelize")
local fn_shorthand = require("elixir_dev.fn_shorthand")
local notify = require("elixir_dev.utils.notify")

local Self = { _icon = "" }

local _commands = {
	["pipelize"] = pipelize.call,
	["fn_shorthand"] = fn_shorthand.call,
}

Self.options = nil

local function with_defaults(options)
	return options or {}
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function Self.setup(options)
	-- avoid setting global values outside of this function. Global state
	-- mutations are hard to debug and test, so having them in a single
	-- function/module makes it easier to reason about all possible changes
	Self.options = with_defaults(options)

	-- do here any startup your plugin needs, like creating commands and
	-- mappings that depend on values passed in options

	vim.api.nvim_create_user_command("ElixirDev", function(opts)
		local current_level = _commands
		local call_args = {}

		for index, command in ipairs(opts.fargs) do
			if type(current_level) == "function" then
				table.insert(call_args, command)
			end

			if type(current_level) == "table" and current_level[command] then
				current_level = current_level[command]
			end

			if index == #opts.fargs and type(current_level) == "function" then
				local ok, result = pcall(current_level, unpack(call_args))

				if ok then
					return result
				end

				notify.err(string.format("Fail to run [%s]\n%s", opts.args, result), Self)
				return false
			elseif index == #opts.fargs then
				notify.err("Invalid command: " .. opts.args, Self)
				return false
			end
		end
	end, {
		nargs = "*",
		complete = function(_, line)
			local commands = vim.split(line, "%s+")
			local current_level = nil

			local completion = function(arg)
				local result = {}

				if not current_level or type(current_level) ~= "table" then
					return result
				end

				for key, _ in pairs(current_level) do
					table.insert(result, key)
				end

				if arg == "" then
					return result
				end

				return vim.tbl_filter(function(val)
					return vim.startswith(val, arg)
				end, result)
			end

			for index, command in ipairs(commands) do
				if index == 1 then
					current_level = _commands
				else
					if index == #commands then
						return completion(command)
					end

					if type(current_level) == "table" and current_level[command] ~= nil then
						current_level = current_level[command]
					else
						return completion(command)
					end
				end
			end
		end,
	})
end

return Self
