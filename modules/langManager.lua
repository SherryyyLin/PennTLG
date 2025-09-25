-- modules/langManager.lua
-- 语言管理器，支持动态加载、语言切换、系统语言自动检测(待开发)
-- Language manager supporting dynamic loading, language switching, and system language auto-detection(to be developed)

local userSettings = require("modules.userSettings") -- 加载用户设置模块 / Load user settings module
local logger = require("modules.logger")             -- 加载日志模块 / Load logging module

local langManager = {}

local currentLangCode            -- 当前语言码，仅在 langManager.setLanguage 中修改 / Current language code, only modified in langManager.setLanguage
local loadedLangTable = {}       -- 已加载的语言表缓存，避免重复 require / Cache of loaded language tables to avoid repeated requires
local defaultLang = "en_US"      -- 默认语言 / Default language code, used if no user settings are found
local fallbackLang = defaultLang -- fallback 语言 / Default fallback language
local fallbackTable = {}         -- fallback 语言表 / Fallback language table
local missingKeys = {}           -- 缺失 key 记录表 / Table to log missing keys

--------------------------------------------------
--- @brief 初始化语言管理模块，使用传入 langCode 或 userSettings 中的语言设置来初始化语言管理器。</p>
--- @brief Initialize language manager with provided langCode or userSettings configuration.
---
--- @param langCode (string?) 可选的语言码 / Optional language code (e.g. "zh_CN", "en_US")
---                           若未传入则使用 userSettings 设置 / Defaults to userSettings configuration
---
--- @return nil
--------------------------------------------------
function langManager.init(langCode)
    logger.logInfo("[langManager][init] 初始化语言管理器 / Initializing language manager")
    if not userSettings.getLanguageSettings() or userSettings.getLanguageSettings() == nil then -- 确保加载用户设置 / Ensure user settings are loaded
        userSettings.load()
    end
    if langCode then -- 使用传入 langCode 初始化语言模块 / Initialize language with provided langCode
        logger.logInfo("[langManager][init] 使用传入语言初始化语言管理模块 / Initializing language manager with provided langCode: " ..
            langCode)
        langManager.setLanguage(langCode) -- 更新当前语言码 / Update current language code
    else                                  -- 使用 userSettings 初始化语言管理器 / Initialize language manager with userSettings
        logger.logInfo("[langManager][init] 使用用户设置初始化语言管理器 / Initializing language manager with user settings: " ..
            userSettings.getLanguageSettings())
        langManager.setLanguage(userSettings.getLanguageSettings())
    end
end

--------------------------------------------------
--- @brief 设置语言，保存到 userSettings.json 中，并调用 langManager.getLangTable 加载对应语言表。</p>
--- @brief Set the language, save to userSettings.json, and call langManager.getLangTable to load the corresponding language table.
---
--- @param langCode (string) 语言代码 / Language code string (e.g., "zh_CN", "en_US")
---
--- @return nil
--------------------------------------------------
function langManager.setLanguage(langCode)
    if currentLangCode == langCode then -- 如语言未变，不进行处理 / If language hasn't changed, do nothing
        logger.logInfo("[langManager][setLanguage] 语言未变，跳过设置 / Language unchanged, skipping set")
    else                                -- 如语言改变，更新语言码 / Update current language code
        currentLangCode = langCode
        logger.logInfo("[langManager][setLanguage] 设置语言为 / Set language to: " .. langCode)
        userSettings.setLanguageSettings(langCode) -- 保存设置到 userSettings.json 文件中 / Save settings to userSettings.json file
        langManager.getLangTable(langCode)         -- 触发加载语言包，确保缓存更新 / Trigger loading language table to ensure cache is updated
    end
end

