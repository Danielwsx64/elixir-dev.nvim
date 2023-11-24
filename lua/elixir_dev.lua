local my_cool_module = require("elixir_dev.my_cool_module")

local elixir_dev = {}

local function with_defaults(options)
   return {
      name = options.name or "John Doe"
   }
end

-- This function is supposed to be called explicitly by users to configure this
-- plugin
function elixir_dev.setup(options)
   -- avoid setting global values outside of this function. Global state
   -- mutations are hard to debug and test, so having them in a single
   -- function/module makes it easier to reason about all possible changes
   elixir_dev.options = with_defaults(options)

   -- do here any startup your plugin needs, like creating commands and
   -- mappings that depend on values passed in options
   vim.api.nvim_create_user_command("MyAwesomePluginGreet", elixir_dev.greet, {})
end

function elixir_dev.is_configured()
   return elixir_dev.options ~= nil
end

-- This is a function that will be used outside this plugin code.
-- Think of it as a public API
function elixir_dev.greet()
   if not elixir_dev.is_configured() then
      return
   end

   -- try to keep all the heavy logic on pure functions/modules that do not
   -- depend on Neovim APIs. This makes them easy to test
   local greeting = my_cool_module.greeting(elixir_dev.options.name)
   print(greeting)
end

-- Another function that belongs to the public API. This one does not depend on
-- user configuration
function elixir_dev.generic_greet()
   print("Hello, unnamed friend!")
end

elixir_dev.options = nil
return elixir_dev
