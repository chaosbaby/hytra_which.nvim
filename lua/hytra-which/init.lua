local M = {}

-- 默认跳转目标
M.last_textobj = "function.outer"

-- 预定义的对象映射，方便扩展
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

---核心跳转函数
---@param obj string|nil 目标 textobject (例如 "function.outer")，若为 nil 则使用上次的目标
---@param forward boolean 是否向后跳转
---@param start boolean 是否跳转到开始位置
function M.jump(obj, forward, start)
    if obj then
        M.last_textobj = obj
    end
    local target = "@" .. M.last_textobj

    local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
    if not ok then
        -- 兼容不同的路径
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

---启动 Hytra 模式 (Which-key Loop)
---@param obj string|nil 如果提供，则先切换到该目标再跳转
function M.start_hytra(obj)
    local wk_ok, wk = pcall(require, "which-key")
    if not wk_ok then
        vim.notify("which-key not found", vim.log.levels.ERROR)
        return
    end

    -- 1. 先执行一次移动 (如果 obj 为空则重复上一次)
    M.jump(obj, true, true)

    -- 2. 开启 which-key 的循环模式
    -- 假设用户绑定的前缀是 <leader>m
    wk.show({ keys = "<leader>m", loop = true })
end

---注册按键到 Which-key
function M.setup(opts)
    opts = opts or {}
    local prefix = opts.prefix or "<leader>m"
    local wk_ok, wk = pcall(require, "which-key")
    if not wk_ok then return end

    local items = {
        { prefix, group = "Hytra (TS Move)", mode = "n" },
        -- 核心入口：重复上一次跳转并进入 Hydra 模式
        { prefix .. "x", function() M.start_hytra() end, desc = "Hydra Mode (Repeat Last)" },
        -- 基础跳转控制
        { prefix .. "j", function() M.jump(nil, true, true) end, desc = "Next Start" },
        { prefix .. "k", function() M.jump(nil, false, true) end, desc = "Prev Start" },
        { prefix .. "J", function() M.jump(nil, true, false) end, desc = "Next End" },
        { prefix .. "K", function() M.jump(nil, false, false) end, desc = "Prev End" },
    }

    -- 批量注册对象跳转，跳转后自动触发循环
    for k, v in pairs(M.defines) do
        table.insert(items, {
            prefix .. k,
            function()
                M.start_hytra(v)
            end,
            desc = v,
        })
    end

    wk.add(items)
end

return M