--------------------------------------------------
--- @brief 获取语言包表。</p>
--- @brief Get the current language table. Load dynamically from localization files if needed.
---
--- @param langCode (string) 可选的语言码 / Optional language code (e.g. "zh_CN", "en_US")
---
--- @return nil
--------------------------------------------------
function langManager.getLangTable(langCode)
    local langCode = langCode or defaultLang -- 如果没有设置则使用 defaultLang / Use defaultLang if not set

    -- 始终确保 fallbackLang 语言表已加载
    -- Always ensure fallbackLang language table is loaded
    if next(fallbackTable) == nil then
        logger.logInfo("[langManager][getLangTable] 尝试加载语言包 / Attempting to get language table: " .. fallbackLang)
        local ok, result = pcall(require, "localization." .. fallbackLang)
        if ok and type(result) == "table" then
            local fallbackLang_table = result
            loadedLangTable[fallbackLang] = fallbackLang_table
            fallbackTable = fallbackLang_table
            setmetatable(fallbackLang_table, nil)
            logger.logInfo("[langManager][getLangTable] 语言包加载成功 / Language table loaded successfully: " .. fallbackLang)
        else
            local err = result
            logger.logError("[langManager][getLangTable] 加载语言包失败 / Failed to load language table: " .. fallbackLang)
            logger.logErrorTrace(err)
        end
    end

    -- 加载目标语言包,如果已缓存则直接返回（只保留 fallback 语言和当前语言）
    -- Try to load target language table. If already cached, return directly (keep only fallback language and current language)
    if langCode ~= fallbackLang then
        logger.logInfo("[langManager][getLangTable] 尝试加载语言包 / Attempting to get language table: " .. langCode)

        if loadedLangTable[langCode] then
            -- 如果已经缓存，直接返回
            -- If already loaded, return cached version
            logger.logInfo("[langManager][getLangTable] 获取到已缓存的语言包 / Returning cached language table: " .. langCode)
        else
            -- 如没有对应缓存，则尝试加载语言包
            -- If not cached, load the language table
            local ok, result = pcall(require, "localization." .. langCode)
            if not ok or type(result) ~= "table" then
                -- 加载失败 fallback 到 fallbackLang
                -- Fallback to fallbackLang if whole table fails
                local err = result
                logger.logWarn("[langManager][getLangTable] 加载失败：" ..
                    langCode .. " / Failed to load " .. langCode .. ", fallback to " .. fallbackLang)
                logger.logErrorTrace(err)
                langManager.setLanguage(fallbackLang)
            else
                -- 清除除 fallbackLang 和当前语言外的所有缓存
                -- Keep only fallbackLang and current language
                local langTable = result
                for code, _ in pairs(loadedLangTable) do
                    if code ~= fallbackLang and code ~= langCode then
                        loadedLangTable[code] = nil
                        logger.logInfo("[langManager][getLangTable] 清除缓存语言包 / Cleared cached language table: " .. code)
                    end
                end
                -- 设置 fallback
                -- Set fallback
                setmetatable(langTable, { __index = fallbackTable }) -- 使用 fallbackTable 作为默认值 / Use fallbackTable as default values
                loadedLangTable[langCode] = langTable
                logger.logInfo("[langManager][getLangTable] 语言包加载成功 / Language table loaded successfully: " .. langCode)
                --- @deprecated logger.logDebug("[langManager][setLanguage] " .. langManager.tableToString(loadedLangTable[langCode]))
            end
        end
    end
end

--------------------------------------------------
--- @brief 获取当前语言码。</p>
--- @brief Get the current language code.
---
--- @return string currentLangCode 返回当前 langManager 语言码 / Returns the current langManager language code
--------------------------------------------------
function langManager.getCurrentLangCode()
    if not currentLangCode then
        logger.logWarn("[langManager][getCurrentLangCode] 语言码未设置，默认 " ..
            defaultLang " / currentLangCode not set, default " .. defaultLang)
        return defaultLang -- 如果没有设置则默认语言 / If not set, return defaultLang
    else
        logger.logInfo("[langManager][getCurrentLangCode] 当前语言码为 / Current language code is: " .. currentLangCode)
        return currentLangCode
    end
end

--------------------------------------------------
--- @brief 获取 fallback 语言码。</p>
--- @brief Get the fallback language code.
---
--- @return string fallbackLang 返回当前 langManager 语言码 / Returns the current langManager language code
--------------------------------------------------
function langManager.getfallbackLangCode()
    logger.logInfo("[langManager][getCurrentLangCode] 当前 fallback 语言码为 / Current fallback language code is: " ..
        fallbackLang)
    return fallbackLang
end

--------------------------------------------------
--- @brief 遍历路径字符串获取值（如 "ui.menu.exit"）。仅在langManager.getText中调用。</p>
--- @brief Traverse language table with dotted path (e.g. "ui.menu.exit"). Only called by langManager.getText
---
--- @param langTable (table) 语言表 / Language table
--- @param path (string) 点号路径 / Dotted path string
---
--- @return string|nil text 对应文本或nil / Text if found, or nil
--------------------------------------------------
local function traversePath(langTable, path)
    local current = langTable
    for key in string.gmatch(path, "[^%.]+") do           -- 使用点号分隔路径 / Split path by dots
        if type(current) == "table" and current[key] then -- 检查当前是否为表且包含该键 / Check if current is a table and contains the key
            current = current[key]
        else
            missingKeys[path] = true
            return nil
        end
    end
    return current
