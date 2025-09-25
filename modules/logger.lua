-- modules/logger.lua
-- 记录调试和运行日
-- Logging with levels, timestamp, and file output
------------------- file path -------------------
--- Windows:   C:\Users\<user>\AppData\Roaming\LOVE\TLG\log\
--- macOS:     ~/Library/Application Support/LOVE/TLG/log/
--- Linux:     ~/.local/share/love/TLG/log/
------------------- file path -------------------

local logger = {}

local folderPath = "log" -- 创建日志文件路径 / Create log file path
local logLevels = {      -- 定义日志等级映射表 / Define log level mapping table
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}
local currentLevel = logLevels.DEBUG -- 日志等级阈值，低于该等级将被过滤 / Logs below this level will be ignored
local logRetentionDays = 7           -- 日志保留天数 / Number of days to retain logs
logger.enableConsole = true          -- 是否启用控制台输出 / Whether to enable console output

--------------------------------------------------
--- @brief 获取当前系统时间字符串，格式为 "YYYY-MM-DDTHH-MM-SS"。<br>
--- @brief Get current system time string in format "YYYY-MM-DDTHH-MM-SS".
---
--- @return string TimeString 格式化后的时间字符串 / Formatted timestamp string
--------------------------------------------------
local function getTimeString()
    TimeString = tostring(os.date("%Y-%m-%dT%H-%M-%S"))
    return TimeString
end

local bootTime = os.time()                                             -- 程序启动时固定时间戳 / Get timestamp at program start
local bootTimeString = getTimeString()                                 -- 程序启动时固定时间戳(String) / Get timestamp at program start (String)
local logFilePath = folderPath .. "/main_" .. bootTimeString .. ".log" -- 日志文件路径 / Log file path

--------------------------------------------------
--- @brief 加载日志模块时删除超过特定天数的文件。<br>
--- @brief Load logger module and delete files older than specified days.
---
--- @param retainedDays (number?) 可选的日志保留天数 / Optional number of days to retain logs
--- @param bootTimeString (string?)    可选的启动时间戳，默认为当前时间戳 / Optional boot timestamp, defaults to current time
---
--- @return nil
--------------------------------------------------
function logger.init(retainedDays, bootTimeString)
    -- 确保文件夹存在
    -- Ensure folder exists
    love.filesystem.createDirectory(folderPath)

    -- 获取启动时间戳，确定该次启动日志文件名
    -- Get boot time, determine log file name for this session
    if bootTimeString == nil then
        bootTimeString = getTimeString()
        logFilePath = folderPath .. "/main_" .. bootTimeString .. ".log"
    end

    -- 获取日志文件夹中所有文件名
    -- Get all filenames in log folder
    local files = love.filesystem.getDirectoryItems(folderPath)

    -- 遍历文件列表，删除过期日志文件
    -- Iterate through file list and delete old log files
    for _, filename in ipairs(files) do
        -- 构建完整路径
        -- Construct full file path
        local filePath = folderPath .. "/" .. filename

        -- 只处理 .log 结尾的文件
        -- Only process .log files
        if filename:match("%.log$") then
            -- 获取文件最后编辑时间
            -- Get file last modified time
            local info = love.filesystem.getInfo(filePath)
            if info and info.modtime then
                -- 比较文件修改时间与当前时间的差值
                -- Compare file modification time with current time
                local ageInSeconds = bootTime - info.modtime

                -- 如果传入了保留天数，则使用该值
                -- Use provided retention days if given
                if retainedDays then
                    logRetentionDays = retainedDays
                end

                -- 删除超过特定天数的文件
                -- Delete files older than specified days
                if ageInSeconds > logRetentionDays * 24 * 60 * 60 then
                    love.filesystem.remove(filePath)
                    logger.logInfo("[logger][init] 删除过期日志 / Deleted old log: " .. filename)
                end
            end
        end
    end
    logger.logInfo("[logger][init] 日志模块初始化完成 / Logger module initialized: " .. logFilePath)
end

--------------------------------------------------
--- @brief 日志写入函数，(默认等级为INFO)。<br>
--- @brief Log writing function (Default to INFO level).
---
--- @param logMessage (string) 日志内容 / Message content
--- @param level (string?)     日志等级 / Optional log level string (DEBUG, INFO, WARN, ERROR)
---
--- @return nil
--------------------------------------------------
function logger.log(logMessage, level)
    level = level or "INFO"
    local levelUpper = string.upper(level)
    local levelValue = logLevels[levelUpper] or logLevels.INFO

    -- 跳过低于设定等级日志
    -- Skip if below current logging level
    if levelValue < currentLevel then return end

    -- 构建完整日志行
    -- Build full log line
    local timeStamp = os.date("%Y-%m-%d %H:%M:%S")
    local fullMessage = string.format("[%s] [%s] %s", timeStamp, levelUpper, tostring(logMessage))

    -- 写入日志文件
    -- Write to file
    love.filesystem.append(logFilePath, fullMessage .. "\n")

    -- 输出到控制台
    -- Print to console
    if logger.enableConsole then
        print(fullMessage)
    end
end

--------------------------------------------------
--- @brief 记录报错堆栈，用于调试 Lua 错误来源。<br>
--- @brief Log full Lua error stack trace, useful for debugging source of runtime errors.
---
--- @param msg (string) 错误信息内容 / Error message content
---
--- @return nil
--------------------------------------------------
function logger.logErrorTrace(msg)
    local trace = debug.traceback(msg, 2) -- 获取当前堆栈追踪 / Get stack trace
    logger.log(trace, "ERROR")            -- 使用 ERROR 等级记录完整堆栈 / Log the full stack at ERROR level
end

-- 快捷封装函数
-- Shortcut wrappers

--------------------------------------------------
--- @brief DEBUG 等级日志封装。<br>
--- @brief Wrapper for DEBUG level logging.
---
--- @param logMessage (string) 日志内容 / Log message content
---
--- @return nil
--------------------------------------------------
function logger.logDebug(logMessage)
    logger.log(logMessage, "DEBUG")
end

--------------------------------------------------
--- @brief INFO 等级日志封装。<br>
--- @brief Wrapper for INFO level logging.
---
--- @param logMessage (string) 日志内容 / Log message content
---
--- @return nil
--------------------------------------------------
function logger.logInfo(logMessage)
    logger.log(logMessage, "INFO")
end

--------------------------------------------------
--- @brief WARN 等级日志封装。<br>
--- @brief Wrapper for WARN level logging.
---
--- @param logMessage (string) 日志内容 / Log message content
---
--- @return nil
--------------------------------------------------
function logger.logWarn(logMessage)
    logger.log(logMessage, "WARN")
end

--------------------------------------------------
--- @brief ERROR 等级日志封装。<br>
--- @brief Wrapper for ERROR level logging.
---
--- @param logMessage (string) 日志内容 / Log message content
---
--- @return nil
--------------------------------------------------
function logger.logError(logMessage)
    logger.log(logMessage, "ERROR")
end

return logger
