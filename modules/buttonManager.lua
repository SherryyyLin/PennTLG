-- modules/buttonManager.lua
-- 按钮管理模块，支持多个按钮状态管理 + 悬停/点击判断等。
-- button module, supports multiple button states management + hover/click detection, etc.

local logger = require("modules.logger")               -- 加载日志模块 / Load logging module
local layoutManager = require("modules.layoutManager") -- 加载布局管理模块 / Load layout manager module
local buttonConfig = require("config.buttonConfig")    -- 加载配置文件 / Load config file

local buttonManager = {}

-- 所有按钮配置
-- All button configurations
local buttons = {} -- buttons[id] -> config

-- 按钮默认配置
-- Default button config
local default = buttonConfig.default

-- 当前页面名称
-- Current interface name
local currentInterface = "menu"


--------------------------------------------------
--- @brief 内部函数：将嵌套按钮配置表拍平成一维表，并提取 meta 字段用于参数传递。<br>
--- @brief Internal function: Flatten nested button config into a single-level table, and extract meta fields.
---
--- @param id (string)          按钮 ID / Button ID
--- @param config (table)       按钮配置 / Full button config with grouped fields
---
--- @return (table) flatConfig  拍平后的配置表 / Flattened config for button.create
--- @return (table) meta        额外提取的元信息 / Separate meta info for direct use
--------------------------------------------------
local function flattenConfig(id, config)
    --- 拍平的元数据表<br>
    --- Flattened meta table
    local meta = {}
    --- 拍平后的完整配置表
    --- Flattened config table
    local flatConfig = {}

    --- 遍历各字段组：meta 单独提取，全部字段拍平合并入 flatConfig<br>
    --- Iterate through sections: extract meta separately, flatten and merge all other fields into flatConfig
    for key, data in pairs(config) do
        if type(data) == "table" then
            if key == "meta" then
                --- 提取 meta 字段(id, interface, group, tags, dependencies)<br>
                --- Extract meta fields (id, interface, group, tags, dependencies)
                for k, v in pairs(data) do
                    if type(v) == "table" then
                        --- 避免嵌套表导致的配置错误<br>
                        --- Avoid configuration errors caused by nested tables
                        if logger and logger.logWarn and type(v[1]) == "table" then
                            logger.logWarn("[buttonManager][flattenConfig] 发现嵌套表，可能配置错误 / Nested table found in key: " ..
                                tostring(key))
                        end
                    else
                        --- 执行提取 meta 字段，并同步提取进 flatConfig<br>
                        --- Directly extract meta fields and synchronize extraction into flatConfig
                        meta[k] = v
                        flatConfig[k] = v
                    end
                end
            else
                --- 提取其他字段组<br>
                --- Extract other fields
                for k, v in pairs(data) do
                    if type(v) == "table" then
                        --- 避免嵌套表导致的配置错误<br>
                        --- Avoid configuration errors caused by nested tables
                        if logger and logger.logWarn and type(v[1]) == "table" then
                            logger.logWarn("[buttonManager][flattenConfig] 发现嵌套表，可能配置错误 / Nested table found in key: " ..
                                tostring(key))
                        end
                    elseif v ~= nil then
                        --- 执行提取其他字段<br>
                        --- Directly extract other fields
                        flatConfig[k] = v
                    end
                end
            end
        elseif type(data) ~= "table" then
            --- 如果是非表类型数据，无需拍平
            --- If it's a non-table type, no need to flatten
            if key == "id" or key == "interface" or key == "group" or key == "tags" or key == "dependencies" then
                --- 直接提取 id, interface, group 等元信息
                --- Directly extract id, interface, group as meta info
                meta[key] = data
                flatConfig[key] = data
            else
                flatConfig[key] = data
            end
        end
    end
    return flatConfig, meta
end

