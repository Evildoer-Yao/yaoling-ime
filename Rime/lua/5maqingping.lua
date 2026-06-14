   -- 当输入达到 5 码且无候选词时，自动清空输入内容。
   --
   -- 触发条件:
   -- 1.当输入长度达到 5 。
   -- 2.没有候选词菜单。
   -- 3.纯a-z字母。
   -- 4.不以z开头。（保留反查功能）
   -- 条件达成立即清空正在输入的内容。（无需按下下一个按键）
   --
   -- 技术说明：我们监听了 context.update_notifier 事件。
   -- 这样就能等转码和过滤模块更新完候选词列表后，再获取输入法的最新状态，避免误判。

local M = {}
   -- 安全检查是否存在候选词菜单。（防止调用出错导致脚本崩溃）

local function safe_has_menu(ctx)
  local ok, v = pcall(function()
    return ctx:has_menu()
  end)
  return ok and v or false
end

function M.init(env)
  local ctx = env.engine.context
  local clearing = false -- 防止清空操作递归触发。

   -- 状态更新的处理函数
  local function handler(context)
    if clearing then
      return
    end

    local input = context.input or ""
   -- 仅处理长度=5 + 纯a-z字母 + 不是以z开头的输入。（排除带特殊前缀的情况）
    if #input ~= 5 or not input:match("^[a-z]+$") or input:match("^z") then
      return
    end

   -- 如果有候选词菜单，就不触发清屏。
    if safe_has_menu(context) then
      return
    end

   -- 满足条件时自动清空输入。
    clearing = true
    context:clear()
    clearing = false
  end

   -- 适配不同版本的 Rime 状态通知。
  if ctx.update_notifier then
    ctx.update_notifier:connect(handler)
  else
   -- Fallback: older builds may not have update_notifier.
    ctx.option_update_notifier:connect(function() handler(ctx) end)
  end
end

function M.func(key, env)
   -- 空按键处理器，核心逻辑在状态监听里
  return 2
end

return M

