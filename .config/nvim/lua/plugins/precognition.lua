-- https://github.com/tris203/precognition.nvim
-- Shows virtual-text hints for the motions available from the cursor
-- (w, b, e, ^, $, %, {, }, gg, G...) to help learn Vim movements.
--
-- Default keybindings:
-- <leader>uk - Toggle motion hints

return {
  "tris203/precognition.nvim",
  event = "VeryLazy",
  opts = {},
  keys = {
    {
      "<leader>uk",
      function()
        require("precognition").toggle()
      end,
      desc = "Toggle Precognition hints",
    },
  },
}