--------------------------------------------------
--- @brief 初始化指定界面的按钮（自动从 config 中读取）。<br>
--- @brief Initialize buttons for a specific interface (automatically read from config).
---
--- @param interface (string)   页面名 / Interface name
---
--- @return nil
--------------------------------------------------
function buttonManager.init(interface)
    -- 从 buttonConfig 中获取特定页面按钮配置
    -- Get specific interface button config from buttonConfig
    if not buttonConfig.button or not buttonConfig.button[interface] then
        logger.logError("[buttonManager][init] 未找到页面按钮配置 / No button config found for interface: " .. tostring(interface))
        return
    end

    -- 将未拍平配置表存储在 buttonGroup 中
    -- Store the unflattened config table in buttonGroup
    local buttonGroup = buttonConfig.button[interface]
    logger.logDebug("[buttonManager][init] 初始化按钮组 / Initializing button group for interface: " ..
        "button[" .. tostring(interface) .. "]" .. tostring(buttonGroup))

    -- 设置当前界面名
    -- Set the current interface name
    currentInterface = interface
    layoutManager.setCurrentInterface(currentInterface)

    -- 遍历配置的按钮组，调用 buttonManager.create 创建按钮
    -- Iterate through the configured button group and call buttonManager.create to create the button
    for key, config in pairs(buttonGroup) do
        -- 调用内部函数 flattenConfig 将 buttonGroup 中未拍平配置拍平
        -- Call internal function flattenConfig to flatten the unflattened config in buttonGroup
        local flatConfig, meta = flattenConfig(key, config)

        -- 校验 meta.id 是否存在（按钮唯一标识）
        -- Validate if meta.id exists (unique button identifier)
        if not meta.id then
            logger.logError("[buttonManager][init] 缺少 id / Missing id (entry key: " .. tostring(key) .. ")")
            return
        end

        -- 调用 buttonManager.create 创建按钮
        -- Call buttonManager.create to create the button
        logger.logInfo("[buttonManager][init] 尝试创建按钮 / Attempting to create button: " .. meta.id)
        buttonManager.create(meta.id, flatConfig, meta.group, currentInterface, meta)
    end

    -- 清理非当前界面的按钮（如果 shouldDestroyOnExit == true）
    -- Clear buttons not belonging to current interface (if shouldDestroyOnExit == true)
    buttonManager.clearUnused(currentInterface)

    logger.logInfo("[buttonManager][init] 按钮初始化完成 / Button initialization complete for interface: " .. interface)
end

--------------------------------------------------
--- @brief 卸载非当前界面的按钮（如果设置了 shouldDestroyOnExit）。<br>
--- @brief Clear buttons not belonging to current interface if they are marked destroyable.
---
--- @param interface (string)   指定页面名(该页面不卸载) / Specified interface name (this interface will not be cleared)
---
--- @return nil
--------------------------------------------------
function buttonManager.clearUnused(interface)
    -- 计数器（用于 Debug）
    -- Counter for destroyed buttons (for Debug)
    local count = 0

    -- 遍历所有按钮，检查是否属于当前界面
    -- Iterate through all buttons, check if they belong to the current interface
    for id, config in pairs(buttons) do
        if config.interface ~= interface and (config.shouldDestroyOnExit ~= false) then
            logger.logDebug("[buttonManager][clearUnused] 尝试销毁按钮 / Attempting to destroy button: " .. tostring(id))
            buttonManager.destroy(id)
            count = count + 1
        end
    end
    logger.logDebug("[buttonManager][clearUnused] 共清理按钮数量 / Total cleared buttons: " .. count)
end

