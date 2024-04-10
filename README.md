<div align='center'>
<p><img width='400px' src='https://raw.githubusercontent.com/shellRaining/img/main/2305/01_logo_bg.png'></p>
</div>
<h1 align='center'>hlchunk.nvim</h1>

## What can this plugin do

similar to [indent-blankline](https://github.com/lukas-reineke/indent-blankline.nvim), this plugin can highlight the indent line, and highlight the code chunk according to the current cursor position.

## What is the advantage of this plugin

1. more extensible
2. faster rendering speed (0.04 seconds per thousand renderings, with the window have 50 lines)
3. more active maintenance (the author is a student with a lot of time to maintain this plugin, haha)

## Brief introduction

this plugin now have five parts (future will add more... `^v^`)

1. chunk
2. line_num
3. context

one picture to understand what these mods do

<img width='500' src='https://raw.githubusercontent.com/shellRaining/img/main/2305/01_intro.png'>

## more details about each mod

<b><font color='red'> NOTE: you can click the picture to get more information about how to configure like this </font></b>

### chunk

<a href='./docs/en/chunk.md#chunk_example1'>
<img width="500" alt="image" src="https://raw.githubusercontent.com/shellRaining/img/main/2303/08_hlchunk8.gif">
</a>

### line_num

<a href='./docs/en/line_num.md'>
<img width="500" alt="image" src="https://raw.githubusercontent.com/shellRaining/img/main/2302/25_hlchunk3.png">
</a>

## Requirements

neovim version `>= 0.9.0`

## Installation

### Packer

```lua
use { "shellRaining/hlchunk.nvim" }
```

### Plug

```vimscript
call plug#begin()
Plug 'shellRaining/hlchunk.nvim'
call plug#end()

lua << EOF
require("hlchunk").setup({})
EOF
```

### Lazy

```lua
{
  "shellRaining/hlchunk.nvim",
  event = { "UIEnter" },
  config = function()
    require("hlchunk").setup({})
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
        enable = true,
        notify = true,
        -- details about support_filetypes and exclude_filetypes in https://github.com/shellRaining/hlchunk.nvim/blob/main/lua/hlchunk/utils/filetype.lua
        support_filetypes = ft.support_filetypes,
        exclude_filetypes = ft.exclude_filetypes,
        chars = {
            horizontal_line = "─",
            vertical_line = "│",
            left_top = "╭",
            left_bottom = "╰",
            right_arrow = ">",
        },
        style = {
            { fg = "#806d9c" },
            { fg = "#c21f30" }, -- this fg is used to highlight wrong chunk
        },
        textobject = "",
        error_sign = true,
    },

    line_num = {
        enable = true,
        -- if hlchunk make your neovim slowly, set this option to true and try again
        in_performance = false,
        style = "#806d9c",
    },
}
```

<hr>

</details>

<hr>

setup example:

```lua
require('hlchunk').setup({
    chunk = {
        enable = true,
        notify = true,
        chars = {
            horizontal_line = "─",
            vertical_line = "│",
            left_top = "╭",
            left_bottom = "╰",
            right_arrow = ">",
        },
        style = {
            { fg = "#806d9c" },
            { fg = "#c21f30" }, -- this fg is used to highlight wrong chunk
        },
        textobject = "",
        error_sign = true,
    },

    line_num = {
        enable = true,
        -- if hlchunk make your neovim slowly, set this option to true and try again
        in_performance = false,
        style = "#806d9c",
    },
})
```

## command

<details>
<summary>Click this Dropdown to see Available Commands</summary>

this plugin provides some commands to switch plugin status, which are listed below

- EnableHL
- DisableHL

the two commands are used to switch the whole plugin status, when use `DisableHL`, include `hl_chunk` and `hl_indent` will be disable

- DisableHLChunk
- EnableHLChunk

the two will control `hl_chunk`

- DisableHLLineNum
- EnableHLLineNum

the two will control `hl_line_num`

</details>
