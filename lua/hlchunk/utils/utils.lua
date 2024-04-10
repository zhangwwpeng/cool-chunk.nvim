local ft = require("hlchunk.utils.ts_node_type")
local fn = vim.fn
local treesitter = vim.treesitter

local function is_suit_type(node_type)
    local suit_types = ft[vim.bo.ft]
    if suit_types then
        return suit_types[node_type] and true or false
    end

    for _, rgx in ipairs(ft.default) do
        if node_type:find(rgx) then
            return true
        end
    end
    return false
end

-- this is utils module for hlchunk every mod
-- every method in this module should pass arguments as follow
-- 1. mod: BaseMod, for utils function to get mod options
-- 2. normal arguments
-- 3. opts: for utils function to get options specific for this function
-- every method in this module should return as follow
-- 1. return ret code, a enum value
-- 2. return ret value, a table or other something
local M = {}

---@enum CHUNK_RANGE_RETCODE
M.CHUNK_RANGE_RET = {
    OK = 0,
    CHUNK_ERR = 1,
    NO_CHUNK = 2,
}

---@param mod BaseMod
---@return CHUNK_RANGE_RETCODE enum
---@return table<number, number>
---@diagnostic disable-next-line: unused-local
function M.get_chunk_range(mod)
    local cursor_node = treesitter.get_node()
    while cursor_node do
        local node_type = cursor_node:type()
        local node_start, _, node_end, _ = cursor_node:range()
        if node_start ~= node_end and is_suit_type(node_type) then
            return cursor_node:has_error() and M.CHUNK_RANGE_RET.CHUNK_ERR or M.CHUNK_RANGE_RET.OK,
                {
                    node_start + 1,
                    node_end + 1,
                }
        end
        cursor_node = cursor_node:parent()
    end
    return M.CHUNK_RANGE_RET.NO_CHUNK, {}
end

---@param mod BaseMod
---@return table<number, number> | nil not include end point
function M.get_ctx_range(mod)
    local get_indent = require("nvim-treesitter.indent").get_indent
    local cur_line = fn.line(".")
    local cur_indent = get_indent(cur_line)

    if cur_indent < fn.shiftwidth() or
        cur_line == 1 or
        cur_line == fn.line("$") then
        return nil
    end

    local ctx_indent = 0
    local pre_indent, next_indent = get_indent(cur_line - 1), get_indent(cur_line + 1)
    local extend_up, extend_down = false, false
    if next_indent == cur_indent then
        if pre_indent < cur_indent then
            ctx_indent = cur_indent - fn.shiftwidth()
            extend_down = true
        elseif pre_indent == cur_indent then
            ctx_indent = cur_indent - fn.shiftwidth()
            extend_up = true
            extend_down = true
        else
            extend_up = true
            ctx_indent = cur_indent
        end
    elseif pre_indent == cur_indent then
        if next_indent < cur_indent then
            ctx_indent = cur_indent - fn.shiftwidth()
            extend_up = true
        else
            extend_down = true
            ctx_indent = cur_indent
        end
    elseif pre_indent < cur_indent and cur_indent < next_indent then
        ctx_indent = cur_indent
        extend_down = true
    elseif pre_indent > cur_indent and cur_indent > next_indent then
        extend_up = true
        ctx_indent = cur_indent
    elseif pre_indent < cur_indent and next_indent < cur_indent then
        ctx_indent = cur_indent - fn.shiftwidth()
    elseif pre_indent > cur_indent and next_indent > cur_indent then
        ctx_indent = cur_indent
        extend_up = true
    end

    local beg_line, end_line = cur_line, cur_line
    if extend_up then
        for i = cur_line - 1, 1, -1 do
            if get_indent(i) == ctx_indent then
                beg_line = i + 1
                break
            end
        end
    else
        if ctx_indent ~= cur_indent then
            beg_line = cur_line
        else
            beg_line = cur_line + 1
        end
    end

    if extend_down then
        for i = cur_line + 1, fn.line("$"), 1 do
            if get_indent(i) == ctx_indent then
                end_line = i - 1
                break
            end
        end
    else
        if ctx_indent ~= cur_indent then
            end_line = cur_line
        else
            end_line = cur_line - 1
        end
    end

    return { ctx_indent, beg_line, end_line }
end

---@param col number the column number
---@return boolean
function M.col_in_screen(col)
    local leftcol = vim.fn.winsaveview().leftcol
    return col >= leftcol
end

return M