--------------------------------------------------
--- @brief 销毁指定按钮，释放其所有状态并从注册表中移除。<br>
--- @brief Destroy a specified button, release its state and remove from registry.
---
--- @param id (string) 按钮唯一标识符 / Unique identifier of the button to destroy
---
--- @return nil
--------------------------------------------------
function buttonManager.destroy(id)
    -- 检查按钮是否存在于按钮状态表中
    -- Check if the button exists in the button state table
    if not buttons[id] then
        logger.logWarn("[buttonManager][destroy] 尝试销毁不存在的按钮 / Attempted to destroy non-existent button: " .. tostring(id))
        return
    end

    local button = buttons[id]

    -- 如有绑定的资源，可在此处手动清理（如贴图、回调、输入框等）
    -- If the button has allocated resources, manually release them here (e.g., image, callbacks, input fields)

    -- TODO: 可在此拓展资源释放逻辑
    -- TODO: Extend cleanup logic here as needed

    -- 从按钮状态表中移除
    -- Remove button from the state table
    buttons[id] = nil

    -- 记录销毁日志
    -- Log destruction
    logger.logDebug("[buttonManager][destroy] 按钮已销毁 / Button destroyed: " .. tostring(id))
end

--------------------------------------------------
--- @brief 内部函数：合并默认配置和输入配置，未设置的使用默认值。<br>
--- @brief Internal function: Merge default config and input config, using defaults for unset values.
---
--- @param flattenInputConfig (table)   输入的拍平配置表 / Flattened input config table
--- @param flattenDefault (table)       默认的拍平配置表 / Flattened default config table
--- @return (table) flattenInputConfig  合并后的配置表 / Merged config table
-----------------------------------------------------
local function mergeDefaults(flattenInputConfig, flattenDefault)
    if type(flattenInputConfig) ~= "table" then
        logger.logError("[buttonManager][mergeDefaults] 输入配置不是表 / Input config is not a table")
        return flattenInputConfig
    end

    for key, value in pairs(flattenDefault) do
        if flattenInputConfig[key] == nil then
            flattenInputConfig[key] = value
        end
    end
    return flattenInputConfig
end

-----------------------------------------------------
--- @brief 内部函数：从源表中提取指定键的值，返回一个新表。<br>
--- @brief Internal function: Extract specified keys from source table, returning a new table.
---
--- @param sourceTable (table)  源表 / Source table to extract from
--- @param keys (table)         要提取的键列表 / List of keys to extract
---
--- @return (table) newTable    新表，包含指定键的值 / New table containing specified keys and their values
-----------------------------------------------------
local function extractKeys(sourceTable, keys)
    local newTable = {}
    for _, key in ipairs(keys) do
        if sourceTable[key] ~= nil then
            newTable[key] = sourceTable[key]
        end
    end
    return newTable
end

-----------------------------------------------------
--- @brief 内部函数：如果传入值是 nil，就返回默认值；否则返回原值（即使是 false 也保留）。<br>
--- @brief Internal function: Return default if value is nil; otherwise return original value (even if false).
---
--- @param value (any)      传入值 / Input value
--- @param default (any)    默认值 / Default value
---
--- @return (any) result    传入值或默认值 / Input value or default
-----------------------------------------------------
local function withDefault(value, default)
    if value == nil then return default end
    return value
end

