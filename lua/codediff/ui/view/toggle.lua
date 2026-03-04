local M = {}

local lifecycle = require("codediff.ui.lifecycle")
local layout = require("codediff.ui.layout")

local function normalize_inline_layout(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    return false
  end

  lifecycle.update_layout(tabpage, "inline")
  session.single_pane = nil

  local original_win = session.original_win
  local modified_win = session.modified_win
  local keep_win = (modified_win and vim.api.nvim_win_is_valid(modified_win) and modified_win) or (original_win and vim.api.nvim_win_is_valid(original_win) and original_win)

  if not keep_win then
    return false
  end

  session.original_win = keep_win
  session.modified_win = keep_win

  local close_win = nil
  if original_win and modified_win and original_win ~= modified_win then
    close_win = keep_win == modified_win and original_win or modified_win
  end

  if close_win and vim.api.nvim_win_is_valid(close_win) then
    vim.api.nvim_set_current_win(keep_win)
    pcall(vim.api.nvim_win_close, close_win, true)
  end

  return true
end

local function normalize_side_by_side_layout(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    return false
  end

  local current_win = (session.modified_win and vim.api.nvim_win_is_valid(session.modified_win) and session.modified_win)
    or (session.original_win and vim.api.nvim_win_is_valid(session.original_win) and session.original_win)

  if not current_win then
    return false
  end

  lifecycle.update_layout(tabpage, "side-by-side")
  session.single_pane = true
  session.original_win = nil
  session.modified_win = current_win
  return true
end

local function build_session_diff_config(session, diff_config)
  if diff_config then
    return vim.deepcopy(diff_config)
  end

  return {
    mode = session.mode,
    git_root = session.git_root,
    original_path = session.original_path,
    modified_path = session.modified_path,
    original_revision = session.original_revision,
    modified_revision = session.modified_revision,
  }
end

local function rerender_current_source(tabpage)
  local session = lifecycle.get_session(tabpage)
  if not session then
    return false
  end

  if session.mode == "explorer" then
    local explorer = lifecycle.get_explorer(tabpage)
    return explorer and require("codediff.ui.explorer").rerender_current(explorer) or false
  end

  if session.mode == "history" then
    local history = lifecycle.get_explorer(tabpage)
    return history and require("codediff.ui.history").rerender_current(history) or false
  end

  local diff_config = lifecycle.get_diff_config(tabpage)
  return require("codediff.ui.view").update(tabpage, build_session_diff_config(session, diff_config), false)
end

function M.toggle(tabpage)
  tabpage = tabpage or vim.api.nvim_get_current_tabpage()
  local session = lifecycle.get_session(tabpage)
  if not session then
    return false
  end

  if session.result_win and vim.api.nvim_win_is_valid(session.result_win) then
    vim.notify("Cannot toggle layout in conflict mode", vim.log.levels.WARN)
    return false
  end

  local target_layout = session.layout == "inline" and "side-by-side" or "inline"
  local normalize = target_layout == "inline" and normalize_inline_layout or normalize_side_by_side_layout
  local previous_layout = session.layout

  if not normalize(tabpage) then
    return false
  end

  if rerender_current_source(tabpage) then
    layout.arrange(tabpage)
    return true
  end

  lifecycle.update_layout(tabpage, previous_layout)
  return false
end

return M
