# Neovim shortcuts

Custom keymaps defined in this repository's Neovim config (`.config/nvim`).
`<leader>` is <kbd>Space</kbd>. LazyVim's own defaults are not repeated here;
see the [LazyVim keymaps](https://www.lazyvim.org/keymaps) page, or press
`<leader>` and wait for which-key to list everything that is active.

Keep this file in sync with the config: every added, removed, or changed
keymap or plugin updates it in the same commit (see `AGENTS.md`).

## Editing and general

Defined in `.config/nvim/lua/config/keymaps.lua`.

| Mode | Keys | Action |
| --- | --- | --- |
| n | `<F2>` | Toggle paste mode |
| n | `<F3>` | Insert the current date below the cursor |
| n | `<F10>` | Toggle line wrap |
| n | `<leader>p` | Enable completion (blink.cmp) |
| n | `<leader>P` | Disable completion (blink.cmp) |
| n | `<leader><Left>` | Vertical resize +20 |
| n | `<leader><Right>` | Vertical resize -20 |
| n | `<leader><Up>` | Horizontal resize +10 |
| n | `<leader><Down>` | Horizontal resize -10 |
| n | `<leader>rbs` | Remove every `/` in the buffer |
| n | `<leader>aq` | Surround the word under the cursor with double quotes |
| n | `<C-d>` / `<C-u>` | Scroll half a page and keep the cursor centered |

## LSP

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `K` | Hover documentation | `keymaps.lua` |
| n | `gd` | Go to definition | `keymaps.lua` |
| n, v | `<leader>ca` | Code action | `keymaps.lua` |
| n | `<leader>S` | Stop the LSP clients (`:LspStop`) | `keymaps.lua` |
| n | `gpd` | Preview definition | `goto-preview.lua` |
| n | `gpt` | Preview type definition | `goto-preview.lua` |
| n | `gpi` | Preview implementation | `goto-preview.lua` |
| n | `gpD` | Preview declaration | `goto-preview.lua` |
| n | `gpr` | Preview references | `goto-preview.lua` |
| n | `gP` | Close all preview windows | `goto-preview.lua` |

## Go (only in Go buffers)

Defined in `.config/nvim/lua/plugins/go.lua`.

| Mode | Keys | Action |
| --- | --- | --- |
| n | `<leader>ct` | Add or remove struct tags (gomodifytags) |
| n | `<leader>cl` | Run the CodeLens under the cursor |
| n | `<leader>cL` | Refresh CodeLens |
| n | `<leader>ch` | Toggle inlay hints for the buffer |

## Pickers and files (snacks.nvim)

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `<leader><leader>` | Find files | `snacks.lua` |
| n | `<leader>R` | Recent files | `snacks.lua` |
| n | `<leader>fb` | Buffers | `snacks.lua` |
| n | `<leader>fg` | Grep files | `snacks.lua` |
| n | `<leader>fs` | Pick and insert an icon or emoji | `keymaps.lua` |
| n | `<C-n>` | File explorer | `snacks.lua` |
| n | `<F12>` | Toggle zen mode | `snacks.lua` |

## Git

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `<leader>tgb` | Pick a git branch | `keymaps.lua` |
| n | `<leader>tgc` | Pick a git commit | `keymaps.lua` |
| n | `<leader>gl` | Lazygit log (cwd) | `snacks.lua` |
| n | `]h` / `[h` | Next / previous hunk | `gitsigns.lua` |
| n | `]H` / `[H` | Last / first hunk | `gitsigns.lua` |
| n, v | `<leader>ghs` | Stage hunk | `gitsigns.lua` |
| n, v | `<leader>ghr` | Reset hunk | `gitsigns.lua` |
| n | `<leader>ghS` | Stage buffer | `gitsigns.lua` |
| n | `<leader>ghu` | Undo stage hunk | `gitsigns.lua` |
| n | `<leader>ghR` | Reset buffer | `gitsigns.lua` |
| n | `<leader>ghp` | Preview hunk inline | `gitsigns.lua` |
| n | `<leader>gb` | Blame line (full) | `gitsigns.lua` |
| n | `<leader>ghb` | Blame buffer | `gitsigns.lua` |
| n | `<leader>ghd` | Diff this | `gitsigns.lua` |
| n | `<leader>ghD` | Diff this against `~` | `gitsigns.lua` |
| n | `<leader>gH` | Toggle line highlight | `gitsigns.lua` |
| o, x | `ih` | Select hunk (text object) | `gitsigns.lua` |

## Markdown

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `<leader>mp` | Toggle the browser preview | `markdown-preview.lua` |
| n | `<leader>mr` | Toggle in-buffer rendering | `render-markdown.lua` |
| n | `<leader>mti` | Insert a table of contents | `markdown-toc.lua` |
| n | `<leader>mtu` | Update the table of contents | `markdown-toc.lua` |
| n | `<leader>mtr` | Remove the table of contents | `markdown-toc.lua` |
| n, v | `<leader>mlu` | Turn lines into a bullet list | `keymaps.lua` |
| n, v | `<leader>mln` | Turn lines into a numbered list | `keymaps.lua` |
| n, v | `<leader>mlc` | Turn lines into a checkbox list | `keymaps.lua` |
| i | `<C-t>` / `<C-d>` | Indent / outdent a list item | `bullets.lua` |

## Folding

Defined in `.config/nvim/lua/config/keymaps.lua`. The `z` heading maps save
the buffer and reload it before folding.

| Mode | Keys | Action |
| --- | --- | --- |
| n | `<CR>` | Toggle the fold under the cursor |
| n | `zi` | Fold the heading the cursor is in |
| n | `zj` | Fold all headings of level 1 or deeper |
| n | `zk` | Fold all headings of level 2 or deeper |
| n | `zl` | Fold all headings of level 3 or deeper |
| n | `z;` | Fold all headings of level 4 or deeper |
| n | `zu` | Unfold all headings |

## AI: Claude Code (claudecode.nvim)

Defined in `.config/nvim/lua/plugins/claudecode.lua`.

| Mode | Keys | Action |
| --- | --- | --- |
| n | `<leader>ac` | Toggle Claude |
| n | `<leader>af` | Focus Claude |
| n | `<leader>ar` | Resume a Claude session |
| n | `<leader>aC` | Continue the last Claude session |
| n | `<leader>am` | Select the Claude model |
| n | `<leader>ab` | Add the current buffer |
| v | `<leader>as` | Send the selection to Claude |
| n | `<leader>as` | Add the file under the cursor (file explorers) |
| n | `<leader>aa` | Accept the proposed diff |
| n | `<leader>ad` | Deny the proposed diff |

opencode.nvim (`opencode.lua`) uses the same `<leader>a` group and is
disabled in `disabled.lua`. Enable only one of the two at a time; check
`opencode.lua` for its keymaps when you switch.

## Python

LazyVim's `lang.python` extra provides basedpyright (type checking and inlay
hints, selected with `vim.g.lazyvim_python_lsp` in `options.lua`), ruff
(lint and format), venv-selector, and the Python adapters for the debugger
and test runner below. These keymaps come from LazyVim extras enabled in
`lazyvim.json`.

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `<leader>cv` | Select a virtualenv | `lang.python` |
| n | `<leader>dPt` | Debug the method under the cursor | `lang.python` |
| n | `<leader>dPc` | Debug the class under the cursor | `lang.python` |