--------------------------------------------------
--- @brief 创建并注册一个按钮（包括布局）。<br>
--- @brief Create and register a button, including layout registration.
---
--- @param id (string)          唯一的按钮ID / Unique button ID
--- @param config (table)       配置表(扁平) / Configuration table (flattened)
--- @param group (string?)      分组名 / Group name (optional, default is "default")
--- @param interface (string?)  页面名 / Interface name (optional, defaults to currentInterface)
--- @param meta (table?)        元信息 / Meta info
---     meta: id, group, interface, tags, dependencies, shouldDestroyOnExit
---
--- @return nil
--------------------------------------------------
function buttonManager.create(id, config, group, interface, meta)
    -- 设置默认分组和界面名
    -- Set default group and interface name if not provided
    local group = group or "default"
    local interface = interface or currentInterface

    -- 检查参数是否有效
    -- Check if id and config are provided
    if not id or not config then
        logger.logError("[button][create] 缺少参数 / Missing parameters : id = " ..
            tostring(id) .. ", config = " .. tostring(config))
        return
    end

    -- 获取拍平后的传入配置
    -- Get the flattened input config
    local flattenInputConfig, inputMeta = flattenConfig(config)

    -- 获取拍平后的默认配置
    -- Get the flattened default config
    local flattenDefault = flattenConfig(default)

    -- 遍历合并配置，未设置的使用默认值
    -- Merge style config, use defaults for unset values
    local finalConfig = mergeDefaults(flattenInputConfig or {}, flattenDefault or {})
    logger.logDebug("[button][create] 合并配置 / Merged config: " .. tostring(finalConfig))

    -- 提取 layout 相关键值对（锚点、XY偏移量、zIndex）
    -- Extract layout related keys (anchor, offsetX, offsetY, zIndex)
    local layout = extractKeys(finalConfig, { "anchor", "offsetX", "offsetY", "zIndex" })

    -- 注册 layout 布局
    -- Register layout with layoutManager
    local ok, result = pcall(function()
        layoutManager.register(id, layout, interface, group, meta)
    end)
    if not ok then
        local err = result
        logger.logError("[button.create] 布局注册失败 / Layout registration failed for: " .. id)
        logger.logErrorTrace(tostring(err))
    end

    -- 注册按钮状态
    -- Register final button object
    buttons[id] = {
        -- meta                                                                   -- 元信息 / Meta Information
        id = id or finalConfig.id or "untitled-id",                               -- -- 按钮唯一ID / Unique button ID
        interface = interface or finalConfig.interface or "default",              -- -- 所属界面 / Interface this button belongs to
        group = group or finalConfig.group or "default",                          -- -- 分组名 / Group for batch control
        tags = finalConfig.tags or {},                                            -- -- 标签 / Tags for classification
        dependencies = finalConfig.dependencies or {},                            -- -- 依赖模块列表 / List of required modules
        shouldDestroyOnExit = withDefault(finalConfig.shouldDestroyOnExit, true), -- -- 是否在界面退出时销毁 / Whether to destroy this button when exiting the interface
        -- content                                                                -- 内容配置 / Content Configuration
        label = finalConfig.label or "untitled",                                  -- -- 按钮文本 / Button text
        iconImage = finalConfig.iconImage,                                        -- -- 可选图标 / Optional icon image
        -- layout                                                                 -- 布局配置 / Layout Configuration
        anchor = finalConfig.anchor or "center",                                  -- -- 锚点位置 / Anchor point
        offsetX = finalConfig.offsetX,                                            -- -- X轴偏移量 / Horizontal offset
        offsetY = finalConfig.offsetY,                                            -- -- Y轴偏移量 / Vertical offset
        zIndex = finalConfig.zIndex,                                              -- -- 绘制层级（值越高越晚绘制） / Drawing order (higher = top)
        -- displayControl                                                         -- 显示控制 / Display Control
        visible = withDefault(finalConfig.visible, true),                         -- -- 是否显示 / Whether to display the button
        -- style                                                                  -- 基础样式 / Visual Style
        font = finalConfig.font,                                                  -- -- 字体 / Font
        textColor = finalConfig.textColor,                                        -- -- 字体颜色 / Text color (RGB 0~1)
        shadow = finalConfig.shadow,                                              -- -- 是否有阴影 / Enable shadow
        width = finalConfig.width,                                                -- -- 按钮宽度 / Width
        height = finalConfig.height,                                              -- -- 按钮高度 / Height
        padding = finalConfig.padding,                                            -- -- 内边距 / Inner padding
        backgroundColor = finalConfig.backgroundColor,                            -- -- 背景颜色 / Background color
        backgroundImage = finalConfig.backgroundImage,                            -- -- 背景图像 / Optional background image
        borderColor = finalConfig.borderColor,                                    -- -- 边框颜色 / Border color
        borderWidth = finalConfig.borderWidth,                                    -- -- 边框宽度 / Border width
        roundedCorners = finalConfig.roundedCorners,                              -- -- 是否启用圆角 / Enable rounded corners
        cornerRadius = finalConfig.cornerRadius,                                  -- -- 圆角半径 / Radius in pixels
        -- hoverStyle                                                  -- 悬停时样式 / Style to apply when mouse is over button
        hoverBackgroundColor = finalConfig.hoverBackgroundColor,                  -- -- 悬停时背景颜色 / Hover background
        -- pressedStyle                                                -- 按下时样式 / Style to apply when button is pressed
        pressedBackgroundColor = finalConfig.pressedBackgroundColor,              -- -- 按下时背景颜色 / Pressed background
        -- logic                                                       -- 逻辑配置 / Logic Handlers
        onClick = finalConfig.onClick,                                            -- -- 点击时的函数 / Function to execute on click
        onHold = finalConfig.onHold,                                              -- -- 可选：长按触发 / Optional: Trigger on hold
        onHoverEnter = finalConfig.onHoverEnter,                                  -- -- 鼠标悬停进入时的函数 / Function when mouse enters button
        onHoverExit = finalConfig.onHoverExit,                                    -- -- 鼠标悬停离开时的函数 / Function when mouse exits button
        checkEnabled = finalConfig.checkEnabled,                                  -- -- 可动态控制是否禁用 / Dynamically enable/disable（如当玩家资源不足时禁用按钮。）
        -- access                                                      -- 访问控制 / Access Control
        tooltip = finalConfig.tooltip,                                            -- -- 鼠标悬停提示文本 / Tooltip text when hovered
        hotkey = finalConfig.hotkey,                                              -- -- 绑定的快捷键 / Keyboard shortcut key
        cooldown = finalConfig.cooldown,                                          -- -- 冷却时间，单位为秒 / Time in seconds to block repeated clicks
        repeatable = withDefault(finalConfig.repeatable, false),                  -- -- 是否支持长按重复触发点击 / Enable click repeat when held
        locked = withDefault(finalConfig.locked, false),                          -- -- 是否为锁定状态 / Whether it is locked or not
        disabled = withDefault(finalConfig.disabled, false),                      -- -- 是否禁用按钮 / Whether to disable the button
        clickSound = finalConfig.clickSound,                                      -- -- 点击音效 / Sound effect to play on click
    }
