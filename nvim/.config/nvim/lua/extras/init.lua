local extra_modules = {
  "common",
  "highlight_groups",
  "clipboard",
}

for _, module in ipairs(extra_modules) do
  require("extras." .. module).setup()
end
