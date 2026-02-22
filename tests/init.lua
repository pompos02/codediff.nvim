-- Test init file for plenary tests
-- This loads the plugin and plenary.nvim

-- Disable auto-installation in tests (library is already built by CI)
vim.env.VSCODE_DIFF_NO_AUTO_INSTALL = "1"

-- Disable ShaDa (fixes Windows permission issues in CI)
vim.opt.shadafile = "NONE"

-- Disable vim.loader - it overrides require() with rtp-only resolution
-- which breaks when tests change CWD (making relative rtp "." point elsewhere)
vim.loader.enable(false)

-- Determine project root from this file's location (stable even when CWD changes)
local this_file = debug.getinfo(1, "S").source:sub(2) -- remove @ prefix
local tests_dir = vim.fn.fnamemodify(this_file, ":p:h")
local project_root = vim.fn.fnamemodify(tests_dir, ":h")

-- Add project root to runtimepath
vim.opt.rtp:prepend(project_root)

-- Ensure lua/ directory is in package.path for direct requires
-- Use absolute paths so modules remain findable even after CWD changes
local lua_dir = (project_root .. "/lua"):gsub("\\", "/")
package.path = lua_dir .. "/?.lua;" .. lua_dir .. "/?/init.lua;" .. package.path

vim.opt.swapfile = false

-- Setup plenary.nvim in Neovim's data directory (proper location)
local plenary_dir = vim.fn.stdpath("data") .. "/plenary.nvim"
if vim.fn.isdirectory(plenary_dir) == 0 then
  -- Clone plenary if not found
  print("Installing plenary.nvim for tests...")
  vim.fn.system({
    "git",
    "clone",
    "--depth=1",
    "https://github.com/nvim-lua/plenary.nvim",
    plenary_dir,
  })
end
vim.opt.rtp:prepend(plenary_dir)

-- Load plugin files (for integration tests that need commands)
vim.cmd('runtime! plugin/*.lua plugin/*.vim')

-- Setup plugin
require("codediff").setup()
