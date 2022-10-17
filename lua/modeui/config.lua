--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local M = {}

-- Default config
local _config = {
  -- Remove instantly the mode mark when switching to `normal`
  -- mode, don't wait for timeout (should only be used when
  -- ignoring normal modes)
  clear_on_normal = true,
  -- Enable or not sticky mode. In sticky mode, the mode mark will
  -- move along with the cursor
  sticky = true,
  -- Mark offset position relative to the cursor. A negative
  -- number will draw the mark to the left of the cursor,
  -- a positive number to the right, 0 on top of it
  offset = 1,
  -- Default timeout (ms) after which the mode mark will be removed.
  -- Note that it can be set individually for each mode
  -- (see below), in this case the individual timeout values take
  -- precedence
  timeout = 300,
  -- Text, highlight group and timeout map.
  -- Each mode table can takes a third item which is its specific
  -- timeout value
  map = {
    normal = { '⭘', 'modeuiNormal' },
    visual = { '◆', 'modeuiVisual' },
    v_line = { '━', 'modeuiVisual' },
    v_block = { '■', 'modeuiVisual' },
    select = { '■', 'modeuiVisual' },
    insert = { '❱', 'modeuiInsert' },
    replace = { '❰', 'modeuiReplace' },
    command = { '↓', 'modeuiCommand' },
    prompt = { '↓', 'modeuiCommand' },
    shell_ex = { '❯', 'modeuiCommand' },
    terminal = { '❯', 'modeuiInsert' },
  },
  -- Background highlight mode (:h nvim_buf_set_extmark)
  hl_mode = 'combine',
  -- List of modes to ignore, items are those listed in `:h modes()`
  -- Includes normal familly, visual/select by line, terminal,
  -- shell, command line and prompt
  ignore = {
    'V',
    'Vs',
    'S',
    't',
    '!',
    'r?',
    'c',
    'cv',
    'r',
    'rm',
    'n',
    'no',
    'nov',
    'noV',
    'no',
    'niI',
    'niR',
    'niV',
    'nt',
    'ntT',
  },
}

function M.init(config)
  _config = vim.tbl_deep_extend('force', _config, config or {})
  return _config
end

return M
