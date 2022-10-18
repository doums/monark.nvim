## monark.nvim

Show mode changes right next to the cursor.

### Motivations

In vim, the main thing we do is switch modes.
I like to have some sort of feedback when I switch modes,
especially when entering in insert mode.
I noticed that having to look away from the cursor location
to get current mode feedback, then focus back on cursor, like at
the very bottom in a status bar, costs a little effort each time
and could be uncomfortable in a long run.

I could use the `guicursor` option but it does not play well with
the terminal I use, at least for the cursor color.

So I decided to make _monark_. This small plugin just draws an
extmark representing the current mode, right next to the cursor,
whenever you switch mode.
It's visual and in a central place, the main focused area.
It prevents the eyestrain from having to look away and focus back.
Also the UI must be the least distracting. So I added a timeout
logic, to automatically hide the mark after a small amount of time.

### Install

Use your plugin manager

```lua
require('paq')({
  -- ...
  'doums/monark.nvim',
})
```

### Configuration

The configuration is optional and can be partially overridden.

```lua
require('monark').setup({
  -- Remove instantly the mode mark when switching to `normal`
  -- mode, don't wait for timeout (should only be used when
  -- ignoring normal modes)
  clear_on_normal = true,
  -- Enable or not sticky mode. In sticky mode, the mode mark will
  -- move along with the cursor
  sticky = true,
  -- Default mark offset relative to the cursor position. A
  -- negative number will draw the mark to the left of the cursor,
  -- a positive number to the right, 0 on top of it
  -- It can be set by mode (see below), if set the specific
  -- offset take precedence
  offset = 1,
  -- Default timeout (ms) after which the mode mark will be removed.
  -- It can be set by mode (see below), if set the specific
  -- timeout take precedence
  timeout = 300,
  -- Modes settings. Each mode have a dedicated table to customize
  -- its mark.
  -- The first item is the text, the second item is the highlight
  -- group.
  -- A specific timeout can be set using the `timeout` key.
  -- A specific offset can be set using the `offset` key.
  -- A specific hl_mode can be set using the `hl_mode` key.
  -- eg. insert = { '❱', 'monarkInsert', offset = -1, timeout = 200 }
  modes = {
    normal = { '⭘', 'monarkNormal' },
    visual = { '◆', 'monarkVisual' },
    visual_l = { '━', 'monarkVisual' },
    visual_b = { '■', 'monarkVisual' },
    select = { '■', 'monarkVisual' },
    insert = { '❱', 'monarkInsert' },
    replace = { '❰', 'monarkReplace' },
    terminal = { '❯', 'monarkInsert' },
  },
  -- Background highlight mode (:h nvim_buf_set_extmark)
  -- It can be set by mode (see above)
  hl_mode = 'combine',
  -- List of modes to ignore, items are those listed in `:h modes()`
  -- Includes normal familly, visual/select by line, terminal,
  -- shell, command line and prompt
  ignore = { 'V' --...
  },
})
```

All default configuration values are listed
[here](https://github.com/doums/monark.nvim/blob/main/lua/monark/config.lua).

### License

Mozilla Public License 2.0
