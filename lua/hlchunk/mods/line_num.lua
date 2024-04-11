local BaseMod = require("hlchunk.base_mod")
local utils = require("hlchunk.utils.utils")
local ft = require("hlchunk.utils.filetype")
local api = vim.api
local fn = vim.fn
local CHUNK_RANGE_RET = utils.CHUNK_RANGE_RET

---@class LineNumOpts: BaseModOpts

---@class LineNumMod: BaseMod
---@field options LineNumOpts
local line_num_mod = BaseMod:new({
    name = "line_num",
    options = {
        notify = true,
        hl_group = {
            chunk = "CursorLineNr",
            context = "LineNr",
            error = "Error",
        },
        support_filetypes = ft.support_filetypes,
        exclude_filetypes = ft.exclude_filetypes,
    },
})

function line_num_mod:render()
    if not self.is_enabled or self.options.exclude_filetypes[vim.bo.ft] then
        return
    end

    self:clear()
    self:refresh()

    local retcode, chunk_range = utils.get_chunk_range(self)
    local hl_chunk
    if retcode == CHUNK_RANGE_RET.OK then
        hl_chunk = self.options.hl_group.chunk
    elseif retcode == CHUNK_RANGE_RET.CHUNK_ERR then
        hl_chunk = self.options.hl_group.error
    end

    if hl_chunk then
        local beg_row, end_row = unpack(chunk_range)
        for i = beg_row, end_row do
            local row_opts = {}
            row_opts.number_hl_group = hl_chunk
            api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i - 1, 0, row_opts)
        end
    end

    local ctx_range = utils.get_ctx_range(self)
    if ctx_range then
        local _, beg_row, end_row = unpack(ctx_range)
        for i = beg_row, end_row do
            local row_opts = {}
            row_opts.number_hl_group = self.options.hl_group.context
            api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i - 1, 0, row_opts)
        end
    end
end

function line_num_mod:set_hl()
    if string.sub(self.options.hl_group.chunk, 1, 1) == '#' then
        local fg = self.options.hl_group.chunk
        self.options.hl_group.chunk = "HLChunkLineNumChunk"
        api.nvim_set_hl(0, self.options.hl_group.chunk, { fg = fg })
    end
    if string.sub(self.options.hl_group.context, 1, 1) == '#' then
        local fg = self.options.hl_group.context
        self.options.hl_group.context = "HLChunkLineNumContext"
        api.nvim_set_hl(0, self.options.hl_group.context, { fg = fg })
    end
    if string.sub(self.options.hl_group.error, 1, 1) == '#' then
        local fg = self.options.hl_group.error
        self.options.hl_group.error = "HLChunkLineNumError"
        api.nvim_set_hl(0, self.options.hl_group.error, { fg = fg })
    end
end

return line_num_mod
