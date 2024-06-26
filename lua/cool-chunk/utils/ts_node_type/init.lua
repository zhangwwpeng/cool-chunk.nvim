local M = {}

M.cpp = require("cool-chunk.utils.ts_node_type.cpp")
M.lua = require("cool-chunk.utils.ts_node_type.lua")
M.default = {
    "class",
    "^func",
    "method",
    "^if",
    "else",
    "while",
    "for",
    "with",
    "try",
    "except",
    "match",
    "arguments",
    "argument_list",
    "object",
    "dictionary",
    "element",
    "table",
    "tuple",
    "do_block",
    "return",
    "call_expression",
}

return M
