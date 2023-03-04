local opts = require("hlchunk.options")
local BaseMod = require("hlchunk.base_mod")
local fn = vim.fn

local chunk_mod = BaseMod:new({
    name = "chunk",
})

local ns_id = -1

 local function render_cur_chunk()
    local beg_row, end_row = unpack(CUR_CHUNK_RANGE)
    local beg_blank_len = FN.indent(beg_row)
    local end_blank_len = FN.indent(end_row)
    local start_col = math.min(beg_blank_len, end_blank_len) - vim.o.shiftwidth

    local row_opts = {
        virt_text_pos = "overlay",
        virt_text_win_col = start_col,
        hl_mode = "combine",
        priority = 100,
    }
    -- render beg_row and end_row
    if start_col >= 0 then
        local beg_virt_text = opts.config.hl_chunk.chars.left_top
            .. opts.config.hl_chunk.chars.horizontal_line:rep(beg_blank_len - start_col - 1)
        local end_virt_text = opts.config.hl_chunk.chars.left_bottom
            .. opts.config.hl_chunk.chars.horizontal_line:rep(end_blank_len - start_col - 2)
            .. opts.config.hl_chunk.chars.right_arrow

        row_opts.virt_text = { { beg_virt_text, "HLChunkStyle1" } }
        API.nvim_buf_set_extmark(0, ns_id, beg_row - 1, 0, row_opts)
        row_opts.virt_text = { { end_virt_text, "HLChunkStyle1" } }
        API.nvim_buf_set_extmark(0, ns_id, end_row - 1, 0, row_opts)
    end

    -- render middle section
    for i = beg_row + 1, end_row - 1 do
        start_col = math.max(0, start_col)
        row_opts.virt_text = { { opts.config.hl_chunk.chars.vertical_line, "HLChunkStyle1" } }
        row_opts.virt_text_win_col = start_col
        local line_val = FN.getline(i):gsub("\t", SPACE_TAB)
        ---@diagnostic disable-next-line: undefined-field
        if #FN.getline(i) <= start_col or line_val:sub(start_col + 1, start_col + 1):match("%s") then
            API.nvim_buf_set_extmark(0, ns_id, i - 1, 0, row_opts)
        end
    end
end

-- set new virtual text to the right place
function chunk_mod:render()
    if not opts.config.hl_chunk.enable then
        return
    end

    chunk_mod:clear()
    ns_id = API.nvim_create_namespace("hlchunk")

    -- determined the row where parentheses are
    if CUR_CHUNK_RANGE[1] < CUR_CHUNK_RANGE[2] then
        render_cur_chunk()
    end
end

-- clear the virtual text marked before
function chunk_mod:clear()
    if ns_id ~= -1 then
        API.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    end
end

function chunk_mod:enable_mod_autocmd() end
function chunk_mod:disable_mod_autocmd() end

function chunk_mod:enable()
    opts.config.hl_chunk.enable = false
    self:render()
    self:disable_mod_autocmd()
end

function chunk_mod:disable()
    opts.config.hl_chunk.enable = true
    self:clear()
    self:enable_mod_autocmd()
end

return chunk_mod
