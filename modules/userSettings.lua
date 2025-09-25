-- modules/userSettings.lua
-- 负责从 JSON 文件加载和保存用户设置
-- 所有设置都存储在 config/userSettings.json 文件中
-- Handle loading and saving user settings from/to a JSON file
-- All settings are stored in the config/userSettings.json file


local json = require("modules.dkjson")   -- 加载 dkjson 模块用于 JSON 编解码 / Load dkjson module for JSON encoding/decoding
local logger = require("modules.logger") -- 加载日志模块 / Load logging module

local userSettings = {}

-- 设置文件相对于 LOVE 用户目录的路径<br>
-- Config file path relative to LOVE save directory
local configPath = "config/userSettings.json"
-------------------- config file path --------------------
-- Windows:   C:\Users\<user>\AppData\Roaming\LOVE\TLG\config\userSettings.json
-- macOS:     ~/Library/Application Support/LOVE/TLG/config/userSettings.json
-- Linux:     ~/.local/share/love/TLG/config/userSettings.json
-------------------- config file path --------------------

-- 默认设置表<br>
-- Default settings table
local defaultSettings = {
    language = "en_US",       -- 默认语言：英文 / Default language: English
    display = {
        width = 1280,         -- 默认宽度 / Default width
        height = 720,         -- 默认高度 / Default height
        fullscreen = false,   -- 是否为全屏模式 / Whether to use fullscreen mode
        resizable = true,     -- 是否允许用户拖动调整窗口大小 / Whether to allow user to resize window
        vsync = true,         -- 是否开启垂直同步 / Whether to enable vertical sync
    },
    volume = {                -- 音量设置 / Volume settings
        music = 1.0,          -- 音乐音量 / Music volume
        sfx = 1.0,            -- 音效音量 / Sound effects volume
        mute = false          -- 是否静音 / Whether to mute all sounds
    },
    network = {               -- 联网玩家昵称
        playerName = "Player" -- 默认昵称
    }
}


-- 当前内存中存储的设置表<br>
-- Holds the current settings in memory
userSettings.data = {}

--------------------------------------------------
--- @brief 递归合并默认设置与加载的用户设置，缺失项使用默认值。<br>
--- @brief Recursively merge default settings with loaded user settings, fallback to defaults when missing.
---
--- @param defaults (table) 默认设置表 / Table containing default values
--- @param loaded (table)   已加载的用户设置表 / Table loaded from config file
---
--- @return table result    合并后的最终设置表 / Merged settings table
--------------------------------------------------
local function mergeTable(defaults, loaded)
    local result = {}
    for k, v in pairs(defaults) do
        if type(v) == "table" and type(loaded[k]) == "table" then
            result[k] = mergeTable(v, loaded[k])
        else
            result[k] = loaded[k] ~= nil and loaded[k] or v
        end
    end
    return result
end

--------------------------------------------------
--- @brief 从配置文件中加载设置，如果不存在则使用默认设置并保存。<br>
--- @brief Load settings from config file, fallback to default settings if file not found or invalid.
---
--- @return nil
--------------------------------------------------
function userSettings.load()
    love.filesystem.createDirectory("config")                   -- 若 config 文件夹不存在，则创建
    if love.filesystem.getInfo(configPath) then                 -- 设置文件存在：读取并解析
        local contents, size = love.filesystem.read(configPath) -- 读取整个 JSON 文件内容
        local parsed, pos, err = json.decode(contents)          -- 解析 JSON 字符串
        logger.logDebug("[userSettings][load] 读取到的contents内容:\n" .. tostring(contents))
        logger.logDebug("[userSettings][load] 读取到的parsed内容:\n" .. tostring(parsed))
        if parsed and type(parsed) == "table" then
            logger.logInfo("[userSettings][load] 用户配置文件加载成功，尝试检查并合并缺失项")
            userSettings.data = mergeTable(defaultSettings, parsed)
        else
            logger.logWarn("[userSettings][load] 设置文件无效或缺失，使用默认配置" .. tostring(err))
            userSettings.data = defaultSettings
            userSettings.save()
        end
    else
        logger.logWarn("[userSettings][load] 未找到设置文件，使用默认设置")
        userSettings.data = defaultSettings
        userSettings.save()
    end
