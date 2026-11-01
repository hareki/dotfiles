return {
  opts = {
    -- Upstream's root_dir answers nil outside an oxlint project, which starts a rootless server
    workspace_required = true,
  },
}
