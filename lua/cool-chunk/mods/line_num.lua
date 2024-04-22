local BaseMod = require("cool-chunk.base_mod")
local Array = require("cool-chunk.utils.array")
local utils = require("cool-chunk.utils.utils")
local ft = require("cool-chunk.utils.filetype")
local api = vim.api
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
        fire_event = { "CursorHold", "CursorHoldI" },
    },
})

function line_num_mod:render()
    if not self.is_enabled or self.options.exclude_filetypes[vim.bo.ft] then
        return
    end

    local opts = {}
    local retcode, chunk_range = utils.get_chunk_range(self)
    local hl_chunk
    local overlap = {}
    if retcode == CHUNK_RANGE_RET.OK then
        hl_chunk = self.options.hl_group.chunk
    elseif retcode == CHUNK_RANGE_RET.CHUNK_ERR then
        hl_chunk = self.options.hl_group.error
    end

    if hl_chunk then
        if #self.old_chunk_range > 1 and
            chunk_range[1] == self.old_chunk_range[1] and
            chunk_range[2] == self.old_chunk_range[2] then
            return
        end
        opts.old_chunk_range = chunk_range
    end

    local ctx_range = utils.get_ctx_range(self)
    if ctx_range then
        if #self.old_ctx_range > 1 and
            ctx_range[2] == self.old_ctx_range[1] and
            ctx_range[3] == self.old_ctx_range[2] then
            return
        end
        opts.old_ctx_range = { ctx_range[2], ctx_range[3] }
    end

    self:clear()
    self:refresh(opts)

    if opts.old_chunk_range then
        for i = chunk_range[1], chunk_range[2] do
            local row_opts = {
                number_hl_group = hl_chunk
            }
            overlap[i] = api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i - 1, 0, row_opts)
        end
    end

    if opts.old_ctx_range then
        ---@diagnostic disable-next-line: need-check-nil
        for i = ctx_range[2], ctx_range[3] do
            local row_opts = {
                number_hl_group = self.options.hl_group.context,
                id = overlap[i]
            }
            api.nvim_buf_set_extmark(self.bufnr, self.ns_id, i - 1, 0, row_opts)
        end
    end
end

function line_num_mod:set_hl()
    local token_array = Array:from(self.name:split("_"))
    local mod_name = token_array
        :map(function(value)
            return value:firstToUpper()
        end)
        :join()
    if string.sub(self.options.hl_group.chunk, 1, 1) == '#' then
        local fg = self.options.hl_group.chunk
        self.options.hl_group.chunk = BaseMod.name .. mod_name .. "Chunk"
        api.nvim_set_hl(0, self.options.hl_group.chunk, { fg = fg })
    end
    if string.sub(self.options.hl_group.context, 1, 1) == '#' then
        local fg = self.options.hl_group.context
        self.options.hl_group.chunk = BaseMod.name .. mod_name .. "Context"
        api.nvim_set_hl(0, self.options.hl_group.context, { fg = fg })
    end
    if string.sub(self.options.hl_group.error, 1, 1) == '#' then
        local fg = self.options.hl_group.error
        self.options.hl_group.chunk = BaseMod.name .. mod_name .. "Error"
        api.nvim_set_hl(0, self.options.hl_group.error, { fg = fg })
    end
end

return line_num_mod
