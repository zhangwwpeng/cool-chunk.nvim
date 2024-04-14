local ft = require("hlchunk.utils.ts_node_type")
local api = vim.api
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
---@param jump boolean is jump to context
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

function M.get_ctx_jump(mod)
    local cur_row, cur_col = unpack(api.nvim_win_get_cursor(0))
    local get_indent = require("nvim-treesitter.indent").get_indent
    local cur_indent = get_indent(cur_row)
    local cur_node = treesitter.get_node()
    while cur_node do
        local start_row, start_col, end_row, end_col = cur_node:range()
        local start_indent = get_indent(start_row + 1)
        local end_indent = get_indent(end_row + 1)
        if start_row == end_row then
            goto continue
        end

        if start_indent <= end_indent then
            if cur_indent > start_indent then
                goto ret
            elseif cur_node:type() == "block" then
                goto continue
            elseif (cur_row == start_row + 1 or cur_row == end_row + 1) or
                cur_node:type() == "if_statement" then
                goto ret
            else
                goto continue
            end

            ::ret::
            if cur_row == start_row + 1 and cur_col == start_col or
                cur_row == end_row + 1 and cur_col == end_col - 1 then
                goto continue
            end

            return { start_row + 1, start_col + 1, end_row + 1, end_col }
        end

        ::continue::
        cur_node = cur_node:parent()
    end
end

---@param mod BaseMod
---@return table<number, number> | nil not include end point
function M.get_ctx_range(mod)
    local cur_row, _ = unpack(api.nvim_win_get_cursor(0))
    local get_indent = require("nvim-treesitter.indent").get_indent
    local cur_indent = get_indent(cur_row)
    local cur_node = treesitter.get_node()
    while cur_node do
        local start_row, _, end_row, _ = cur_node:range()
        local start_indent = get_indent(start_row + 1)
        local end_indent = get_indent(end_row + 1)
        local res = { start_indent, start_row + 2, end_row }
        if start_row == end_row then
            goto continue
        end

        if start_indent < end_indent then
            res = { start_indent, start_row + 2, end_row + 1 }
        end
        if start_indent <= end_indent then
            if cur_indent > start_indent then
                return res
            elseif cur_node:type() == "block" then
                goto continue
            elseif (cur_row == start_row + 1 or cur_row == end_row + 1) or
                cur_node:type() == "if_statement" then
                return res
            end
        end

        ::continue::
        cur_node = cur_node:parent()
    end
end

---@param col number the column number
---@return boolean
function M.col_in_screen(col)
    local leftcol = vim.fn.winsaveview().leftcol
    return col >= leftcol
end

return M
