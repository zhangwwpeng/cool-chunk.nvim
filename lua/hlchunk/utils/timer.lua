local api = vim.api
local M = {}
-- TODO: Add it later to the options
M.sleep = 15

---@param ns_id? number
---@param opts?  table
---@param len?   number
function M.start_draw(ns_id, opts, len)
    opts = opts or {}

    -- TODO: Stop the previous timer and want to implement multiple timers running
    M:stop_draw()
    M.timer = vim.loop.new_timer()
    -- Record the number of symbols
    M.index = 1

    local prev_opt = nil
    local prev_line = 0
    M.timer:start(M.sleep, M.sleep, vim.schedule_wrap(function()
        local row_opts = {
            virt_text_pos = "overlay",
            hl_mode = "combine",
            priority = 100,
        }

        row_opts.virt_text = { { opts.virt_text[M.index][1], opts.hl_group } }
        row_opts.virt_text_win_col = opts.offset[M.index]
        local id = api.nvim_buf_set_extmark(0, ns_id, opts.line_num[M.index] - 1, 0, row_opts)

        if prev_opt then
            api.nvim_buf_set_extmark(0, ns_id, prev_line, 0, prev_opt)
        end
        prev_line = opts.line_num[M.index] - 1
        prev_opt = row_opts
        prev_opt.id = id
        prev_opt = vim.deepcopy(row_opts)
        prev_opt.virt_text = { { opts.virt_text[M.index][2], opts.hl_group } }

        M.index = M.index + 1
        -- Stop running if the len is exceeded
        if M.index == len then
            M:stop_draw()
        end
    end))
end

function M.stop_draw()
    if M.timer ~= nil then
        M.timer:close()
        M.timer = nil
    end
end

return M