end

--------------------------------------------------
--- @brief 主查询函数，路径访问语言表，获取对应的语言文本。
--- @brief Main query function to access language table and get localized text.
---
--- @param path (string)         路径字符串 / Key path string
--- @param defaultText (string?) 可选的 fallback 文本 / Optional fallback text
---
--- @return string text          对应语言文本或默认值 / Localized text or fallback
--------------------------------------------------
function langManager.getText(path, defaultText)
    --- @deprecated local returnDefaultText = defaultText or nil -- 如果没有提供默认文本，则为 nil / If no default text provided, set to nil

    -- 基础检查和初始化
    -- Basic checks and initialization
    if next(loadedLangTable[currentLangCode]) == nil then -- 确保加载语言包 / Ensure language table is loaded
        langManager.getLangTable(currentLangCode)
    end

    if next(fallbackTable) == nil then -- 确保 fallback 语言包已加载 / Ensure fallback language table is loaded
        langManager.getLangTable(fallbackLang)
    end

    if not path or type(path) ~= "string" or path == "" then -- 检查路径有效性 / Check if path is valid
        logger.logError("[langManager][getText] 无效的路径 / Invalid path provided")
        return "Invalid path"
    end

    -- 遍历路径获取值
    -- Traverse the path to get the value
    local value = traversePath(loadedLangTable[currentLangCode], path)
    if value ~= nil then
        return value
    elseif currentLangCode ~= fallbackLang then
        local fallbackValue = traversePath(fallbackTable, path)
        if fallbackValue ~= nil then
            return fallbackValue
        end
    end

    -- 如果没有找到对应的文本，返回默认文本或缺失提示
    -- If no text found, return default text or missing key message
    if defaultText ~= nil then
        return defaultText
    elseif currentLangCode == fallbackLang then
        return "Fallback Language - Invalid Path"
    else
        return "Current Language - Invalid Path"
    end
end

--------------------------------------------------
--- @brief 支持 {变量} 占位符替换的文本获取
--- @brief Get text with {variable} placeholder replacement
---
--- @param path (string)         路径字符串 / Key path string
--- @param vars (table)          占位变量表 / Placeholder replacement table
--- @param defaultText (string?) 可选的 fallback 文本 / Optional fallback text
---
--- @return string text          对应语言文本或默认值 / Localized text or fallback
--------------------------------------------------
function langManager.getFormatted(path, vars, defaultText)
    local rawText = langManager.getText(path, defaultText) -- 获取原始字符串 / Get raw text

    -- 报错直接返回
    -- If rawText is an error message, return it directly
    if rawText == "Fallback Language - Invalid Path" then
        return "Fallback Language - Invalid Path"
    elseif rawText == "Current Language - Invalid Path" then
        return "Current Language - Invalid Path"
    end

    -- 占位符替换：将 {key} 替换为 vars[key]
    -- Placeholder replacement: replace {key} with vars[key]
    return (rawText:gsub("{(.-)}", function(k)
        return tostring(vars and vars[k] or "{" .. k .. "}")
    end))
end

-- 以下为 Debug 使用
-- The following is for debugging purposes

--------------------------------------------------
--- @brief 打印所有缺失的语言 key
--- @brief Print all missing keys
---
--- @return nil
--------------------------------------------------
function langManager.reportMissing()
    for key in pairs(missingKeys) do
        print("[MissingLangKey] " .. key)
        logger.logDebug("[langManager][reportMissing] Missingkey: " .. key)
    end
end

--------------------------------------------------
--- @brief 将表转换为字符串，便于调试和查看
--- @brief Convert table to string for debugging and viewing
---
--- @param tbl (table)      需要转换的表 / Table to convert
--- @param indent (number?) 缩进级别，默认为0 / Indentation level, default is 0
---
--- @return string toprint  返回转换后的字符串 / Returns the converted string
--------------------------------------------------
function langManager.tableToString(tbl, indent)
    indent = indent or 0
    local toprint = string.rep("  ", indent) .. "{\n"
    indent = indent + 1
    for key, value in pairs(tbl) do
        toprint = toprint .. string.rep("  ", indent)
        toprint = toprint .. tostring(key) .. " = "
        if type(value) == "table" then
            toprint = toprint .. langManager.tableToString(value, indent) .. ",\n"
        else
            toprint = toprint .. tostring(value) .. ",\n"
        end
    end
    toprint = toprint .. string.rep("  ", indent - 1) .. "}"
    return toprint
end

return langManager
