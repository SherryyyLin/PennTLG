-- modules/gameStateManager.lua
-- 游戏状态管理器，用于统一管理界面切换与生命周期调用。
-- Game State Manager to handle screen transitions and lifecycle delegation.

local logger = require("modules.logger") -- 加载日志模块 / Load logging module

local gameStateManager = {}

-- 当前状态配置
-- Config of current state (table)
local currentState

-- 当前状态名称
-- Name of the current state (string)
local currentStateName

-- 已缓存的状态
-- Cache for loaded state modules
-- loadedStates[stateName] → config
local loadedStates = {}


--------------------------------------------------
--- @brief 切换到指定状态模块。<br>
--- @brief Switch to a given state module.
---
--- @param stateName (string) 状态名称 / Name of the state
---
--- @return nil
--------------------------------------------------
function gameStateManager.switchState(stateName)
    -- 判断当前状态与目标状态，如果相同不执行切换
    -- Check if the current state is the same as the target state, if so, do nothing
    if currentStateName == stateName then
        logger.logInfo("[gameStateManager] 已在状态: " ..
            stateName .. "，不进行切换 / Already in state: " .. stateName .. ", no switch needed")
        return
    end

    -- 卸载当前状态（如有必要）
    -- Optionally perform cleanup for the current state
    if currentState and currentState.unload then
        logger.logInfo("[gameStateManager][switchState] 卸载状态: " ..
            currentStateName .. " / Unloading state: " .. currentStateName)
        currentState.unload()
    end

    -- 如未缓存该状态，尝试加载
    -- Load the module if not already loaded
    if not loadedStates[stateName] then
        local ok, result = pcall(require, "interface." .. stateName)
        if ok and type(result) == "table" then
            module = result
            loadedStates[stateName] = module
        else
            local err = result
            logger.logError("[gameStateManager][switchState] 加载状态失败: " ..
                stateName .. " / Failed to load state: " .. stateName)
            logger.logErrorTrace(err)
            return
        end
    end

    -- 切换状态并调用 load()
    -- Switch state and call load()
    currentStateName = stateName
    currentState = loadedStates[stateName]
    logger.logInfo("[gameStateManager][switchState] 切换到状态: " .. stateName .. " / Switching to state: " .. stateName)
    if currentState.load then
        currentState.load()
    end
end

--------------------------------------------------
--- @brief 卸载指定状态模块，释放其缓存与资源。<br>
--- @brief Unload a specified state module and free its cache.
---
--- @param stateName (string) 状态名称 / Name of the state to unload
---
--- @return nil
--------------------------------------------------
function gameStateManager.unloadState(stateName)
    -- 避免卸载当前状态
    -- Prevent unloading the current state
    if stateName == currentStateName then
        logger.logError("[gameStateManager][unloadState] 无法卸载当前状态: " ..
            stateName .. " / Cannot unload current state: " .. stateName)
        return
    end

    -- 构建卸载状态的文件路径
    -- Build the unload state file path
    local unloadStateName = "interface." .. stateName

    -- 卸载
    -- Unload the state
    if loadedStates[stateName] then
        loadedStates[stateName] = nil
        package.loaded[unloadStateName] = nil -- 从 Lua 模块系统中移除 / Remove from Lua package cache
        collectgarbage("collect")             -- 强制垃圾回收 / Force garbage collection
        logger.logInfo("[gameStateManager][unloadState] 已卸载状态: " ..
            stateName .. " / Unloaded state: " .. stateName)
    end
end

--------------------------------------------------
--- @brief 暂停当前状态。<br>
--- @brief Pause the current state.
---
--- @return nil
--------------------------------------------------
function gameStateManager.pause()
    if currentState and currentState.pause then
        currentState.pause()
    end
end

--------------------------------------------------
--- @brief 恢复当前状态。<br>
--- @brief Resume the current state
---
--- @return nil
--------------------------------------------------
function gameStateManager.resume()
    if currentState and currentState.resume then
        currentState.resume()
    end
