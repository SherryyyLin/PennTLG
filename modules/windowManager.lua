-- modules/windowManager.lua
-- 管理窗口尺寸、全屏模式、分辨率等配置
-- Manage window size, fullscreen mode, resolution, etc.

local userSettings = require("modules.userSettings")   -- 加载用户设置模块 / Load user settings module
local logger = require("modules.logger")               -- 加载日志模块 / Load logging module
local layoutManager = require("modules.layoutManager") -- 加载布局管理模块 / Load layout management module

local windowManager = {}

local currentConfig = {} -- 当前窗口设置 / Current window configuration

--------------------------------------------------
--- @brief 初始化窗口管理模块，根据传入或默认配置设置窗口。<br>
--- @brief Initialize window manager; apply passed or default config.
---
--- @param configTable (table?) 可选的配置表 / Optional configuration table (e.g. width, height, fullscreen, vsync, resizable)
---                             若未传入则使用默认设置 / Defaults used if not provided
---
--- @return nil
--------------------------------------------------
function windowManager.init(configTable)
    logger.logInfo("[windowManager][init] 初始化窗口管理器 / Initializing window manager")

    -- 确保 userSettings 已加载
    -- Ensure userSettings is loaded
    if not userSettings.getDisplaySettings() then
        userSettings.load()
    end

    -- 从 userSettings 获取用户配置
    -- Get user settings from userSettings
    currentConfig = {
        width = userSettings.getDisplaySettings().width or 1280,
        height = userSettings.getDisplaySettings().height or 720,
        fullscreen = userSettings.getDisplaySettings().fullscreen or false,
        vsync = userSettings.getDisplaySettings().vsync or true,
        resizable = userSettings.getDisplaySettings().resizable or true
    }

    if configTable then
        -- 如传入配置表，则使用传入配置表初始化窗口
        -- If configTable is provided, initialize window with it

        logger.logInfo("[windowManager][init] 尝试使用传入配置初始化窗口 / Initializing window with provided config")

        -- 确保传入的配置表包含必要的字段
        -- Ensure configTable contains necessary fields
        configTable.width = configTable.width or currentConfig.width
        configTable.height = configTable.height or currentConfig.height
        configTable.fullscreen = configTable.fullscreen or currentConfig.fullscreen
        configTable.vsync = configTable.vsync or currentConfig.vsync
        configTable.resizable = configTable.resizable or currentConfig.resizable

        -- 设置窗口模式
        -- Set window mode with provided config
        windowManager.setMode(
            configTable.width,
            configTable.height,
            configTable.fullscreen,
            configTable.vsync,
            configTable.resizable
        )
    else
        -- 如未传入配置表，则使用 userSettings 初始化窗口
        -- If no configTable is provided, initialize window with userSettings

        logger.logInfo(string.format(
            "[windowManager][init] 尝试使用用户配置初始化窗口: %dx%d, 全屏: %s, 可调整大小: %s, 垂直同步: %s",
            currentConfig.width, currentConfig.height,
            tostring(currentConfig.fullscreen), tostring(currentConfig.resizable), tostring(currentConfig.vsync)))
        logger.logInfo(string.format(
            "[windowManager][init] Initializing window with user settings: %dx%d, fullscreen: %s, resizable: %s, vsync: %s",
            currentConfig.width, currentConfig.height,
            tostring(currentConfig.fullscreen), tostring(currentConfig.resizable), tostring(currentConfig.vsync)))
        windowManager.setMode(
            currentConfig.width,
            currentConfig.height,
            currentConfig.fullscreen,
            currentConfig.vsync,
            currentConfig.resizable
        )
    end
end

--------------------------------------------------
--- @brief 设置窗口模式，包括分辨率、是否全屏和可调节大小。<br>
--- @brief Set the window mode, including resolution, fullscreen toggle, and resizability.
---
--- @param width (number)       窗口宽度 / Width of the window
--- @param height (number)      窗口高度 / Height of the window
--- @param fullscreen (boolean) 是否全屏显示 / Whether fullscreen mode is enabled
--- @param vsync (boolean)      是否启用垂直同步 / Whether to enable vertical sync
--- @param resizable (boolean)  是否允许调整窗口大小 / Whether the window is resizable by the user
---
--- @return nil
--------------------------------------------------
function windowManager.setMode(width, height, fullscreen, vsync, resizable)
    -- 确保传入的配置表包含必要的字段
    -- Ensure the passed parameters are set or use currentConfig defaults
    currentConfig.width = width or currentConfig.width
    currentConfig.height = height or currentConfig.height
    currentConfig.fullscreen = fullscreen or currentConfig.fullscreen
    currentConfig.vsync = vsync or currentConfig.vsync
    currentConfig.resizable = resizable or currentConfig.resizable

    -- 调用 Love2D 窗口设置函数设置窗口
    -- Call Love2D window setMode function to apply the mode
    love.window.setMode(width, height, {
        fullscreen = currentConfig.fullscreen,
        resizable = currentConfig.resizable,
        vsync = currentConfig.vsync
    })

    logger.logInfo(string.format(
        "[windowManager][setMode] 设置窗口模式: %dx%d, 全屏: %s, 可调整大小: %s, 垂直同步: %s",
        currentConfig.width, currentConfig.height,
        tostring(currentConfig.fullscreen), tostring(currentConfig.resizable), tostring(currentConfig.vsync)))
    logger.logInfo(string.format(
        "[windowManager][setMode] Set window mode: %dx%d, fullscreen: %s, resizable: %s, vsync: %s",
        currentConfig.width, currentConfig.height,
        tostring(currentConfig.fullscreen), tostring(currentConfig.resizable), tostring(currentConfig.vsync)))
end

--------------------------------------------------
--- @brief 获取当前窗口的设置参数，包括宽度、高度、全屏状态等。<br>
--- @brief Get the current window settings such as width, height, and fullscreen state.
---
--- @return (table) WindowModeTable 当前窗口设置表 / A table containing current window settings
--------------------------------------------------
function windowManager.getCurrentMode()
    return {
        width = love.graphics.getWidth(),
        height = love.graphics.getHeight(),
        fullscreen = love.window.getFullscreen(),
        vsync = currentConfig.vsync,
        resizable = currentConfig.resizable
    }
end

--------------------------------------------------
--- @brief Love2D 的回调，用于响应窗口尺寸变化事件。<br>
--- @brief Callback function used by Love2D when window is resized.
---
--- @param w (number) 新宽度 / New window width
--- @param h (number) 新高度 / New window height
---
--- @return nil
--------------------------------------------------
function windowManager.onResize(w, h)
    -- 通知 layoutManager 进行响应处理
    -- Notify layoutManager to handle resize
    layoutManager.onResize(w, h)

    logger.logInfo(string.format(
        "[windowManager][onResize] 窗口尺寸变化 / Window resized: width %d, height %d", w, h))
    print(string.format("[窗口尺寸变化] 新尺寸: %dx%d", w, h))
end

-------------------- 以下为预留 / Placeholder functions --------------------
-------------------- 以下为预留 / Placeholder functions --------------------
-------------------- 以下为预留 / Placeholder functions --------------------


--------------------------------------------------
--- @brief 预留接口：用于设置可用分辨率选项，尚未实现。<br>
--- @brief  Placeholder function to set list of allowed resolutions (not implemented yet).
---
--- @param resList (table) 允许的分辨率表 / List of resolution options (e.g. {{1280, 720}, {1920, 1080}})
---
--- @return nil
--------------------------------------------------
function windowManager.setResolutionList(resList)
    -- 预留功能：例如存入下拉菜单使用 / Placeholder: store for dropdown UI use later
end

return windowManager
