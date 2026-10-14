-- Go IDE tuning on top of `lazyvim.plugins.extras.lang.go`.
--
-- The Go extra already wires gopls (gofumpt, staticcheck, inlay hints,
-- analyses, govulncheck codelens), none-ls (gomodifytags, impl),
-- neotest-golang and nvim-dap-go. This file only fills the gaps:
--   1. Ensure `gotests` + `delve` are installed via Mason (delve is
--      otherwise lazy and may not install until DAP first loads).
--   2. Add discoverable, buffer-local Go keymaps under the `<leader>c`
--      (code) group, bound to features that already exist.
--
-- Keymap collision check (verified against lua/config/keymaps.lua):
--   <leader>ca ....... existing (code action) -> untouched
--   <leader>ct/cT/cv/cg ... free
--   <leader>t* ....... neotest group (tt/tr/td/ts/...) does NOT clash
--                      with your existing <leader>tg* Telescope git maps.

return {
  -- Force-install the tools the extra omits or lazy-loads.
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "gotests", "delve" } },
  },

  -- Go-specific ergonomic keymaps, bound to already-present features.
  {
    "neovim/nvim-lspconfig",
    opts = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "go",
        callback = function(ev)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, { buffer = ev.buf, desc = desc })
          end

          -- Struct tags via gomodifytags code actions (none-ls).
          map("<leader>ct", function()
            vim.lsp.buf.code_action({ context = { only = { "refactor.rewrite" } }, apply = false })
          end, "Go: Struct Tags (add/remove)")

          -- Run codelens under cursor (go generate, govulncheck, tidy, test...).
          map("<leader>cl", vim.lsp.codelens.run, "Go: Run CodeLens")
          map("<leader>cL", vim.lsp.codelens.refresh, "Go: Refresh CodeLens")

          -- Toggle inlay hints for this buffer.
          map("<leader>ch", function()
            local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf })
            vim.lsp.inlay_hint.enable(not enabled, { bufnr = ev.buf })
            vim.notify("Go inlay hints " .. (enabled and "disabled" or "enabled"))
          end, "Go: Toggle Inlay Hints")
        end,
      })
    end,
  },
}
