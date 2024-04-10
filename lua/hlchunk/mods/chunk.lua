local BaseMod = require("hlchunk.base_mod")
local utils = require("hlchunk.utils.utils")
local ft = require("hlchunk.utils.filetype")
local api = vim.api
local fn = vim.fn
local timer = require("hlchunk.utils.timer")
local CHUNK_RANGE_RET = utils.CHUNK_RANGE_RET

---@class ChunkOpts: BaseModOpts
---@field chars table<string, string>
---@field textobject string
---@field error_sign boolean

---@class ChunkMod: BaseMod
---@field old_chunk_range table<number, number>
---@field options ChunkOpts
local chunk_mod = BaseMod:new({
    name = "chunk",
    old_chunk_range = { 1, 1 },
    options = {
        enable = true,
        notify = true,
        support_filetypes = ft.support_filetypes,
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
        error_sign = true,
    },
})

-- chunk_mod can use text object, so add a new function extra to handle it
function chunk_mod:enable()
    BaseMod.enable(self)
    self:extra()
end

-- set new virtual text to the right place
function chunk_mod:render()
    if not self.options.enable or self.options.exclude_filetypes[vim.bo.ft] then
        return
    end

    local retcode, cur_chunk_range = utils.get_chunk_range(self)
    local hl_group = self.options.hl_group.chunk
    if retcode == CHUNK_RANGE_RET.NO_CHUNK then
        self:clear()
        self.old_chunk_range = { 1, 1 }
        return
    elseif retcode == CHUNK_RANGE_RET.CHUNK_ERR then
        hl_group = self.options.hl_group.error
    end

    if cur_chunk_range[1] == self.old_chunk_range[1] and
        cur_chunk_range[2] == self.old_chunk_range[2] then
        return
    end

    self.old_chunk_range = cur_chunk_range

    local get_indent = require("nvim-treesitter.indent").get_indent

    self.ns_id = api.nvim_create_namespace(self.name)

    local beg_row, end_row = unpack(cur_chunk_range)

    local beg_blank_len, end_blank_len = get_indent(beg_row), get_indent(end_row)
    local start_col = math.max(math.min(beg_blank_len, end_blank_len) - fn.shiftwidth(), 0)

    self:clear()

    local opts = { virt_text = {}, offset = {}, line_num = {}, hl_group = hl_group }
    local start_range = beg_row - beg_blank_len + start_col
    local end_range = end_row + end_blank_len - start_col

    for i = start_range + 1, end_range - 1, 1 do
        local virt_text = self.options.chars["vertical_line"]
        local arrow_text = self.options.chars["bottom_arrow"]
        local line_num = i
        local offset = start_col - fn.winsaveview().leftcol

        if beg_row == i then
            virt_text = self.options.chars["left_top"]
            arrow_text = self.options.chars["left_arrow"]
        elseif beg_row > i then
            virt_text = self.options.chars["horizontal_line"]
            offset, line_num = offset - (i - beg_row), beg_row
            arrow_text = self.options.chars["left_arrow"]
        elseif end_row < i then
            virt_text = self.options.chars["horizontal_line"]
            arrow_text = self.options.chars["right_arrow"]
            offset, line_num = offset + (i - end_row), end_row
        elseif end_row == i then
            virt_text = self.options.chars["left_bottom"]
        end
        opts.virt_text[i - start_range] = { arrow_text, virt_text }
        opts.offset[i - start_range] = offset
        opts.line_num[i - start_range] = line_num
    end

    timer.start_draw(self.ns_id, opts, end_range - start_range)
end

function chunk_mod:enable_mod_autocmd()
    BaseMod.enable_mod_autocmd(self)

    api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = self.augroup_name,
        pattern = self.options.support_filetypes,
        callback = function()
            chunk_mod:render()
        end,
    })

    return

        api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
            group = self.augroup_name,
            pattern = self.options.support_filetypes,
            callback = function()
                chunk_mod:render()
            end,
        })
end

function chunk_mod:extra()
    local textobject = self.options.textobject
    if #textobject == 0 then
        return
    end
    vim.keymap.set({ "x", "o" }, textobject, function()
        local retcode, cur_chunk_range = utils.get_chunk_range(self)
        if retcode ~= CHUNK_RANGE_RET.OK then
            return
        end
        local s_row, e_row = unpack(cur_chunk_range)
        local ctrl_v = api.nvim_replace_termcodes("<C-v>", true, true, true)
        local cur_mode = vim.fn.mode()
        if cur_mode == "v" or cur_mode == "V" or cur_mode == ctrl_v then
            vim.cmd("normal! " .. cur_mode)
        end

        api.nvim_win_set_cursor(0, { s_row, 0 })
        vim.cmd("normal! V")
        api.nvim_win_set_cursor(0, { e_row, 0 })
    end)
end

function chunk_mod:set_hl()
    if string.sub(self.options.hl_group.chunk, 1, 1) == "#" then
        local fg = self.options.hl_group.chunk
        self.options.hl_group.chunk = "HLChunkChunkChunk"
        api.nvim_set_hl(0, self.options.hl_group.chunk, { fg = fg })
    end
    if string.sub(self.options.hl_group.error, 1, 1) == "#" then
        local fg = self.options.hl_group.error
        self.options.hl_group.error = "HLChunkChunkError"
        api.nvim_set_hl(0, self.options.hl_group.error, { fg = fg })
    end
end

return chunk_mod
