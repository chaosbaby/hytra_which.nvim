local M = {}

-- =============================================================================
-- 1. Treesitter Textobjects 状态与定义
-- =============================================================================
M.last_textobj = "function.outer"

M.defines = {
    m = "function.outer",
    f = "call.outer",
    d = "conditional.outer",
    o = "loop.outer",
    s = "statement.outer",
    a = "parameter.outer",
    c = "comment.outer",
    b = "block.outer",
    l = "class.outer",
    r = "frame.outer",
    t = "attribute.outer",
    e = "scopename.outer",
    M = "function.inner",
    F = "call.inner",
    D = "conditional.inner",
    O = "loop.inner",
    A = "parameter.inner",
    B = "block.inner",
    L = "class.inner",
    R = "frame.inner",
    T = "attribute.inner",
    E = "scopename.inner",
    g = "assignment.outer",
    G = "assignment.inner",
    n = "assignment.lhs",
    N = "assignment.rhs",
    u = "return.outer",
    U = "return.inner",
}

-- =============================================================================
-- 2. Treesitter 跳转核心函数
-- =============================================================================
---@param obj string|nil 目标 textobject，若为 nil 则使用上一次的对象
---@param forward boolean 是否向后跳转
---@param start boolean 是否跳转到开始位置
function M.ts_jump(obj, forward, start)
    if obj then
        M.last_textobj = obj
    end
    local target = "@" .. M.last_textobj

    local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
    if not ok then
        ok, move = pcall(require, "nvim-treesitter.textobjects.move")
    end

    if ok and move then
        local method = forward and (start and "goto_next_start" or "goto_next_end")
            or (start and "goto_previous_start" or "goto_previous_end")
        if move[method] then
            move[method](target, "textobjects")
        end
    end
end

-- =============================================================================
-- 3. 万能 Hydra 激活器 (针对已有 Keymap 组)
-- =============================================================================
---@param prefix string 需要进入循环模式的按键前缀 (例如 "<leader>h")
---@param trigger string|nil 触发该模式的按键 (默认为 "x")
---@param desc string|nil 描述
function M.activate(prefix, trigger, desc)
    local wk_ok, wk = pcall(require, "which-key")
    if not wk_ok then return end

    trigger = trigger or "x"
    desc = desc or "Hydra Mode (" .. prefix .. ")"

    wk.add({
        {
            prefix .. trigger,
            function()
                wk.show({ keys = prefix, loop = true })
            end,
            desc = desc,
        },
    })
end

-- =============================================================================
-- 4. Treesitter 特殊配置生成
-- =============================================================================
---生成一组 TS 跳转映射，并在跳转后自动进入 Hydra 模式
function M.setup_ts(opts)
    opts = opts or {}
    local prefix = opts.prefix or "<leader>m"
    local trigger = opts.trigger or "x"
    local wk_ok, wk = pcall(require, "which-key")
    if not wk_ok then return end

    local items = {
        { prefix, group = "TS-Hytra", mode = "n" },
        -- 核心控制：j/k/J/K
        { prefix .. "j", function() M.ts_jump(nil, true, true) end, desc = "Next Start" },
        { prefix .. "k", function() M.ts_jump(nil, false, true) end, desc = "Prev Start" },
        { prefix .. "J", function() M.ts_jump(nil, true, false) end, desc = "Next End" },
        { prefix .. "K", function() M.ts_jump(nil, false, false) end, desc = "Prev End" },
    }

    -- 批量生成各个对象的跳转
    for k, v in pairs(M.defines) do
        table.insert(items, {
            prefix .. k,
            function()
                M.ts_jump(v, true, true)
                -- 跳转后自动开启循环面板
                wk.show({ keys = prefix, loop = true })
            end,
            desc = v,
        })
    end

    wk.add(items)

    -- 注册 x 键作为手动激活入口
    M.activate(prefix, trigger, "TS TextObject Hydra")
end

-- =============================================================================
-- 5. 统一入口与命令
-- =============================================================================
function M.setup(opts)
    opts = opts or {}

    -- 处理 Treesitter 自动生成
    if opts.ts then
        M.setup_ts(opts.ts)
    end

    -- 处理其他通用组的批量激活
    if opts.groups then
        for k, v in pairs(opts.groups) do
            if type(k) == "number" then
                M.activate(v, "x")
            else
                M.activate(k, v)
            end
        end
    end

    -- 注册命令方便动态使用
    vim.api.nvim_create_user_command("HytraOn", function(cmd_opts)
        local args = vim.split(cmd_opts.args, "%s+")
        local prefix = args[1]
        local trigger = args[2] or "x"
        if prefix then
            M.activate(prefix, trigger)
        end
    end, { nargs = "*" })
end

return M
