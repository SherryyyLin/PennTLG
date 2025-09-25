--- @brief 禁用JIT编译器在Mac ARM64架构上的运行，避免 LuaJIT 兼容性问题
--- @brief Disable JIT on Mac ARM64 architecture, avoiding LuaJIT compatibility issues
--- @diagnostic disable-next-line: undefined-global
local jit = jit
if (love.system.getOS() == 'OS X') and (jit.arch == 'arm64' or jit.arch == 'arm') then jit.off() end



--------------------------------------------------
--- @brief 加载功能模块。
--- @brief Load core functional modules.
--------------------------------------------------
local userSettings = require("modules.userSettings")         -- 加载配置模块 / Load settings module
local logger = require("modules.logger")                     -- 加载日志模块 / Load logger module
local gameStateManager = require("modules.gameStateManager") -- 加载游戏状态管理模块 / Load game state management module
local windowManager = require("modules.windowManager")       -- 加载窗口管理模块 / Load window management module
local langManager = require("modules.langManager")           -- 加载语言管理模块 / Load language management module
local layoutManager = require("modules.layoutManager")       -- 加载布局管理模块 / Load layout management module

local defaultGameState = "menu"                              -- 默认游戏状态 / Default game state



------- 未来迁移位置 -------
-- 初始化一次随机种子
-- 使用当前系统时间和CPU时间的组合，确保每次启动随机数不同
-- Initialize random seed once
-- Use system time + reversed CPU clock digits to ensure uniqueness
math.randomseed(os.time() + tonumber(tostring(os.clock()):reverse():sub(1, 6)))
logger.logInfo("[main] 随机种子初始化完成 / Random seed initialized")
--------------------------

--------------------------------------------------
--- @brief LOVE2D 初始化函数：在游戏启动时调用一次
--- @brief LOVE2D load function: called once at game startup
--- @return nil
--------------------------------------------------
function love.load()
    logger.init()                                  -- 初始化日志记录器 / Initialize logger
    logger.logInfo("[main] 尝试启动游戏主函数 / Attempting to start main function")
    userSettings.load()                            -- 加载用户设置 / Load user settings
    windowManager.init()                           -- 初始化窗口参数 / Initialize window parameters
    windowManager.onResize(love.graphics.getWidth(), love.graphics.getHeight())
    langManager.init()                             -- 初始化语言设置 / Initialize language settings
    gameStateManager.switchState(defaultGameState) -- 切换到菜单状态 / Switch to default game state
end

--------------------------------------------------
--- @brief LOVE2D 更新函数：每帧调用一次
--- @brief LOVE2D update function: called once per frame
--- @param dt (number) 时间增量 / Time delta since last frame
--------------------------------------------------
function love.update(dt)
    gameStateManager.update(dt)
end

--------------------------------------------------
--- @brief LOVE2D 每帧绘图函数：根据当前状态绘制界面
--- @brief LOVE2D draw function: draws the current game state
--------------------------------------------------
function love.draw()
    gameStateManager.draw()
end

---
---
---
---
---
---
---
--------------------------------------------------
--- @brief 键盘按下事件。</p>
--- @brief Handle keyboard key pressed events.
---
--- @param key (string) 被按下的键名 / The key that was pressed
--------------------------------------------------
function love.keypressed(key)
    gameStateManager.keypressed(key)
end

--------------------------------------------------
--- @brief 键盘释放事件。</p>
--- @brief Handle key release events (paired with keypressed).
---
--- @param key (string) 被释放的键 / Released key name
--------------------------------------------------
function love.keyreleased(key)
    gameStateManager.keyreleased(key)
end

--------------------------------------------------
--- @brief 鼠标按下事件（用于选中卡牌、点击按钮）。</p>
--- @brief Handle mouse button pressed events.
---
--- @param x (number) 鼠标X坐标 / Mouse X position
--- @param y (number) 鼠标Y坐标 / Mouse Y position
--- @param button (number) 鼠标按键（1=左键）/ Mouse button (1 = left click)
--------------------------------------------------
function love.mousepressed(x, y, button)
    gameStateManager.mousepressed(x, y, button)
end

--------------------------------------------------
--- @brief 鼠标松开事件（用于放下卡牌、确认点击）。</p>
--- @brief Handle mouse button released events.
---
--- @param x (number) 鼠标X坐标 / Mouse X position
--- @param y (number) 鼠标Y坐标 / Mouse Y position
--- @param button (number) 鼠标按键 / Mouse button (1 = left click)
--------------------------------------------------
function love.mousereleased(x, y, button)
    gameStateManager.mousereleased(x, y, button)
end

--------------------------------------------------
--- @brief 鼠标移动事件（用于卡牌拖动、悬浮反馈）。</p>
--- @brief Handle mouse movement (for drag interaction or hover effects).
---
--- @param x (number) 当前鼠标X坐标 / Current mouse X
--- @param y (number) 当前鼠标Y坐标 / Current mouse Y
--- @param dx (number) 上次移动到这次的X增量 / Delta X
--- @param dy (number) 上次移动到这次的Y增量 / Delta Y
--- @param istouch (boolean) 是否为触摸事件 / Whether the event is from touch
--------------------------------------------------
function love.mousemoved(x, y, dx, dy, istouch)
    gameStateManager.mousemoved(x, y, dx, dy, istouch)
end

--------------------------------------------------
--- @brief 鼠标滚轮滚动事件（可用于卡组浏览、缩放）
--- @brief Handle mouse wheel movement
---
--- @param x (number) 水平滚动量 / Scroll amount in X direction
--- @param y (number) 垂直滚动量 / Scroll amount in Y direction
--------------------------------------------------
function love.wheelmoved(x, y)
    gameStateManager.wheelmoved(x, y)
end

--------------------------------------------------
--- @brief LOVE2D 回调，用于响应窗口尺寸变化事件。<br>
--- @brief LOVE2D callback to handle window resize events.
---
--- @param w (number) 新的窗口宽度 / New window width
--- @param h (number) 新的窗口高度 / New window height
--- @return nil
--------------------------------------------------
function love.resize(w, h)
    windowManager.onResize(w, h) -- 通知窗口管理器进行响应处理 / Notify window manager to handle resize
end
