local api = vim.api
local M = {}
M.duration = 500
M.timer = vim.loop.new_timer()

---@param ns_id? number
---@param opts?  table
---@param len?   number
function M.start_draw(ns_id, opts, len)
    opts = opts or {}

    M.index = 1

    local interval = math.floor(M.duration / len)
    local prev_opt = nil
    local prev_line = 0
    M.timer:start(interval, interval, vim.schedule_wrap(function()
        local row_opts = {
            virt_text_pos = "overlay",
            hl_mode = "combine",
            priority = 100,
        }

        row_opts.virt_text = { { opts.virt_text[M.index][1], opts.hl_group } }
        row_opts.virt_text_win_col = opts.offset[M.index]
        local id = api.nvim_buf_set_extmark(opts.bufnr, ns_id, opts.line_num[M.index] - 1, 0, row_opts)

        if prev_opt then
            api.nvim_buf_set_extmark(opts.bufnr, ns_id, prev_opt.line_num, 0, prev_opt)
        end
        prev_line = opts.line_num[M.index] - 1
        prev_opt = row_opts
        prev_opt.line_num = opts.line_num[M.index] - 1
        prev_opt.id = id
        prev_opt.virt_text = { { opts.virt_text[M.index][2], opts.hl_group } }

        M.index = M.index + 1
        -- Stop running if the len is exceeded
        if M.index == len then
            M.timer:stop()
        end
    end))
end

return M
