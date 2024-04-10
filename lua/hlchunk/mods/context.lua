local BaseMod = require("hlchunk.base_mod")
local utils = require("hlchunk.utils.utils")
local ft = require("hlchunk.utils.filetype")
local api = vim.api
local fn = vim.fn

---@class ContextOpts: BaseModOpts
---@field chars table<string, string>
---@field textobject string
---
---@class ContextMod: BaseMod
---@field options ContextOpts
local context_mod = BaseMod:new({
    name = "context",
    options = {
        enable = false,
        notify = true,
        chars = {
            "│",
        },
        hl_group = {
            context = "LineNr",
        },
        exclude_filetypes = ft.exclude_filetypes,
        textobject = "ih",
    },
})

-- chunk_mod can use text object, so add a new function extra to handle it
function context_mod:enable()
    BaseMod.enable(self)
    self:extra()
    self:set_hl()
end

function context_mod:render()
    if (not self.options.enable) or self.options.exclude_filetypes[vim.bo.filetype] then
        return
    end

    self:clear()
    self.ns_id = api.nvim_create_namespace(self.name)

    local ctx_range = utils.get_ctx_range(self)
    if not ctx_range then
        return
    end
    local ctx_col, beg_row, end_row = unpack(ctx_range)

    local shiftwidth = fn.shiftwidth()
    local row_opts = {
        virt_text_pos = "overlay",
        virt_text_win_col = ctx_col,
        hl_mode = "combine",
        priority = 99,
    }

    -- render middle section
    local offset = fn.winsaveview().leftcol
    for i = beg_row, end_row do
        row_opts.virt_text = { { self.options.chars[1], self.options.hl_group.context } }
        row_opts.virt_text_win_col = ctx_col - offset
        local space_tab = (" "):rep(shiftwidth)
        local line_val = fn.getline(i):gsub("\t", space_tab)
        if #fn.getline(i) <= ctx_col or line_val:sub(ctx_col + 1, ctx_col + 1):match("%s") then
            if utils.col_in_screen(ctx_col) then
                api.nvim_buf_set_extmark(0, self.ns_id, i - 1, 0, row_opts)
            end
        end
    end
end

function context_mod:enable_mod_autocmd()
    BaseMod.enable_mod_autocmd(self)

    api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = self.augroup_name,
        pattern = "*",
        callback = function()
            context_mod:render()
        end,
    })

    return

        api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
            group = self.augroup_name,
            pattern = "*",
            callback = function()
                context_mod:render()
            end,
        })
end

function context_mod:extra()
    local textobject = self.options.textobject
    if #textobject == 0 then
        return
    end
    vim.keymap.set({ "x", "o" }, textobject, function()
        local cur_ctx_range = utils.get_ctx_range(self)
        if not cur_ctx_range then
            return
        end

        local _, s_row, e_row = unpack(cur_ctx_range)
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

function context_mod:set_hl()
    if string.sub(self.options.hl_group.context, 1, 1) == "#" then
        local fg = self.options.hl_group.context
        self.options.hl_group.context = "HLChunkContext"
        api.nvim_set_hl(0, self.options.hl_group.context, { fg = fg })
    end
end

return context_mod
