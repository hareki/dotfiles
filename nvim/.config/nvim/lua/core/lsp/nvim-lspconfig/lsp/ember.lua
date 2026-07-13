-- Drop the default '.git' root marker and require a workspace so the server
-- only starts inside actual Ember projects (its filetypes include plain js/ts).
return {
  opts = {
    root_markers = { 'ember-cli-build.js' },
    workspace_required = true,
  },
}
