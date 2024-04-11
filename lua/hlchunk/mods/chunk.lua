local BaseMod = require("hlchunk.base_mod")
local utils = require("hlchunk.utils.utils")
local ft = require("hlchunk.utils.filetype")
local api = vim.api
local fn = vim.fn
local CHUNK_RANGE_RET = utils.CHUNK_RANGE_RET

---@class ChunkOpts: BaseModOpts
---@field chars table<string, string>
---@field textobject string
---@field error_sign boolean

---@class ChunkMod: BaseMod
---@field options ChunkOpts
local chunk_mod = BaseMod:new({
    name = "chunk",
    options = {
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
        animate_duration = 200,
    },
})

-- chunk_mod can use text object, so add a new function extra to handle it
function chunk_mod:enable()
    if BaseMod.enable(self) then
        self:set_keymap()
    end
end

function chunk_mod:disable()
    if BaseMod.disable(self) then
        self:del_keymap()
    end
end

-- set new virtual text to the right place
function chunk_mod:render()
    if not self.is_enabled or self.options.exclude_filetypes[vim.bo.ft] then
        return
    end

    local retcode, cur_chunk_range = utils.get_chunk_range(self)
    local hl_group = self.options.hl_group.chunk
    if retcode == CHUNK_RANGE_RET.NO_CHUNK then
        self:clear()
        return
    elseif retcode == CHUNK_RANGE_RET.CHUNK_ERR then
        hl_group = self.options.hl_group.error
    end



    if #self.old_range > 1 and
        cur_chunk_range[1] == self.old_range[1] and
        cur_chunk_range[2] == self.old_range[2] then
        return
    end

    self:clear()
    self:refresh(cur_chunk_range)

    if cur_chunk_range[2] - cur_chunk_range[1] >= api.nvim_win_get_height(0) or
        require("nvim-treesitter.indent").get_indent(cur_chunk_range[1]) == 0 then
        chunk_mod:draw_by_direct(cur_chunk_range, hl_group)
    else
        chunk_mod:draw_by_animate(cur_chunk_range, hl_group)
    end
end

function chunk_mod:draw_by_direct(range, hl_group)
    local get_indent = require("nvim-treesitter.indent").get_indent
    local beg_row, end_row = unpack(range)
    local beg_blank_len = get_indent(beg_row)
    local end_blank_len = get_indent(end_row)
    local shiftwidth = fn.shiftwidth()
    local start_col = math.max(math.min(beg_blank_len, end_blank_len) - shiftwidth, 0)
    local offset = fn.winsaveview().leftcol
    local get_width = api.nvim_strwidth
    local row_opts = {
        virt_text_pos = "overlay",
        hl_mode = "combine",
        priority = 100,
    }

    -- render beg_row
    if beg_blank_len > 0 then
        local virt_text_len = beg_blank_len - start_col
        local beg_virt_text = self.options.chars.left_top .. self.options.chars.horizontal_line:rep(virt_text_len - 1)

        -- because the char is utf-8, so we need to get the utf-8 byte index
        if not utils.col_in_screen(start_col) then
            local byte_idx = math.min(offset - start_col, virt_text_len)
            if byte_idx > get_width(beg_virt_text) then
                byte_idx = get_width(beg_virt_text)
            end
            local utfBeg = vim.str_byteindex(beg_virt_text, byte_idx)
            beg_virt_text = beg_virt_text:sub(utfBeg + 1)
        end

        row_opts.virt_text = { { beg_virt_text, hl_group } }
        row_opts.virt_text_win_col = math.max(start_col - offset, 0)
        api.nvim_buf_set_extmark(0, self.ns_id, beg_row - 1, 0, row_opts)
    end

    -- render end_row
    if end_blank_len > 0 then
        local virt_text_len = end_blank_len - start_col
        local end_virt_text = self.options.chars.left_bottom
            .. self.options.chars.horizontal_line:rep(end_blank_len - start_col - 2)
            .. self.options.chars.right_arrow

        if not utils.col_in_screen(start_col) then
            local byte_idx = math.min(offset - start_col, virt_text_len)
            if byte_idx > get_width(end_virt_text) then
                byte_idx = get_width(end_virt_text)
            end
            local utfBeg = vim.str_byteindex(end_virt_text, byte_idx)
            end_virt_text = end_virt_text:sub(utfBeg + 1)
        end
        row_opts.virt_text = { { end_virt_text, hl_group } }
        row_opts.virt_text_win_col = math.max(start_col - offset, 0)
        api.nvim_buf_set_extmark(0, self.ns_id, end_row - 1, 0, row_opts)
    end

    -- render middle section
    for i = beg_row + 1, end_row - 1 do
        row_opts.virt_text = { { self.options.chars.vertical_line, hl_group } }
        row_opts.virt_text_win_col = start_col - offset
        local space_tab = (" "):rep(shiftwidth)
        local line_val = fn.getline(i):gsub("\t", space_tab)
        if #line_val <= start_col or fn.indent(i) > start_col then
            if utils.col_in_screen(start_col) then
                api.nvim_buf_set_extmark(0, self.ns_id, i - 1, 0, row_opts)
            end
        end
    end
end

function chunk_mod:draw_by_animate(range, hl_group)
    local get_indent = require("nvim-treesitter.indent").get_indent
    local beg_row, end_row = unpack(range)
    local beg_blank_len, end_blank_len = get_indent(beg_row), get_indent(end_row)
    local start_col = math.max(math.min(beg_blank_len, end_blank_len) - fn.shiftwidth(), 0)

    local opts = { virt_text = {}, offset = {}, line_num = {}, hl_group = hl_group, bufnr = self.bufnr }
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

    BaseMod.draw_by_animate(self, opts, end_range - start_range)
end

function chunk_mod:set_keymap()
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

function chunk_mod:del_keymap()
    local textobject = self.options.textobject
    if #textobject == 0 then
        return
    end
    vim.keymap.del({ "x", "o" }, textobject)
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
