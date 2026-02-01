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

-- 辅助：获取支持的 capture
function Hytra.get_supported_captures(bufnr)
  local ok_parser, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok_parser then return nil end
  local lang = parsers.get_buf_lang(bufnr)
  if not lang then return nil end
  local ok_query, query = pcall(require, "nvim-treesitter.query")
  if not ok_query then return nil end
  local ts_query = query.get_query(lang, "textobjects")
  if not ts_query then return nil end
  local captures = {}
  for _, name in ipairs(ts_query.captures) do
    captures[name] = true
  end
  return captures
end

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

-- 万能 Hydra 激活器
function Hytra.activate(prefix, trigger, desc, bufnr)
  local wk_ok, wk = pcall(require, "which-key")
  if not wk_ok then return end
  trigger = trigger or "x"
  wk.add({
    {
      prefix .. trigger,
      function() wk.show({ keys = prefix, loop = true }) end,
      desc = desc or ("Hydra Mode (" .. prefix .. ")"),
      buffer = bufnr,
    },
  })
end

-- 动态为 Buffer 注册 TS 映射
function Hytra.register_buffer_ts(bufnr, prefix, trigger)
  local wk_ok, wk = pcall(require, "which-key")
  if not wk_ok then return end

  local supported = Hytra.get_supported_captures(bufnr)
  if not supported then return end

  local items = {
    { prefix, group = "TS-Hytra", mode = "n", buffer = bufnr },
    { prefix .. "j", function() Hytra.ts_jump(nil, true, true) end, desc = "Next Start", buffer = bufnr },
    { prefix .. "k", function() Hytra.ts_jump(nil, false, true) end, desc = "Prev Start", buffer = bufnr },
    { prefix .. "J", function() Hytra.ts_jump(nil, true, false) end, desc = "Next End", buffer = bufnr },
    { prefix .. "K", function() Hytra.ts_jump(nil, false, false) end, desc = "Prev End", buffer = bufnr },
  }

  local has_any = false
  for k, v in pairs(Hytra.defines) do
    if supported[v] then
      has_any = true
      table.insert(items, {
        prefix .. k,
        function()
          Hytra.ts_jump(v, true, true)
          wk.show({ keys = prefix, loop = true })
        end,
        desc = v,
        buffer = bufnr,
      })
    end
  end

  if has_any then
    wk.add(items)
    Hytra.activate(prefix, trigger, "TS TextObject Hydra", bufnr)
  end
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
      select = { enable = true, lookahead = true, keymaps = Hytra.defines },
      move = { enable = true, set_jumps = true },
    },
    hytra = {
      ts = { prefix = "<leader>m", trigger = "x" },
      groups = {
        ["<leader>h"] = "x",
        ["<leader>d"] = "x",
      }
    }
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)

    local h_opts = opts.hytra or {}
    if h_opts.ts then
      local prefix = h_opts.ts.prefix or "<leader>m"
      local trigger = h_opts.ts.trigger or "x"
      
      -- 注册自动命令实现动态过滤
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
        callback = function(args)
          vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf) then
              Hytra.register_buffer_ts(args.buf, prefix, trigger)
            end
          end)
        end,
      })
      Hytra.register_buffer_ts(0, prefix, trigger)
    end

    if h_opts.groups then
      for prefix, trigger in pairs(h_opts.groups) do
        Hytra.activate(prefix, trigger)
      end
    end
  end,
}
