-- modules/layoutManager
-- 布局管理模块
-- Layout Manager module for managing UI element positions responsively.

local userSettings = require("modules.userSettings") -- 加载用户设置模块 / Load user settings module
local logger = require("modules.logger")             -- 加载日志模块 / Load logging module

local layoutManager = {}


--- 注册的元素表：registry[interface][group][id] -> config<br>
--- Registered element table: registry[interface][group][id] -> config
local registry = {}

--- 当前窗口大小<br>
--- Current window size
local windowWidth, windowHeight = love.graphics.getWidth(), love.graphics.getHeight()

--- 设计参考尺寸 (用于缩放参考)<br>
--- Design reference size
local baseWidth, baseHeight = 1280, 720

--- 当前缩放比例<br>
--- Current scale ratio
local scaleRatio = 1.0

--- 当前页面名称<br>
--- Current interface name
local currentInterface = "menu"

--- 内建锚点函数<br>
--- Built-in anchor resolver functions
local anchors = {
    ["top-left"]      = function(w, h) return 0, 0 end,
    ["top-center"]    = function(w, h) return w / 2, 0 end,
    ["top-right"]     = function(w, h) return w, 0 end,
    ["center-left"]   = function(w, h) return 0, h / 2 end,
    ["center"]        = function(w, h) return w / 2, h / 2 end,
    ["center-right"]  = function(w, h) return w, h / 2 end,
    ["bottom-left"]   = function(w, h) return 0, h end,
    ["bottom-center"] = function(w, h) return w / 2, h end,
    ["bottom-right"]  = function(w, h) return w, h end,
}

--------------------------------------------------
--- @brief 设置当前页面名。<br>
--- @brief Set current interface name.
---
--- @param name (string)    页面名 / Interface name
---
--- @return nil
--------------------------------------------------
function layoutManager.setCurrentInterface(name)
    currentInterface = name or "menu"
    logger.logInfo("[layoutManager][setCurrentInterface] 当前页面已设置为 / Current interface set to: " .. currentInterface)
end

--------------------------------------------------
--- @brief 注册一个 UI 元素的布局配置（锚点 + 偏移）。<br>
--- @brief Register a layout config for a UI element (anchor + offset).
---
--- @param id (string)          元素唯一 ID / Unique element ID
--- @param config (table)       布局配置表 / Layout config table
--- @param interface (string)   页面名（可选，默认 currentInterface） / Interface name (optional, defaults to currentInterface)
--- @param group (string)       分组名（可选，默认为 "default"） / Group name (optional, default is "default")
--- @param meta (table?)        元数据（可选，暂未使用） / Metadata (optional, not used currently)
---
--- @return nil
--------------------------------------------------
function layoutManager.register(id, config, interface, group, meta)
    -- 如未提供 group 和 interface，则使用 default 和 currentInterface
    -- If group and interface are not provided, use default values and current interface
    group = group or "default"
    interface = interface or currentInterface
    config = config or {}

    -- 过滤字段，如果传入 config 未提供所需值则使用默认值（锚点："top-left"，偏移0）
    -- Filter config fields, use defaults if not provided
    local cleanConfig = {
        anchor = config.anchor or "top-left",
        offsetX = config.offsetX or 0,
        offsetY = config.offsetY or 0,
        zIndex = config.zIndex or 10, -- 值越高越晚绘制 / Value higher means drawn later
    }

    -- 锚点合法性校验
    -- Validate anchor
    if not anchors[cleanConfig.anchor] then
        logger.logWarn("[layoutManager][register] 无效锚点 / Invalid anchor: " ..
            tostring(id) .. tostring(config.anchor) .. "默认使用 / Defaulting to: top-left")
        cleanConfig.anchor = "top-left"
    end

    -- 保存注册配置
    -- Save to registry
    registry[interface] = registry[interface] or {}
    registry[interface][group] = registry[interface][group] or {}
    registry[interface][group][id] = cleanConfig

    logger.logInfo("[layoutManager][register] 已注册元素 / Registered element: " ..
        tostring(id) .. " in interface: " .. tostring(interface) .. ", group: " .. tostring(group))
end

--------------------------------------------------
--- @brief 利用 LOVE2D 回调 [love.resize]，更新窗口尺寸并重新计算缩放比例。<br>
--- @brief LOVE2D callback [love.resize] to update window size and recalculate scale ratio.
---
--- @param w (number) 新窗口宽度 / New window width
--- @param h (number) 新窗口高度 / New window height
---
--- @return nil
--------------------------------------------------
function layoutManager.onResize(w, h)
    windowWidth, windowHeight = w, h
    scaleRatio = math.min(w / baseWidth, h / baseHeight)
