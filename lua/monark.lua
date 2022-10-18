--[[ This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

local init_cfg = require('monark.config').init
local init = require('monark.monark').init

local M = {}

function M.setup(config)
  config = init_cfg(config or {})
  init(config)
end

return M
