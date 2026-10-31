-- Drop the '.git' root marker and require a workspace: its filetypes include plain js/ts
return {
  opts = {
    root_markers = { 'ember-cli-build.js' },
    workspace_required = true,
  },
}