### Debugger (nvim-dap, nvim-dap-ui, debugpy)

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `<leader>db` | Toggle breakpoint | `dap.core` |
| n | `<leader>dB` | Conditional breakpoint | `dap.core` |
| n | `<leader>dc` | Run / continue | `dap.core` |
| n | `<leader>da` | Run with arguments | `dap.core` |
| n | `<leader>dC` | Run to cursor | `dap.core` |
| n | `<leader>dl` | Run last | `dap.core` |
| n | `<leader>di` | Step into | `dap.core` |
| n | `<leader>dO` | Step over | `dap.core` |
| n | `<leader>do` | Step out | `dap.core` |
| n | `<leader>dg` | Go to line (no execute) | `dap.core` |
| n | `<leader>dj` / `<leader>dk` | Down / up the stack | `dap.core` |
| n | `<leader>dP` | Pause | `dap.core` |
| n | `<leader>dt` | Terminate | `dap.core` |
| n | `<leader>dr` | Toggle REPL | `dap.core` |
| n | `<leader>ds` | Session | `dap.core` |
| n | `<leader>dw` | Widgets | `dap.core` |
| n | `<leader>du` | Toggle DAP UI | `dap.core` |
| n, v | `<leader>de` | Evaluate expression | `dap.core` |

### Tests (neotest, neotest-python / pytest)

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `<leader>tr` | Run nearest test | `test.core` |
| n | `<leader>tt` | Run current file | `test.core` |
| n | `<leader>tT` | Run all test files | `test.core` |
| n | `<leader>tl` | Run last | `test.core` |
| n | `<leader>td` | Debug nearest test | `test.core` |
| n | `<leader>ta` | Attach to test | `test.core` |
| n | `<leader>tw` | Toggle watch | `test.core` |
| n | `<leader>ts` | Toggle summary | `test.core` |
| n | `<leader>to` | Show output | `test.core` |
| n | `<leader>tO` | Toggle output panel | `test.core` |
| n | `<leader>tS` | Stop | `test.core` |

## Learning Vim (learn-vim)

An interactive tutorial with a lesson pane and an exercise pane. Progress is
saved between sessions. It has no global keymaps; use the command.

| Command | Action | Source |
| --- | --- | --- |
| `:LearnVim start` | Start or resume the tutorial | `learn-vim.lua` |
| `:LearnVim next` / `:LearnVim prev` | Next / previous lesson | `learn-vim.lua` |
| `:LearnVim lesson <m>.<l>` | Jump to a lesson, e.g. `:LearnVim lesson 2.1` | `learn-vim.lua` |
| `:LearnVim contents` | Open the table of contents | `learn-vim.lua` |
| `:LearnVim exc` / `:LearnVim exr` | Check / reset the current exercise | `learn-vim.lua` |
| `:LearnVim restart` | Restart the tutorial from the beginning | `learn-vim.lua` |

## Other tools

| Mode | Keys | Action | Source |
| --- | --- | --- | --- |
| n | `<leader>uk` | Toggle motion hints | `precognition.lua` |
| n | `<leader>U` | Toggle the undo tree | `undotree.lua` |
| n | `<leader>k` | Toggle Screenkey | `screenkey.lua` |
| n | `<leader>sv` | Toggle secret masking | `veil.lua` |
| n | `<leader>sp` | Peek the masked value on the current line | `veil.lua` |
| n | `gSe` | Encrypt the file with SOPS | `nvim-sops.lua` |
| n | `gSd` | Decrypt the file with SOPS | `nvim-sops.lua` |
