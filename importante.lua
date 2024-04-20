-- it returns the buf filetype
-- local a = vim.bo[bufnr].filetype

-- Lua class typed(?) function you must learn about that
-- print(vim.inspect(string.match("daniel/3 [sei la]", "daniel/3")))
--
-- print(vim.inspect(string.match("ddaaniel/3 [sei la]", "daniel/3")))

-- local str = "function_name/0"
local str = "function_name/0 [ bla la]"

local pattern = "([%a_]+)/(%d+)"

-- string.
local result = string.gmatch(str, pattern)

if result then
	print(vim.inspect(result))
end