end

--------------------------------------------------
--- @brief 注入依赖模块到局部环境表中。<br>
--- @brief Inject required modules into isolated environment for execution.
---
--- @param dependencyList (table)   字符串模块名列表 / List of module names to require (e.g. { "gameStateManager", "firstStage" })
---
--- @return table env               局部执行环境（带依赖模块） / Isolated execution environment with injected modules
--------------------------------------------------
local function injectDependenciesToEnv(dependencyList)
    local env = {}

    for _, moduleName in ipairs(dependencyList or {}) do
        local ok, mod = pcall(require, moduleName) -- 默认从 modules/ 加载 / Default module path
        if ok then
            env[moduleName] = mod
            logger.logInfo("[buttonManager][injectDependencies] 成功加载依赖模块 / Successfully loaded module: " .. moduleName)
        else
            logger.logError("[buttonManager][injectDependencies] 加载依赖模块失败 / Failed to load module: " .. moduleName)
        end
    end

    -- 允许访问全局库（如 love.graphics）/ Allow fallback to _G
    setmetatable(env, { __index = _G })

    return env
end

--------------------------------------------------
--- @brief 在指定环境中逐条执行字符串代码。<br>
--- @brief Execute a list of Lua code strings in a given environment.
---
--- @param codeList (table) 包含字符串代码的表 / Table of Lua statements as strings
--- @param env (table) 执行环境 / Execution environment (usually injected dependencies + _G fallback)
--- @param context (string?) 可选上下文名 / Optional context name for debugging
--- @param options (table?)     可选参数表（预留）/ Optional settings table (e.g. { trace = true, dryRun = false })
---
--- @return nil
--------------------------------------------------
local function runCodeListInEnv(codeList, env, context, options)
    options = options or {}

    for i, code in ipairs(codeList) do
        local chunk, err = load(code, (context or "onClick") .. "[" .. i .. "]", "t", env)

        if chunk then
            local ok, result = pcall(chunk)
            if not ok then
                logger.logError("[buttonManager][runCodeListInEnv] 执行失败 / Execution failed: " .. tostring(result))
            end
        else
            logger.logError("[buttonManager][runCodeListInEnv] 加载失败 / Compilation failed: " .. tostring(err))
        end
    end
