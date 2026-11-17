-- This file contains the configuration for disabling specific Neovim plugins.

return {
  {
    "zbirenbaum/copilot.lua",
    enabled = true,
  },
  -- Enable just ONE of opencode.nvim / claudecode.nvim at a time:
  -- both use the <leader>a keymap group.
  {
    "nickjvandyke/opencode.nvim",
    enabled = false,
  },
  {
    "coder/claudecode.nvim",
    enabled = true,
  },
}
