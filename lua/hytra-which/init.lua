local M = {}

-- =============================================================================
-- 1. Treesitter Textobjects 状态与定义
-- =============================================================================
M.last_textobj = "function.outer"

M.state = {
    mode = "refined", -- "refined" (only existing in buffer) or "full" (all supported by lang)
    prefix = nil,
    trigger = nil,
}

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

---直接从 runtime 路径下的 textobjects.scm 文件中解析支持的 captures
---@param lang string 语言名称 (例如 "lua")
---@return table 捕获名集合
function M.get_captures_from_scm(lang)
    local captures = {}
    -- 获取所有匹配的查询文件 (支持用户自定义和插件预设)
    local files = vim.api.nvim_get_runtime_file("queries/" .. lang .. "/textobjects.scm", true)
    
    for _, file in ipairs(files) do
        local f = io.open(file, "r")
        if f then
            local content = f:read("*all")
            f:close()
            -- 使用正则匹配 @name.something
            for capture in content:gmatch("@([%w%._]+)") do
                captures[capture] = true
            end
        end
    end
    return captures
end

---获取当前 buffer 支持的 Treesitter textobject captures
---@param bufnr number
---@return table|nil 支持的 capture 集合
function M.get_supported_captures(bufnr)
    local ok_parser, parsers = pcall(require, "nvim-treesitter.parsers")
    local lang
    if ok_parser and parsers.get_buf_lang then
        lang = parsers.get_buf_lang(bufnr)
    else
        lang = vim.bo[bufnr].filetype
    end
    
    if not lang or lang == "" then return nil end

    -- 直接从 SCM 文件获取
    local captures = M.get_captures_from_scm(lang)
    
    -- 处理一些常见的语言继承 (简单处理)
    if lang == "typescript" or lang == "javascript" or lang == "tsx" then
        local base = M.get_captures_from_scm("ecma")
        for k, v in pairs(base) do captures[k] = v end
    end

    if next(captures) == nil then return nil end
    return captures
end

---获取当前 buffer 中实际存在的 Treesitter textobject captures
---@param bufnr number
---@return table|nil 实际存在的 capture 集合
function M.get_actual_captures(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    
    -- 获取语言，优先使用 nvim-treesitter 的 parser 映射
    local lang
    local ok_parser, parsers = pcall(require, "nvim-treesitter.parsers")
    if ok_parser and parsers.get_buf_lang then
        lang = parsers.get_buf_lang(bufnr)
    else
        lang = vim.treesitter.language.get_lang(vim.bo[bufnr].filetype) or vim.bo[bufnr].filetype
    end
    
    if not lang or lang == "" then return nil end

    -- 使用标准 Neovim API 获取 query
    local ok_q, q = pcall(vim.treesitter.query.get, lang, "textobjects")
    if not ok_q or not q then return nil end

    -- 使用标准 Neovim API 获取 parser 和 root
    local ok_p, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
    if not ok_p or not parser then return nil end
    
    local ok_tree, tree = pcall(parser.parse, parser)
    if not ok_tree or not tree or not tree[1] then return nil end
    local root = tree[1]:root()

    local actual = {}
    -- 迭代捕获
    pcall(function()
        for id, _ in q:iter_captures(root, bufnr, 0, -1) do
            local name = q.captures[id]
            actual[name] = true
        end
    end)
    
    return actual
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

    bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr

    -- 更新全局状态以便重刷
    M.state.prefix = prefix
    M.state.trigger = trigger

    -- 获取该语言支持的所有 captures
    local supported = M.get_supported_captures(bufnr)
    if not supported then return end

    -- 如果是精简模式，进一步过滤当前 buffer 实际存在的
    local filter_map = supported
    if M.state.mode == "refined" then
        local actual = M.get_actual_captures(bufnr)
        if actual then
            filter_map = {}
            for k, _ in pairs(supported) do
                if actual[k] then
                    filter_map[k] = true
                end
            end
        end
    end

    -- 先清理该 prefix 下的旧映射 (针对该 buffer)
    -- 注意：which-key 会自动覆盖重复的映射，但为了显示干净，我们构造一个完整的列表
    local items = {
        { prefix, group = "TS-Hytra (" .. M.state.mode .. ")", mode = "n", buffer = bufnr },
        -- 基础控制始终注册
        { prefix .. "j", function() M.ts_jump(nil, true, true) end, desc = "Next Start", buffer = bufnr },
        { prefix .. "k", function() M.ts_jump(nil, false, true) end, desc = "Prev Start", buffer = bufnr },
        { prefix .. "J", function() M.ts_jump(nil, true, false) end, desc = "Next End", buffer = bufnr },
        { prefix .. "K", function() M.ts_jump(nil, false, false) end, desc = "Prev End", buffer = bufnr },
        -- 切换模式映射
        {
            prefix .. "z",
            function()
                M.toggle_mode(bufnr)
            end,
            desc = "Toggle Refined/Full Mode",
            buffer = bufnr,
        },
    }

    -- 动态过滤并注册
    local has_any = false
    -- 我们需要把不满足条件的按键显式设置为 nil 或不包含，以确保 toggle 回去时消失
    -- 为了彻底清除，我们先用 which-key 的新 API 特性或简单的全覆盖
    
    -- 收集所有可能的定义键
    local all_keys = {}
    for k, _ in pairs(M.defines) do
        table.insert(all_keys, prefix .. k)
    end
    
    -- 构造新列表
    for k, v in pairs(M.defines) do
        if filter_map[v] then
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
        else
            -- 如果该对象不在 filter_map 中，显式将其在该 prefix 下禁用，防止 toggle 切换时不消失
            table.insert(items, { prefix .. k, hidden = true, buffer = bufnr })
        end
    end

    -- 如果没有任何支持的对象，基础控制可能也没意义，可以选择不注册
    if has_any then
        wk.add(items)
        M.activate(prefix, trigger, "TS TextObject Hydra", bufnr)
    end
end

---切换精简/全量模式并重新注册
function M.toggle_mode(bufnr)
    bufnr = (bufnr == nil or bufnr == 0) and vim.api.nvim_get_current_buf() or bufnr
    M.state.mode = M.state.mode == "refined" and "full" or "refined"
    vim.notify("Hytra Mode: " .. M.state.mode)
    if M.state.prefix then
        M.register_buffer_ts(bufnr, M.state.prefix, M.state.trigger)
        -- 重新显示 which-key 菜单
        local wk_ok, wk = pcall(require, "which-key")
        if wk_ok then
            wk.show({ keys = M.state.prefix, loop = true })
        end
    end
end

---生成 TS 跳转映射，采用动态过滤机制
function M.setup_ts(opts)
    opts = opts or {}
    local prefix = opts.prefix or "<leader>m"
    local trigger = opts.trigger or "x"

    M.state.prefix = prefix
    M.state.trigger = trigger

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