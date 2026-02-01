local M = {}

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

M.enable_filetypes = { "lua", "python", "markdown" }
M.last_textobj = "function.outer"

---核心跳转函数：采用用户测试成功的调用方式
function _G.TSMoveJump(obj, forward, start)
  if obj then
    M.last_textobj = obj
  end
  local target = "@" .. M.last_textobj

  -- 采用用户提供的特定模块路径和参数
  local ok, move = pcall(require, "nvim-treesitter-textobjects.move")
  if not ok then
    -- 备选：尝试不带连字符的路径
    ok, move = pcall(require, "nvim-treesitter.textobjects.move")
  end

  if ok and move then
    local method = forward and (start and "goto_next_start" or "goto_next_end")
      or (start and "goto_previous_start" or "goto_previous_end")
    if move[method] then
      -- 使用用户测试成功的双参数调用方式
      move[method](target, "textobjects")
    end
  end
end

function M.register_wk()
  local wk_ok, wk = pcall(require, "which-key")
  if not wk_ok then
    return
  end

  local prefix = "<leader>m"
  local items = {
    { prefix, group = "TS Move", buffer = true },
    -- Hydra 触发：按下 <leader>mx 开启循环跳转
    {
      prefix .. "x",
      function()
        wk.show({ keys = prefix, loop = true })
      end,
      desc = "Hydra Mode",
      buffer = true,
    },
    -- 基础跳转
    {
      prefix .. "j",
      function()
        _G.TSMoveJump(nil, true, true)
      end,
      desc = "Next Start",
      buffer = true,
    },
    {
      prefix .. "J",
      function()
        _G.TSMoveJump(nil, true, false)
      end,
      desc = "Next End",
      buffer = true,
    },
    {
      prefix .. "k",
      function()
        _G.TSMoveJump(nil, false, true)
      end,
      desc = "Prev Start",
      buffer = true,
    },
    {
      prefix .. "K",
      function()
        _G.TSMoveJump(nil, false, false)
      end,
      desc = "Prev End",
      buffer = true,
    },
  }

  for k, v in pairs(M.defines) do
    table.insert(items, {
      prefix .. k,
      function()
        _G.TSMoveJump(v, true, true)
      end,
      desc = v,
      buffer = true,
    })
  end
  wk.add(items)
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = function(_, opts)
      opts.textobjects = opts.textobjects or {}
      opts.textobjects.select = {
        enable = true,
        lookahead = true,
        keymaps = M.defines,
      }
      opts.textobjects.move = {
        enable = true,
        set_jumps = true,
      }
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, M.enable_filetypes)
      end
    end,
    config = function(_, opts)
      -- 使用 schedule 确保在完全初始化后执行
      vim.schedule(function()
        local ts_ok, configs = pcall(require, "nvim-treesitter.configs")
        if ts_ok then
          configs.setup(opts)
        end

        -- 对当前 buffer 生效按键
        local ft = vim.bo.filetype
        for _, v in ipairs(M.enable_filetypes) do
          if v == ft then
            M.register_wk()
            break
          end
        end
      end)

      -- 注册自动命令以支持后续打开的文件
      vim.api.nvim_create_autocmd("FileType", {
        pattern = M.enable_filetypes,
        callback = function()
          vim.schedule(function()
            M.register_wk()
          end)
        end,
      })
    end,
  },
}
