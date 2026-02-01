local Hytra = {
  last_textobj = "function.outer",
  defines = {
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
}

-- Treesitter 跳转核心逻辑
function Hytra.ts_jump(obj, forward, start)
  if obj then Hytra.last_textobj = obj end
  local target = "@" .. Hytra.last_textobj
  local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
  if not ok then ok, move = pcall(require, "nvim-treesitter.textobjects.move") end
  if ok and move then
    local method = forward and (start and "goto_next_start" or "goto_next_end")
      or (start and "goto_previous_start" or "goto_previous_end")
    if move[method] then
      move[method](target, "textobjects")
    end
  end
end

-- 万能 Hydra 激活器：给任何 prefix 增加一个 trigger 键来开启 which-key 的 loop 模式
function Hytra.activate(prefix, trigger, desc)
  local wk_ok, wk = pcall(require, "which-key")
  if not wk_ok then return end
  trigger = trigger or "x"
  wk.add({
    {
      prefix .. trigger,
      function() wk.show({ keys = prefix, loop = true }) end,
      desc = desc or ("Hydra Mode (" .. prefix .. ")"),
    },
  })
end

-- 为 Treesitter Textobjects 生成一组专用的跳转映射
function Hytra.setup_ts(opts)
  local prefix = opts.prefix or "<leader>m"
  local trigger = opts.trigger or "x"
  local wk_ok, wk = pcall(require, "which-key")
  if not wk_ok then return end

  local items = {
    { prefix, group = "TS-Hytra", mode = "n" },
    { prefix .. "j", function() Hytra.ts_jump(nil, true, true) end, desc = "Next Start" },
    { prefix .. "k", function() Hytra.ts_jump(nil, false, true) end, desc = "Prev Start" },
    { prefix .. "J", function() Hytra.ts_jump(nil, true, false) end, desc = "Next End" },
    { prefix .. "K", function() Hytra.ts_jump(nil, false, false) end, desc = "Prev End" },
  }

  for k, v in pairs(Hytra.defines) do
    table.insert(items, {
      prefix .. k,
      function()
        Hytra.ts_jump(v, true, true)
        -- 跳转后自动触发循环显示
        wk.show({ keys = prefix, loop = true })
      end,
      desc = v,
    })
  end
  wk.add(items)
  Hytra.activate(prefix, trigger, "TS TextObject Hydra")
end

return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "nvim-treesitter/nvim-treesitter-textobjects",
    "folke/which-key.nvim",
  },
  opts = {
    ensure_installed = { "lua", "python", "markdown" },
    textobjects = {
      select = {
        enable = true,
        lookahead = true,
        keymaps = Hytra.defines,
      },
      move = {
        enable = true,
        set_jumps = true,
      },
    },
    -- Hytra 扩展配置
    hytra = {
      ts = { prefix = "<leader>m", trigger = "x" },
      groups = {
        ["<leader>h"] = "x", -- Git Hunk Hydra 激活
        ["<leader>d"] = "x", -- Diagnostic Hydra 激活
      }
    }
  },
  config = function(_, opts)
    -- 1. 配置 Treesitter
    local ts_ok, configs = pcall(require, "nvim-treesitter.configs")
    if ts_ok then
      configs.setup(opts)
    end

    -- 2. 初始化 Hytra 逻辑
    local h_opts = opts.hytra or {}
    
    -- 自动生成 Treesitter 跳转 keymaps
    if h_opts.ts then
      Hytra.setup_ts(h_opts.ts)
    end

    -- 批量激活其他组的 Hydra 模式
    if h_opts.groups then
      for prefix, trigger in pairs(h_opts.groups) do
        Hytra.activate(prefix, trigger)
      end
    end

    -- 注册 HytraOn 命令，方便动态开启
    vim.api.nvim_create_user_command("HytraOn", function(c)
      local args = vim.split(c.args, "%s+")
      local prefix = args[1]
      local trigger = args[2] or "x"
      if prefix then
        Hytra.activate(prefix, trigger)
      end
    end, { nargs = "*" })
  end,
}