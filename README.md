## modeui.nvim

Show mode changes right next to the cursor.

### Motivations

In vim, the main thing we do is switch modes.
I like to have some sort of feedback when I switch modes,
especially when entering in insert mode.
I noticed that having to look at somewhere far from the cursor
position to check the current mode like at the very bottom
in a status bar, costs a little effort each time and could be
uncomfortable in a long run.

I could use the `guicursor` option but it does not play well with
the terminal I use, at least for the cursor color.

So I decided to make _modeui_. This small plugin just put
an extmark close to the cursor whenever you switch mode.
It's visual and right next to the main focused place: the cursor.
No need to look elsewhere.
Also the UI must be the least distracting. So I added a timeout
logic, to automatically hide the mark after a small amount of time.

### Install

Use your plugin manager

```lua
require('paq')({
  -- ...
  'doums/modeui.nvim',
})
```

### Configuration

The configuration is optional and can be partially overridden.

```lua
require('modeui').setup({
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
  offset = 2,
  -- Default timeout (ms) after which the mode mark will be removed.
  -- Note that it can be set individually for each mode
  -- (see below), in this case the individual timeout values take
  -- precedence
  timeout = 300,
  -- Text and highlight group map for each mode. Each mode
  -- table can takes a third item which is its specific timeout
  -- value
  map = {
    normal = { '⭘', 'modeuiNormal' },
    visual = { '◆', 'modeuiVisual' },
    v_block = { '■', 'modeuiVisual' },
    select = { '■', 'modeuiVisual' },
    insert = { '❱', 'modeuiInsert' },
    replace = { '❰', 'modeuiReplace' },
  },
  -- Background highlight mode (:h nvim_buf_set_extmark)
  hl_mode = 'combine',
  -- List of modes to ignore, items are those listed in `:h modes()`
  -- Default includes normal familly, visual/select by line, terminal,
  -- shell, command line and prompt
  ignore = { 'V' --...
  },
})
```

All default configuration values are listed
[here](https://github.com/doums/modeui.nvim/blob/main/lua/modeui/config.lua).

### License

Mozilla Public License 2.0