end

--------------------------------------------------
--- @brief 保存当前设置到 config/userSettings.json 文件。<br>
--- @brief Save current settings to config/userSettings.json file.
---
--- @return nil
--------------------------------------------------
function userSettings.save()
    local encoded = json.encode(userSettings.data, { indent = true }) -- 将表编码成 JSON 字符串，格式化输出
    love.filesystem.write(configPath, encoded)                        -- 将 JSON 字符串写入文件
end

--------------------------------------------------
--- @brief 设置语言码并保存(仅在langManager.lua中调用)。<br>
--- @brief Set the language code and save.
---
--- @param langCode (string) 语言代码（如 "zh_CN", "en_US"）/ Language code (e.g., "zh_CN", "en_US")
---
--- @return nil
--------------------------------------------------
function userSettings.setLanguageSettings(langCode)
    userSettings.data.language = langCode
    logger.logInfo("[userSettings][setLanguage] 设置语言为 / Set language to: " .. langCode)
    userSettings.save()
end

--------------------------------------------------
--- @brief 获取语言设置（若未加载则自动加载）。<br>
--- @brief Get saved language setting (lazy-load if missing).
---
--- @return string language 设置的语言代码 / The currently configured language code
--------------------------------------------------
function userSettings.getLanguageSettings()
    if not userSettings.data.language then
        userSettings.load()
    end
    return userSettings.data.language
end

--------------------------------------------------
--- @brief 设置显示配置（如窗口大小、全屏等）
--- @brief Set display-related configuration
---
--- @param width (number?)         窗口宽度 / Window width
--- @param height (number?)        窗口高度 / Window height
--- @param fullscreen (boolean?)   是否全屏 / Whether to go fullscreen
--- @param vsync (boolean?)        是否启用垂直同步 / Whether to enable vertical sync
--- @param resizable (boolean?)    是否可调整大小 / Whether window is resizable
---
--- @return nil
--------------------------------------------------
function userSettings.setDisplaySettings(width, height, fullscreen, vsync, resizable)
    userSettings.data.display.width = width or userSettings.data.display.width
    userSettings.data.display.height = height or userSettings.data.display.height
    userSettings.data.display.fullscreen = fullscreen or userSettings.data.display.fullscreen
    userSettings.data.display.vsync = vsync or userSettings.data.display.vsync
    userSettings.data.display.resizable = resizable or userSettings.data.display.resizable
    userSettings.save()
end

--------------------------------------------------
--- @brief 获取当前显示设置（如果未加载则先加载）。<br>
--- @brief Get current display settings (lazy-load if needed).
---
--- @return table displaySettings 包含 width, height, fullscreen, vsync 等字段 / Table with display fields
--------------------------------------------------
function userSettings.getDisplaySettings()
    if not userSettings.data.display then
        userSettings.load()
    end
    return {
        width = userSettings.data.display.width or 1280,
        height = userSettings.data.display.height or 720,
        fullscreen = userSettings.data.display.fullscreen or false,
        vsync = userSettings.data.display.vsync or true,
        resizable = userSettings.data.display.resizable or true
    }
end

--------------------------------------------------
--- 联机部分 用户设置 （未开发）
--- Network User settings (Undeveloped)
--------------------------------------------------

--------------------------------------------------
--- @brief 设置玩家昵称 / Set player nickname
---
--- @param name (string) 昵称字符串 / Nickname string
---
--- @return nil
--------------------------------------------------
function userSettings.setPlayerName(name)
    userSettings.data.network.playerName = name
    userSettings.save()
end

--------------------------------------------------
--- @brief 获取玩家昵称（若未加载则先加载）/ Get player nickname (lazy-load if needed)
---
--- @return string playerName 玩家设置的昵称或默认 "Player" / Player nickname or default "Player"
--------------------------------------------------
function userSettings.getPlayerName()
    if not userSettings.data.network or not userSettings.data.network.playerName then
        userSettings.load()
    end
    return userSettings.data.network.playerName or "Player"
end

return userSettings
