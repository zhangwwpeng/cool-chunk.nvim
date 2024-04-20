## What can this plugin do

forked from [hlchunk](https://github.com/shellRaining/hlchunk.nvim). removed indent(if you wnat to used it, recommend [indent-blankline](https://github.com/lukas-reineke/indent-blankline.nvim)), keep chunk and context and line_num. simple and faster and cool.

## Show Gif

![Screencasts](https://github.com/Mr-LLLLL/media/blob/master/cool-chunk/cool-chunk.gif)

## Brief introduction

this plugin now have three parts

1. chunk
2. line_num
3. context

## Requirements

neovim version `>= 0.9.0`

## Installation

### With [Lazy](https://github.com/fork/lazy.nvim)

```lua
{
  "Mr-LLLLL/cool-chunk.nvim",
  event = { "CursorHold", "CursorHoldI" },
  config = function()
    require("cool-chunk").setup({})
  end
},
```

## Setup

The script comes with the following defaults:

<details>
<summary>Click this Dropdown to see defaults setttings.</summary>

```lua
{
    chunk = {
        notify = true,
        support_filetypes = ft.support_filetypes, -- ft = require("cool-chunk.utils.filetype").support_filetypes
        exclude_filetypes = ft.exclude_filetypes,
        hl_group = {
            chunk = "CursorLineNr",
            error = "Error",
        },
        chars = {
            horizontal_line = "─",
            vertical_line = "│",
            left_top = "╭",
            left_bottom = "╰",
            left_arrow = "<",
            bottom_arrow = "v",
            right_arrow = ">",
        },
        textobject = "ah",
        animate_duration = 200,
        fire_event = { "CursorHold", "CursorHoldI" },
    },
    context = {
        notify = true,
        chars = {
            "│",
        },
        hl_group = {
            context = "LineNr",
        },
        exclude_filetypes = ft.exclude_filetypes,
        support_filetypes = ft.support_filetypes,
        textobject = "ih",
        jump_support_filetypes = { "lua", "python" },
        jump_start = "[{",
        jump_end = "]}",
        fire_event = { "CursorHold", "CursorHoldI" },
    },
    line_num = {
        notify = true,
        hl_group = {
            chunk = "CursorLineNr",
            context = "LineNr",
            error = "Error",
        },
        support_filetypes = ft.support_filetypes,
        exclude_filetypes = ft.exclude_filetypes,
        fire_event = { "CursorHold", "CursorHoldI" },
    }
}
```

<hr>

</details>

<hr>

## command

<details>
<summary>Click this Dropdown to see Available Commands</summary>

this plugin provides some commands to switch plugin status, which are listed below

- EnableCC
- DisableCC
- EnableCCChunk
- DisableCCChunk
- EnableCCContext
- DisableCCContext
- EnableCCLineNum
- DisableCCLineNum

</details>
