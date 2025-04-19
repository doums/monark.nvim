-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local hl_fn = require('monark.util').hl
local hl_exists = require('monark.util').hl_exists

local M = {}

local ns_id = vim.api.nvim_create_namespace('monark')
local extmark_id = 1

local function find_pos(offset, initial)
  local col
  local cur_line = vim.api.nvim_get_current_line()
  local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
  if #cur_line == 0 then
    -- If the cursor line is empty, draw it at EOL
    return { cursor_row - 1, -1 }
  end
  -- Try to find the UTF-32 indexed position
  local status, result =
    pcall(vim.str_utfindex, cur_line, 'utf-16', cursor_col + offset)
  if status then
    col = vim.str_byteindex(cur_line, 'utf-16', result)
  elseif offset >= 0 and initial >= 0 then
    -- If the initial offset is positive (mode drawing to the
    -- right), and attempting to draw it fails, first try by
    -- reducing the offset and finally draw it at the EOL
    if offset - 1 < initial then
      -- If the remaining space is less than the wanted offset
      -- draw it at the EOL
      col = -1
    else
      return find_pos(offset - 1, initial)
    end
  else
    -- If mode drawing fails to the left of the cursor, first try
    -- by reducing the offset and finally draw it to the right
    -- Skip 0, do not draw mode ontop of the cursor
    return find_pos(offset + 1 == 0 and 1 or offset + 1, initial)
  end
  return { cursor_row - 1, col }
end

local function draw_mark(config, direction)
  local data = config[direction]
  if not data then
    return
  end
  local position = data.position or (direction == 'forward' and 1 or -1)
  local row, col = unpack(find_pos(position, position))
  vim.api.nvim_buf_set_extmark(0, ns_id, row, col, {
    id = extmark_id,
    virt_text = { { data[1], data[2] } },
    virt_text_pos = col == -1 and 'eol' or 'overlay',
    hl_mode = config.hl_mode or 'combine',
  })
end

function M.init(config)
  if not hl_exists('monarkLeap') then
    hl_fn('monarkLeap', '#f00fdd', nil, 'bold')
  end
  local s, leap = pcall(function()
    return require('leap')
  end, nil)
  if not s then
    vim.notify('leap.nvim not installed', vim.log.levels.WARN)
    return
  end
  vim.api.nvim_create_autocmd('User', {
    pattern = { 'LeapEnter', 'LeapLeave' },
    callback = function(a)
      if a.match == 'LeapEnter' then
        draw_mark(config, leap.state.args.backward and 'backward' or 'forward')
      else
        vim.api.nvim_buf_del_extmark(0, ns_id, extmark_id)
      end
    end,
  })
end

return M
