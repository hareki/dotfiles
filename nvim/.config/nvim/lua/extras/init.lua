local extra_modules = {
  "common",
  "debug",
  "highlight_groups",
  "clipboard",
  "snippets",
}

for _, module in ipairs(extra_modules) do
  require("extras." .. module).setup()
end