end

--------------------------------------------------
--- @brief 获取指定元素的屏幕坐标。
--- @brief Get screen position of given element.
---
--- @param id (string)          元素 ID / Element ID
--- @param group (string)       所在分组 / Group name
--- @param interface (string?)  页面接口名（可选，自动获取当前页面）/ Interface name (optional)
---
--- @return table xy-position   x, y 坐标/ x, y position
--------------------------------------------------
function layoutManager.getPosition(id, group, interface)
    -- 如未提供 group 和 interface，则使用 default 和 currentInterface
    -- If group and interface are not provided, use default values and current interface
    group = group or "default"
    interface = interface or currentInterface

    -- 读取该 id 元素布局配置
    -- Read the button config for this id
    local config = registry[interface] and registry[interface][group] and registry[interface][group][id]

    -- 如果未找到配置，则返回默认位置 (0, 0) 并记录警告
    -- If no config found, return default position (0, 0) and log a warning
    if not config then
        logger.logWarn("[layoutManager][getPosition] 未找到按钮配置 / Cannot find button config: " .. tostring(id))
        return { 0, 0 }
    end

    -- 如果未获取窗口大小，使用当前窗口尺寸
    -- If window size is not provided, use current window size
    if not windowWidth or not windowHeight then
        windowWidth = love.graphics.getWidth()
        windowHeight = love.graphics.getHeight()
    end

    -- 计算元素锚点位置，获取偏移量
    -- Calculate anchor position and apply offsets
    local anchor = config.anchor or "top-left"
    local offsetX = config.offsetX or 0
    local offsetY = config.offsetY or 0
    local anchorFunc = anchors[anchor] or anchors["top-left"]
    local anchorX, anchorY = anchorFunc(windowWidth, windowHeight)

    -- 处理百分比字符串
    -- Handle percentage offset
    if type(offsetX) == "string" and offsetX:sub(-1) == "%" then
        local percent = tonumber(offsetX:sub(1, -2)) or 0
        offsetX = percent * windowWidth / 100
    end
    if type(offsetY) == "string" and offsetY:sub(-1) == "%" then
        local percent = tonumber(offsetY:sub(1, -2)) or 0
        offsetY = percent * windowHeight / 100
    end

    local x = anchorX + offsetX
    local y = anchorY + offsetY
    return { x = x, y = y }
end

--------------------------------------------------
--- @brief 获取当前缩放比例。
--- @brief Get current scale ratio.
---
--- @return number 缩放比例 / Scale ratio
--------------------------------------------------
function layoutManager.getScale()
    return scaleRatio
end

--------------------------------------------------
--- @brief 清除所有注册元素。
--- @brief Clear all layout registrations.
---
--- @return nil
--------------------------------------------------
function layoutManager.clear()
    registry = {}
end

--------------------------------------------------
--- @brief 清除指定页面的布局。
--- @brief Clear layout of specific interface.
---
--- @param interface (string) 页面接口名 / Interface name
--------------------------------------------------
function layoutManager.clearInterface(interface)
    registry[interface] = nil
end

--------------------------------------------------
--- @brief 可选：批量注册网格布局。
--- @brief Optional: register grid layout items.
---
--- @param idPrefix (string) ID 前缀 / ID prefix
--- @param cfg (table) 包含 anchor、起点、行列数、间距等 / Includes anchor, startX, startY, spacing, rows, cols
--- @param group (string?) 分组名 / Group name
--- @param interface (string?) 页面名 / Interface name（可选）
--------------------------------------------------
function layoutManager.registerGrid(idPrefix, cfg, group, interface)
    local rows = cfg.rows or 1
    local cols = cfg.cols or 1
    local spacingX = cfg.spacingX or 0
    local spacingY = cfg.spacingY or 0
    local startOffsetX = cfg.startX or 0
    local startOffsetY = cfg.startY or 0
    local anchor = cfg.anchor or "top-left"
    group = group or "default"
    interface = interface or currentInterface

    for r = 1, rows do
        for c = 1, cols do
            local id = idPrefix .. "_" .. ((r - 1) * cols + c)
            layoutManager.register(id, {
                anchor = anchor,
                offsetX = startOffsetX + (c - 1) * spacingX,
                offsetY = startOffsetY + (r - 1) * spacingY
            }, group, interface)
        end
    end
end

return layoutManager
