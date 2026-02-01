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
-- 2. 辅助工具函数
-- =============================================================================

---获取当前 buffer 支持的 Treesitter textobject captures
---@param bufnr number
---@return table|nil 支持的 capture 集合 (key 为 capture 名，value 为 true)
function M.get_supported_captures(bufnr)
    local ok_parser, parsers = pcall(require, "nvim-treesitter.parsers")
    if not ok_parser then return nil end

    -- 兼容性检查：有些版本可能没有 get_buf_lang
    local lang
    if parsers.get_buf_lang then
        lang = parsers.get_buf_lang(bufnr)
    else
        lang = vim.bo[bufnr].filetype
    end
    
    if not lang then return nil end

    local ok_query, query = pcall(require, "nvim-treesitter.query")
    if not ok_query then return nil end

    -- 再次确认 query 模块是否有 get_query 函数
    if not query.get_query then return nil end

    local ts_query = query.get_query(lang, "textobjects")
    if not ts_query then return nil end

    local captures = {}
    if ts_query.captures then
        for _, name in ipairs(ts_query.captures) do
            captures[name] = true
        end
    end
    return captures
end

-- =============================================================================
-- 3. Treesitter 跳转核心函数
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
-- 4. 万能 Hydra 激活器 (支持全局或 Buffer-local)
-- =============================================================================
---@param prefix string 需要进入循环模式的按键前缀 (例如 "<leader>h")
---@param trigger string|nil 触发该模式的按键 (默认为 "x")
---@param desc string|nil 描述
---@param bufnr number|nil 如果提供，则注册为 buffer-local 映射
function M.activate(prefix, trigger, desc, bufnr)
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
            buffer = bufnr,
        },
    })
end

-- =============================================================================
-- 5. Treesitter 动态配置生成
-- =============================================================================

---为特定 buffer 注册 Treesitter 跳转映射，并过滤不支持的对象
function M.register_buffer_ts(bufnr, prefix, trigger)
    local wk_ok, wk = pcall(require, "which-key")
    if not wk_ok then return end

    -- 获取当前 buffer 支持的 captures
    local supported = M.get_supported_captures(bufnr)
    if not supported then return end

    local items = {
        { prefix, group = "TS-Hytra", mode = "n", buffer = bufnr },
        -- 基础控制始终注册
        { prefix .. "j", function() M.ts_jump(nil, true, true) end, desc = "Next Start", buffer = bufnr },
        { prefix .. "k", function() M.ts_jump(nil, false, true) end, desc = "Prev Start", buffer = bufnr },
        { prefix .. "J", function() M.ts_jump(nil, true, false) end, desc = "Next End", buffer = bufnr },
        { prefix .. "K", function() M.ts_jump(nil, false, false) end, desc = "Prev End", buffer = bufnr },
    }

    -- 动态过滤并注册
    local has_any = false
    for k, v in pairs(M.defines) do
        if supported[v] then
            has_any = true
            table.insert(items, {
                prefix .. k,
                function()
                    M.ts_jump(v, true, true)
                    wk.show({ keys = prefix, loop = true })
                end,
                desc = v,
                buffer = bufnr,
            })
        end
    end

    -- 如果没有任何支持的对象，基础控制可能也没意义，可以选择不注册
    if has_any then
        wk.add(items)
        M.activate(prefix, trigger, "TS TextObject Hydra", bufnr)
    end
end

---生成 TS 跳转映射，采用动态过滤机制
function M.setup_ts(opts)
    opts = opts or {}
    local prefix = opts.prefix or "<leader>m"
    local trigger = opts.trigger or "x"

    -- 创建自动命令组
    local group = vim.api.nvim_create_augroup("HytraTS", { clear = true })

    -- 注册自动命令，在文件类型改变或进入 buffer 时重新注册映射
    vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        group = group,
        callback = function(args)
            -- 延迟执行以确保 treesitter 已经解析或加载
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf) then
                    M.register_buffer_ts(args.buf, prefix, trigger)
                end
            end)
        end,
    })

    -- 对当前 buffer 立即尝试注册
    M.register_buffer_ts(0, prefix, trigger)
end

-- =============================================================================
-- 6. 统一入口与命令
-- =============================================================================
function M.setup(opts)
    opts = opts or {}

    -- 处理 Treesitter 自动生成 (带动态过滤)
    if opts.ts then
        M.setup_ts(opts.ts)
    end

    -- 处理其他通用组的批量激活 (通常是全局的)
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
            -- 默认作为全局激活，如果想支持 buffer 可以再扩展
            M.activate(prefix, trigger)
        end
    end, { nargs = "*" })
end

return M