end

--------------------------------------------------
--- @brief 更新当前状态（每帧调用）。<br>
--- @brief Update current state (called every frame).
---
--- @param dt (number) Love2D 传入的 deltaTime / Delta time from Love2D
---
--- @return nil
--------------------------------------------------
function gameStateManager.update(dt)
    if currentState and currentState.update then
        currentState.update(dt)
    end
end

--------------------------------------------------
--- @brief 绘制当前状态（每帧调用）。</p>
--- @brief Draw current state (called every frame).
---
--- @return nil
--------------------------------------------------
function gameStateManager.draw()
    if currentState and currentState.draw then
        currentState.draw()
    end
end

--------------------------------------------------
--- @brief 处理键盘按下事件。</p>
--- @brief Handle keypressed events.
---
--- @param key (string) 被按下的键名 / The key that was pressed
---
--- @return nil
--------------------------------------------------
function gameStateManager.keypressed(key)
    if currentState and currentState.keypressed then
        currentState.keypressed(key)
    end
end

--------------------------------------------------
--- @brief 处理键盘释放事件。</p>
--- @brief Handle key release events (paired with keypressed).
---
--- @param key (string) 被释放的键名 / Released key name
---
--- @return nil
--------------------------------------------------
function gameStateManager.keyreleased(key)
    if currentState and currentState.keyreleased then
        currentState.keyreleased(key)
    end
end

--------------------------------------------------
--- @brief 处理鼠标按下事件。</p>
--- @brief Handle mousepressed events.
---
--- @param x (number) 鼠标X坐标 / Mouse X position
--- @param y (number) 鼠标Y坐标 / Mouse Y position
--- @param button (number) 鼠标按键 / Mouse button (1 = 左键 / left)
--- @return nil
--------------------------------------------------
function gameStateManager.mousepressed(x, y, button)
    if currentState and currentState.mousepressed then
        currentState.mousepressed(x, y, button)
    end
end

--------------------------------------------------
--- @brief 处理鼠标松开事件.</p>
--- @brief Handle mousereleased events.
---
--- @param x (number) 鼠标X坐标 / Mouse X position
--- @param y (number) 鼠标Y坐标 / Mouse Y position
--- @param button (number) 鼠标按键 / Mouse button (1 = 左键 / left)
--- @return nil
--------------------------------------------------
function gameStateManager.mousereleased(x, y, button)
    if currentState and currentState.mousereleased then
        currentState.mousereleased(x, y, button)
    end
end

--------------------------------------------------
--- @brief 处理鼠标移动事件。</p>
--- @brief Handle mousemoved events.
---
--- @param x (number) 当前鼠标X / Current mouse X position
--- @param y (number) 当前鼠标Y / Current mouse Y position
--- @param dx (number) X轴相对移动量 / Delta X since last move
--- @param dy (number) Y轴相对移动量 / Delta Y since last move
--- @param istouch (boolean) 是否为触摸事件 / Whether this is a touch input
---
--- @return nil
--------------------------------------------------
function gameStateManager.mousemoved(x, y, dx, dy, istouch)
    if currentState and currentState.mousemoved then
        currentState.mousemoved(x, y, dx, dy, istouch)
    end
end

--------------------------------------------------
--- @brief 处理鼠标滚轮事件。</p>
--- @brief Handle wheelmoved events.
---
--- @param x (number) X轴滚动量 / Delta X for wheel movement
--- @param y (number) Y轴滚动量 / Delta Y for wheel movement
---
--- @return nil
-----------------------------------------------------
function gameStateManager.wheelmoved(x, y)
    if currentState and currentState.wheelmoved then
        currentState.wheelmoved(x, y)
    end
end

--------------------------------------------------
--- @brief 返回当前状态名称。</p>
--- @brief Return current state name.
---
--- @return string currentStateName 当前状态名 / Name of the current state
--------------------------------------------------
function gameStateManager.getCurrentState()
    return currentStateName
end

return gameStateManager
