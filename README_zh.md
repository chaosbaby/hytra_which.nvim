# hytra_which.nvim

一个轻量级的 Neovim 插件，利用 `which-key.nvim` v3 的 `loop` (循环) 模式，为重复性的导航任务提供类似 "Hydra" 的体验，并具备智能 Treesitter 文本对象 (textobject) 检测功能。

## 🚀 特性

- **万能 Hydra 激活器**：通过一个触发键（默认：`x`）将任何 `which-key` 前缀转换为循环模式。
- **智能 Treesitter 集成**：
    - **SCM 自动检测**：通过解析特定语言的 `.scm` 文件，自动识别支持的文本对象。
    - **精简模式 (动态分析)**：可选地过滤菜单，仅显示当前缓冲区 (buffer) 中实际存在的文本对象。
    - **模式切换**：在菜单中即时切换“精简”和“全量”模式（按 `z` 键）。
- **上下文感知**：记录上一次跳转的文本对象，以便快速重复。
- **零开销**：使用 `which-key` 的原生功能实现，极致精简。

## 📦 安装

使用 [lazy.nvim](https://github.com/folke/lazy.nvim)：

```lua
{
    "chaosbaby/hytra_which.nvim",
    dependencies = {
        "folke/which-key.nvim",
        "nvim-treesitter/nvim-treesitter",
        "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = {
        -- 内置 Treesitter 文本对象配置
        ts = {
            prefix = "<leader>m",
            trigger = "x"
        },
        -- 其他组的通用激活器
        groups = {
            ["<leader>h"] = "x", -- Git Hunks (gitsigns)
            ["<leader>d"] = "x", -- LSP 诊断 (Diagnostics)
        }
    },
    config = function(_, opts)
        require("hytra-which").setup(opts)
    end
}
```

## 🛠️ 用法

### Treesitter 模式
- 按 `<leader>m` 打开文本对象菜单。
- **智能过滤**：仅显示当前文件类型支持的（以及可选地，当前缓冲区中存在的）文本对象。
- **跳转**：按下对应的键（例如 `f` 代表函数）进行跳转。菜单将保持打开状态（Hydra 模式）。
- **重复**：
    - 按 `j` / `k` 跳转到上一个对象的 **下一个/上一个起始位置**。
    - 按 `J` / `K` 跳转到上一个对象的 **下一个/上一个结束位置**。
- **模式切换**：按 `z` 键在 **精简模式** (仅显示缓冲区中存在的) 和 **全量模式** (显示语言支持的所有对象) 之间切换。
- **再次激活**：按 `<leader>mx` 使用上一次跳转的目标快速重新进入循环。

### 通用模式
- 如果你有一个类似 `<leader>h` 的 Git hunk 分组：
- 按 `<leader>hx` 进入 "Git Hydra"。
- 现在你可以连续按下该分组内的任何按键（如 `j`, `k` 跳转 hunk），而无需重复输入前缀。

## ⌨️ 命令

- `:HytraOn <prefix> [trigger]` - 动态为任何按键前缀启用 Hydra 模式。