end


--------------------------------------------------
--- @brief 执行按钮动作，支持字符串列表（每条语句逐条执行）。<br>
--- @brief Execute button action, supports list of code strings
---
--- @param button (table) 包含 onClick dependencies 的按钮配置表 / Button config with onClick and optional dependencies
---
--- @return nil
--------------------------------------------------
function buttonManager.runAction(button)
    if not button or type(button.onClick) ~= "table" then
        logger.logWarn("[buttonManager][runAction] 无效的 onClick 配置 / Invalid onClick for button: " ..
            tostring(button and button.id))
        return
    end

    local dependencies = button.dependencies or {}
    local env = injectDependenciesToEnv(dependencies)
    runCodeListInEnv(button.onClick, env, button.id)
end

---

















--------------------------------------------------
--- @brief 将颜色乘以因子，得到变暗颜色。<br>
--- @brief Dim a color by multiplying RGB.
---
--- @param color (table)    {r,g,b[,a]}
--- @param factor (number)  缩放因子 / Scaling factor (0-1)
---
--- @return table 调整后的颜色表
--------------------------------------------------
local function multiplyColor(color, factor)
    return {
        (color[1] or 1) * factor,
        (color[2] or 1) * factor,
        (color[3] or 1) * factor,
        (color[4] or 1) * 1
    }
end





