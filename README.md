## monark.nvim

An extension for [leap.nvim](https://github.com/ggandor/leap.nvim)
that draws a mark next to the cursor in the direction of the jump.\
Enhances the visual feedback when leaping.

> [!NOTE]
> Support only forward and backward motions.

### Install

Use your plugin manager, eg. lazy.nvim

```lua
{
  'ggandor/leap.nvim',
  dependencies = {
    'doums/monark.nvim',
    opts = {},
  },
  opts = {
    -- your leap config
  },
}
```

### Configuration

The configuration is optional.\
Defaults are:

```lua
require('monark').setup({
  -- mark glyph, hl and position relative to cursor
  forward = { '❱', 'monarkLeap', position = 1 }, -- `s`
  backward = { '❰', 'monarkLeap', position = -1 }, -- `S`
})
```

### License

Mozilla Public License 2.0
