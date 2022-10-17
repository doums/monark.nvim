--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local api = vim.api
local uv = vim.loop
local hl_fn = require('modeui.util').hl
local hl_exists = require('modeui.util').hl_exists

local M = {}

local group_id = api.nvim_create_augroup('modeui', {})
local ns_id = api.nvim_create_namespace('modeui')
local extmark_id = 1
local timer = uv.new_timer()
local _text
local _hl
local _timeout

local normal_modes =
  { 'n', 'no', 'nov', 'noV', 'no', 'niI', 'niR', 'niV', 'nt', 'ntT' }

local modes_map = {
  { '^n', 'normal' },
  { '^v', 'visual' },
  { '^V', 'v_line' },
  { '^', 'v_block' },
  { '^s', 'select' },
  { '^S', 'select' },
  { '^', 'select' },
  { '^i', 'insert' },
  { '^R', 'replace' },
  { '^c', 'command' },
  { '^r', 'prompt' },
  { '^!', 'shell_ex' },
  { '^t', 'terminal' },
}

local function get_mode_render(map, mode)
  for _, v in ipairs(modes_map) do
    if string.find(mode, v[1]) then
      return map[v[2]]
    end
  end
end

local function defer_clear(timeout, buffer)
  if timer:is_active() then
    timer:stop()
  end
  timer:start(
    timeout,
    0,
    vim.schedule_wrap(function()
      api.nvim_buf_del_extmark(buffer, ns_id, extmark_id)
    end)
  )
end

local function find_pos(offset, initial)
  local col
  local cur_line = api.nvim_get_current_line()
  local cursor_row, cursor_col = unpack(api.nvim_win_get_cursor(0))
  if #cur_line == 0 then
    -- If the cursor line is empty, draw it at EOL
    return { cursor_row - 1, -1 }
  end
  -- Try to find the UTF-32 indexed position
  local status, result = pcall(vim.str_utfindex, cur_line, cursor_col + offset)
  if status then
    col = vim.str_byteindex(cur_line, result)
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

local function set_extmark(config, text, hl)
  local row, col = unpack(find_pos(config.offset, config.offset))
  api.nvim_buf_set_extmark(0, ns_id, row, col, {
    id = extmark_id,
    virt_text = { { text, hl } },
    virt_text_pos = col == -1 and 'eol' or 'overlay',
    hl_mode = config.hl_mode or 'combine',
  })
end

local function create_hls()
  if not hl_exists('modeuiNormal') then
    hl_fn('modeuiNormal', '#c7c7ff', nil, 'bold')
  end
  if not hl_exists('modeuiInsert') then
    hl_fn('modeuiInsert', '#69ff00', nil, 'bold')
  end
  if not hl_exists('modeuiReplace') then
    hl_fn('modeuiReplace', '#ff0050', nil, 'bold')
  end
  if not hl_exists('modeuiVisual') then
    hl_fn('modeuiVisual', '#0087ff', nil, 'bold')
  end
  if not hl_exists('modeuiCommand') then
    hl_fn('modeuiCommand', '#93896c', nil, 'bold')
  end
end

function M.init(config)
  create_hls()
  api.nvim_create_autocmd('ModeChanged', {
    group = group_id,
    pattern = '*',
    callback = function()
      local mode = api.nvim_get_mode().mode
      if config.clear_on_normal and vim.tbl_contains(normal_modes, mode) then
        api.nvim_buf_del_extmark(0, ns_id, extmark_id)
        return
      end
      if vim.tbl_contains(config.ignore, mode) then
        return
      end
      _text, _hl, _timeout = unpack(get_mode_render(config.map, mode))
      set_extmark(config, _text, _hl)
      defer_clear(_timeout or config.timeout, api.nvim_get_current_buf())
    end,
  })

  if config.sticky then
    api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = group_id,
      pattern = '*',
      callback = function()
        local result = api.nvim_buf_get_extmark_by_id(0, ns_id, extmark_id, {})
        if not vim.tbl_isempty(result) then
          -- Only update the mode position when the extmark is drawn
          -- TODO instead of using local variables for current
          -- mark text and hl, use the values from nvim_buf_get_extmark_by_id
          set_extmark(config, _text, _hl)
        end
      end,
    })
  end
end

return M
