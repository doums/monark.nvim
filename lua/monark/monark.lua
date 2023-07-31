-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local api = vim.api
local hl_fn = require('monark.utils').hl
local hl_exists = require('monark.utils').hl_exists
local make_timer = require('monark.timer').timer

local M = {}

local group_id = api.nvim_create_augroup('monark', {})
local ns_id = api.nvim_create_namespace('monark')
local extmark_id = 1
local timer = make_timer:new()
local i_timer = make_timer:new()
local _offset
local _hl_mode

local normal_modes = { 'n', 'niI', 'niR', 'niV', 'nt', 'ntT' }

local modes_map = {
  { { 'n', 'niI', 'niR', 'niV', 'nt', 'ntT' }, 'normal' },
  { { 'v', 'vs' }, 'visual' },
  { { 'V', 'Vs' }, 'visual_l' },
  { { '', 's' }, 'visual_b' },
  { { 's', 'S', '' }, 'select' },
  { { 'i', 'ic', 'ix' }, 'insert' },
  { { 'R', 'Rc', 'Rx', 'Rv', 'Rvc', 'Rvx' }, 'replace' },
  { { 't' }, 'terminal' },
  -- support for leap.nvim
  { { 'leap_f' }, 'leap_f' },
  { { 'leap_b' }, 'leap_b' },
}

local function get_mode_render(map, mode)
  for _, v in ipairs(modes_map) do
    if vim.tbl_contains(v[1], mode) then
      return map[v[2]]
    end
  end
end

local function defer_clear(timeout, buffer)
  if timer:is_active() then
    timer:stop()
  end
  timer:start(timeout, function()
    if api.nvim_buf_is_valid(buffer) then
      api.nvim_buf_del_extmark(buffer, ns_id, extmark_id)
    end
  end)
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

local function set_extmark(data)
  local row, col = unpack(find_pos(data.offset, data.offset))
  api.nvim_buf_set_extmark(0, ns_id, row, col, {
    id = extmark_id,
    virt_text = { { data.text, data.hl } },
    virt_text_pos = col == -1 and 'eol' or 'overlay',
    hl_mode = data.hl_mode,
  })
end

local function create_hls()
  if not hl_exists('monarkNormal') then
    hl_fn('monarkNormal', '#c7c7ff', nil, 'bold')
  end
  if not hl_exists('monarkInsert') then
    hl_fn('monarkInsert', '#69ff00', nil, 'bold')
  end
  if not hl_exists('monarkReplace') then
    hl_fn('monarkReplace', '#ff0050', nil, 'bold')
  end
  if not hl_exists('monarkVisual') then
    hl_fn('monarkVisual', '#0087ff', nil, 'bold')
  end
  if not hl_exists('monarkCommand') then
    hl_fn('monarkCommand', '#93896c', nil, 'bold')
  end
  if not hl_exists('monarkLeap') then
    hl_fn('monarkLeap', '#f00fdd', nil, 'bold')
  end
end

local function draw_mark(config, mode)
  if config.clear_on_normal and vim.tbl_contains(normal_modes, mode) then
    pcall(api.nvim_buf_del_extmark, 0, ns_id, extmark_id)
    return
  end
  if vim.tbl_contains(config.ignore, mode) then
    return
  end
  local data = get_mode_render(config.modes, mode)
  if not data then
    return
  end
  _offset = data.offset or config.offset
  _hl_mode = data.hl_mode or config.hl_mode
  set_extmark({
    text = data[1],
    hl = data[2],
    offset = _offset,
    hl_mode = _hl_mode,
  })
  if not data.no_timeout then
    defer_clear(data.timeout or config.timeout, api.nvim_get_current_buf())
  end
end

function M.init(config)
  create_hls()
  api.nvim_create_autocmd('ModeChanged', {
    group = group_id,
    pattern = '*',
    callback = function()
      local mode = api.nvim_get_mode().mode
      draw_mark(config, mode)
    end,
  })

  -- integration support for leap.nvim
  local s, leap = pcall(function()
    return require('leap')
  end, nil)
  if s then
    vim.api.nvim_create_autocmd('User', {
      pattern = { 'LeapEnter', 'LeapLeave' },
      callback = function(a)
        if a.match == 'LeapEnter' then
          draw_mark(config, leap.state.args.backward and 'leap_b' or 'leap_f')
        else
          api.nvim_buf_del_extmark(0, ns_id, extmark_id)
        end
      end,
    })
  end

  if config.sticky then
    api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
      group = group_id,
      pattern = '*',
      callback = function()
        local result = api.nvim_buf_get_extmark_by_id(
          0,
          ns_id,
          extmark_id,
          { details = true }
        )
        if not vim.tbl_isempty(result) then
          -- Only update the mode position when the extmark is shown
          local virt_text = result[3].virt_text[1]
          set_extmark({
            text = virt_text[1],
            hl = virt_text[2],
            offset = _offset,
            hl_mode = _hl_mode,
          })
        end
      end,
    })
  end

  if config.i_idle_to then
    api.nvim_create_autocmd({ 'CursorHoldI' }, {
      group = group_id,
      pattern = '*',
      callback = function()
        i_timer:start(config.i_idle_to - vim.o.updatetime, function()
          local mode = api.nvim_get_mode().mode
          if vim.tbl_contains(config.ignore, mode) then
            return
          end
          local data = get_mode_render(config.modes, mode)
          _offset = data.offset or config.offset
          _hl_mode = data.hl_mode or config.hl_mode
          set_extmark({
            text = data[1],
            hl = data[2],
            offset = _offset,
            hl_mode = _hl_mode,
          })
        end)
      end,
    })
    api.nvim_create_autocmd({ 'CursorMovedI' }, {
      group = group_id,
      pattern = '*',
      callback = function()
        -- if the main timer is running do not remove the mark
        if timer:is_active() then
          return
        end
        local result = api.nvim_buf_get_extmark_by_id(
          0,
          ns_id,
          extmark_id,
          { details = true }
        )
        if not vim.tbl_isempty(result) then
          i_timer:stop()
          api.nvim_buf_del_extmark(0, ns_id, extmark_id)
        end
      end,
    })
  end

  api.nvim_create_autocmd({ 'VimLeavePre' }, {
    group = group_id,
    pattern = '*',
    callback = function()
      timer:close()
      i_timer:close()
    end,
  })
end

return M