--------------------------------------------------
--- @brief 绘制单个按钮（供内部复用）。<br>
--- @brief Draw one button (for internal reuse).
---
--- @param id (string)          按钮ID / Button id
--- @param config (table)       按钮配置 / Button config
--- @param interface (string)   界面名 / Interface name
--- @param group (string?)      按钮组 / Button group
--------------------------------------------------
local function drawOneButton(id, config, interface, group)
    --- group 可选，自动确定有效的按钮组
    --- Group is optional, automatically determine the effective button group
    local effectiveGroup = group
    if effectiveGroup == nil or effectiveGroup == "" then
        effectiveGroup = config.group or "default"
    end
    --- [界面名-不匹配] 或 [状态-不可见] 则跳过<br>
    --- Skip if interface does not match or button is not visible
    if config.interface ~= interface or config.visible == false then
        return
    end

    --- 安全获取按钮位置信息
    --- Safely get button position information
    local ok, result = pcall(layoutManager.getPosition, id, interface, group)
    if not ok then
        local err = result
        if logger and logger.logWarn then
            logger.logWarn(("[buttonManager][drawOneButton] 无法获取位置 / Unable to obtain location: id=%s, interface=%s, group=%s, %s")
                :format(tostring(id), tostring(interface), tostring(group), tostring(err)))
        end
        return
    elseif type(result) ~= "table" then
        if logger and logger.logWarn then
            logger.logWarn(("[buttonManager][drawOneButton] layoutManager.getPosition 返回值类型错误 / layoutManager.getPosition returned invalid type: id=%s, interface=%s, group=%s, type=%s")
                :format(tostring(id), tostring(interface), tostring(group), type(result)))
        end
        return
    else
        local position = result
        local x, y = position.x, position.y
        if type(x) ~= "number" or type(y) ~= "number" or x ~= x or y ~= y then
            if logger and logger.logWarn then
                logger.logWarn(("[buttonManager][drawOneButton] 位置字段非法: id=%s, x=%s, y=%s")
                    :format(tostring(id), tostring(x), tostring(y)))
            end
            return
        end
    end

    local w = config.width or 100
    local h = config.height or 40
    local r = config.cornerRadius or 0

    --------------------------------------------------
    -- 背景绘制
    --------------------------------------------------
    local bgColor = config.backgroundColor or { 0.6, 0.6, 0.6 }
    if config.hovered and config.hoverBackgroundColor then
        bgColor = config.hoverBackgroundColor
    end
    if config.pressed and config.pressedBackgroundColor then
        bgColor = config.pressedBackgroundColor
    end
    if config.disabled then
        bgColor = multiplyColor(bgColor, 0.5)
    end

    love.graphics.setColor(bgColor)
    love.graphics.rectangle("fill", x, y, w, h, r, r)

    --------------------------------------------------
    -- 边框绘制
    --------------------------------------------------
    if botton.borderColor and botton.borderWidth and botton.borderWidth > 0 then
        local prevLineWidth = love.graphics.getLineWidth()
        love.graphics.setColor(botton.borderColor)
        love.graphics.setLineWidth(botton.borderWidth)
        love.graphics.rectangle("line", x, y, w, h, r, r)
        love.graphics.setLineWidth(prevLineWidth)
    end

    --------------------------------------------------
    -- 文本绘制
    --------------------------------------------------
    if botton.label ~= nil then
        local text = botton.label
        if type(text) == "function" then
            local ok2, result = pcall(text)
            if ok2 then
                text = result
            else
                text = ""
                if logger and logger.logError then
                    logger.logError("[buttonManager][drawOneButton] label() 调用失败: " .. tostring(result))
                end
            end
        end
        text = tostring(text or "")

        local prevFont = love.graphics.getFont()
        local font = botton.font or prevFont
        love.graphics.setFont(font)

        local textColor = botton.textColor or { 1, 1, 1 }
        love.graphics.setColor(textColor)

        local textW = font:getWidth(text)
        local textH = font:getHeight()
        local textX = x + (w - textW) / 2
        local textY = y + (h - textH) / 2

        love.graphics.print(text, textX, textY)

        love.graphics.setFont(prevFont)
    end
end

