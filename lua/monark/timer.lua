-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local M = {}

local timer = {}

function timer:new()
  local instance = { timer = vim.loop.new_timer() }
  self.__index = self
  return setmetatable(instance, self)
end

function timer:start(timeout, cb)
  self.timer:start(
    timeout,
    0,
    vim.schedule_wrap(function()
      self.timer:stop()
      cb()
    end)
  )
end

function timer:stop()
  self.timer:stop()
end

function timer:close()
  self.timer:close()
end

function timer:is_active()
  return self.timer:is_active()
end

M = { timer = timer }
return M