--------------------------------------------------
--- @brief 绘制当前界面下的所有按钮。<br>
--- @brief Draw all buttons for the current interface.
---
--- @param interface (string) 界面名 / Interface name
---
--- @return nil
--------------------------------------------------
function buttonManager.draw(interface)
    --- 遍历已缓存的按钮<br>
    --- Iterate through cached buttons
    for id, botton in pairs(buttons) do
        --- [界面名-不匹配] 或 [状态-不可见] 则跳过<br>
        --- Skip if interface does not match or button is not visible
        if botton.interface == interface and botton.visible ~= false then
            --- 调用 layoutManager 获取按钮位置<br>
            --- Call layoutManager to get button position
            local position = layoutManager.getPosition(id, botton.group, interface)
            local x, y = position.x, position.y
            local w = botton.width or 100
            local h = botton.height or 40
            local r = botton.cornerRadius or 0


            --- 按钮背景绘制<br>
            --- Draw button background
            local bgColor = botton.backgroundColor or { 0.6, 0.6, 0.6 }

            --- ⚠️ 暂不判断 hovered 状态，可在 button.update 中补充 btn.hovered = true ⚠️
            --- If hovered state is true, use hoverBackgroundColor if defined
            if botton.hovered and botton.hoverBackgroundColor then
                bgColor = botton.hoverBackgroundColor
            end

            --- ⚠️ 暂不判断 pressed 状态，可在 button.update 中补充 btn.pressed = true ⚠️
            --- If pressed state is true, use pressedBackgroundColor if defined
            if botton.pressed and botton.pressedBackgroundColor then
                bgColor = botton.pressedBackgroundColor
            end

            --- ⚠️ 禁用按钮时背景颜色 ⚠️<br>
            --- Disabled button background color
            if botton.disabled then
                bgColor = multiplyColor(bgColor, 0.5)
            end

            love.graphics.setColor(bgColor)                   --- 设置背景颜色

            love.graphics.rectangle("fill", x, y, w, h, r, r) --- 绘制背景矩形

            --- 按钮边框绘制<br>
            --- Button border drawing
            if botton.borderColor and botton.borderWidth and botton.borderWidth > 0 then
                local prevLineWidth = love.graphics.getLineWidth() -- 读取当前线宽
                love.graphics.setColor(botton.borderColor)
                love.graphics.setLineWidth(botton.borderWidth)
                love.graphics.rectangle("line", x, y, w, h, r, r)
                love.graphics.setLineWidth(prevLineWidth) -- 还原线宽，防止泄漏
            end

            --- 按钮文本绘制<br>
            --- Button text drawing
            if botton.label ~= nil then
                --- 1) label 规范化为字符串：支持 label 是函数或字符串<br>
                --- 1) Normalize label to string: support label as function or string
                local text = botton.label
                if type(text) == "function" then
                    local ok, result = pcall(text)
                    if ok then
                        text = result
                    else
                        --- 如果 label 函数内部报错，避免拖垮渲染帧<br>
                        --- If label function call fails, avoid dragging down render frame
                        text = ""
                        local err = result
                        logger.logError("[buttonManager][draw]" .. id .. "label调用失败 / Call failed: " .. tostring(err))
                    end
                end
                text = tostring(text or "")

                --- 2) 绘制文本
                --- 2) Draw text
                local prevFont = love.graphics.getFont()
                local font = botton.font or love.graphics.getFont()
                love.graphics.setFont(font)

                local textColor = botton.textColor or { 1, 1, 1 }
                love.graphics.setColor(textColor)

                local textW = font:getWidth(text)
                local textH = font:getHeight()
                local textX = x + (w - textW) / 2
                local textY = y + (h - textH) / 2

                love.graphics.print(text, textX, textY)
                love.graphics.setFont(prevFont)
            end
        end
    end

    -- 恢复颜色状态
    love.graphics.setColor(1, 1, 1, 1)
end

--------------------------------------------------
--- @brief 更新按钮状态：悬停、按下、冷却等
--- @brief Update all buttons: hover, press, cooldown, etc.
---
--- @param dt (number) love.update 中的时间增量 / Delta time
---
--- @return nil
--------------------------------------------------
function buttonManager.update(dt)
    local mx, my = love.mouse.getPosition()

    -- 遍历已缓存的按钮
    -- Iterate through cached buttons
    for id, button in pairs(buttons) do
        -- 只处理当前界面的按钮，且可见且未禁用
        -- Only process buttons for the current interface, that are visible and not disabled
        if button.interface == currentInterface and button.visible ~= false and button.disabled ~= true then
            -- 获取位置 & 尺寸
            -- Get position and size
            local pos = layoutManager.getPosition(id, button.group, currentInterface)
            local x, y = pos.x, pos.y
            local w, h = button.width or 100, button.height or 40

            -- 检查是否悬停
            button.hovered = mx >= x and mx <= x + w and my >= y and my <= y + h

            -- 检查是否按下（鼠标左键）
            if button.hovered and love.mouse.isDown(1) then
                -- 检查冷却时间
                button._cooldownTimer = button._cooldownTimer or 0
                button._cooldownTimer = button._cooldownTimer - dt

                if button._cooldownTimer <= 0 then
                    if button.onClick and type(button.onClick) == "function" then
                        button.onClick()
                        -- 设置冷却时间
                        button._cooldownTimer = button.cooldown or 0
                    end
                end

                button.pressed = true
            else
                button.pressed = false
            end
        end
    end
end

return buttonManager
